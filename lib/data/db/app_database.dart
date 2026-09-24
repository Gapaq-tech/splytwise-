import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../utils/money.dart';
import 'tables.dart';

part 'app_database.g.dart';

const freeMoneyKey = 'free_money';

@DriftDatabase(
    tables: [Users, Categories, Incomes, Allocations, Expenses, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_allocations_income ON allocations(income_id);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_allocations_category ON allocations(category_id);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_incomes_date ON incomes(date);',
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(users, users.profileImagePath);
          }
        },
      );

  Future<void> ensureSeeded() async {
    final settingsCount = await select(appSettings).get();
    if (settingsCount.isEmpty) {
      await into(appSettings).insert(AppSettingsCompanion.insert());
    }
    final free = await freeMoneyCategory();
    if (free == null) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: 'Free money',
          color: 0xFF1E8E6D,
          icon: 'wallet',
          isSystem: const Value(true),
          systemKey: const Value(freeMoneyKey),
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<Category?> freeMoneyCategory() {
    return (select(categories)..where((c) => c.systemKey.equals(freeMoneyKey)))
        .getSingleOrNull();
  }

  Future<int> freeMoneyId() async {
    final row = await freeMoneyCategory();
    if (row == null) {
      throw StateError('Free money bucket missing');
    }
    return row.id;
  }

  Stream<AppSetting> watchSettings() {
    return (select(appSettings)..limit(1)).watchSingleOrNull().asyncMap((row) async {
      if (row == null) {
        await ensureSeeded();
        final seeded = await (select(appSettings)..limit(1)).getSingleOrNull();
        if (seeded == null) {
          throw StateError('App settings could not be created.');
        }
        return seeded;
      }
      return row;
    });
  }

  Future<AppSetting> settings() async {
    final row = await (select(appSettings)..limit(1)).getSingleOrNull();
    if (row == null) {
      await ensureSeeded();
      final seeded = await (select(appSettings)..limit(1)).getSingleOrNull();
      if (seeded == null) {
        throw StateError('App settings could not be created.');
      }
      return seeded;
    }
    return row;
  }

  Future<void> updateSettings(AppSettingsCompanion data) async {
    final current = await settings();
    await (update(appSettings)..where((s) => s.id.equals(current.id)))
        .write(data);
  }

  Stream<List<Category>> watchSpendCategories() {
    return (select(categories)
          ..where((c) => c.isGoal.equals(false))
          ..orderBy([
            (c) => OrderingTerm.asc(c.isSystem),
            (c) => OrderingTerm.asc(c.name),
          ]))
        .watch();
  }

  Stream<List<Category>> watchGoals() {
    return (select(categories)
          ..where((c) => c.isGoal.equals(true))
          ..orderBy([
            (c) => OrderingTerm.asc(c.completedAt),
            (c) => OrderingTerm.desc(c.createdAt),
          ]))
        .watch();
  }

  Stream<List<Category>> watchAllocatable() {
    return (select(categories)
          ..where((c) => c.isSystem.equals(false))
          ..orderBy([
            (c) => OrderingTerm.desc(c.isGoal),
            (c) => OrderingTerm.asc(c.name),
          ]))
        .watch();
  }

  Stream<List<Category>> watchAllBuckets() {
    return (select(categories)..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Stream<List<Allocation>> watchAllocations() => select(allocations).watch();

  Future<Category> categoryById(int id) {
    return (select(categories)..where((c) => c.id.equals(id))).getSingle();
  }

  Future<void> updateCategoryLook(int id,
      {int? color, String? icon, bool? protected}) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        color: color == null ? const Value.absent() : Value(color),
        icon: icon == null ? const Value.absent() : Value(icon),
        protected: protected == null ? const Value.absent() : Value(protected),
      ),
    );
  }

  Future<int> createGoal({
    required String name,
    required int targetPesewas,
    required String icon,
    required int color,
  }) {
    return into(categories).insert(
      CategoriesCompanion.insert(
        name: name,
        color: color,
        icon: icon,
        isGoal: const Value(true),
        targetAmount: Value(targetPesewas),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<int> createCategory({
    required String name,
    required String icon,
    required int color,
    bool protected = false,
  }) {
    return into(categories).insert(
      CategoriesCompanion.insert(
        name: name,
        color: color,
        icon: icon,
        protected: Value(protected),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> deleteCategoryIfAllowed(int id) async {
    final cat = await categoryById(id);
    if (cat.isSystem) return;
    try {
      await (delete(categories)..where((c) => c.id.equals(id))).go();
    } catch (_) {
      // Keep the bucket if income/expense history still points at it.
    }
  }

  Future<void> updateProfile(
      {String? name, String? currency, String? profileImagePath}) async {
    final existing = await currentUser();
    if (existing == null) return;
    await (update(users)..where((u) => u.id.equals(existing.id))).write(
      UsersCompanion(
        name: name == null ? const Value.absent() : Value(name),
        currency: currency == null ? const Value.absent() : Value(currency),
        profileImagePath: profileImagePath == null
            ? const Value.absent()
            : Value(profileImagePath),
      ),
    );
  }

  Future<User?> currentUser() {
    return (select(users)..limit(1)).getSingleOrNull();
  }

  Stream<User?> watchUser() {
    return (select(users)..limit(1)).watchSingleOrNull();
  }

  Future<void> completeOnboarding({
    required String name,
    required List<({String name, String icon, int color})> starterCategories,
  }) async {
    await transaction(() async {
      final existing = await currentUser();
      if (existing == null) {
        await into(users).insert(
          UsersCompanion.insert(
            name: name,
            createdAt: DateTime.now(),
          ),
        );
      } else {
        await (update(users)..where((u) => u.id.equals(existing.id)))
            .write(UsersCompanion(name: Value(name)));
      }
      for (final starter in starterCategories) {
        await into(categories).insert(
          CategoriesCompanion.insert(
            name: starter.name,
            color: starter.color,
            icon: starter.icon,
            createdAt: DateTime.now(),
          ),
        );
      }
      await updateSettings(
        const AppSettingsCompanion(onboardingComplete: Value(true)),
      );
    });
  }

  Future<({int incomeId, List<int> completedGoalIds})>
      addIncomeWithAllocations({
    required int amountPesewas,
    required String source,
    required DateTime date,
    required List<SettledAllocation> splits,
  }) async {
    return transaction(() async {
      final incomeId = await into(incomes).insert(
        IncomesCompanion.insert(
          amount: amountPesewas,
          source: source,
          date: date,
          createdAt: DateTime.now(),
        ),
      );
      final completed = <int>[];
      for (final split in splits) {
        await into(allocations).insert(
          AllocationsCompanion.insert(
            incomeId: incomeId,
            categoryId: split.categoryId,
            amount: split.amountPesewas,
            percent: split.percent,
          ),
        );
        final cat = await categoryById(split.categoryId);
        final next = cat.currentAmount + split.amountPesewas;
        DateTime? completedAt = cat.completedAt;
        var justCompleted = false;
        if (cat.isGoal &&
            cat.targetAmount != null &&
            cat.completedAt == null &&
            next >= cat.targetAmount!) {
          completedAt = DateTime.now();
          justCompleted = true;
        }
        await (update(categories)..where((c) => c.id.equals(cat.id))).write(
          CategoriesCompanion(
            currentAmount: Value(next),
            completedAt: Value(completedAt),
          ),
        );
        if (justCompleted) completed.add(cat.id);
      }
      return (incomeId: incomeId, completedGoalIds: completed);
    });
  }

  Future<int> addExpense({
    required int? categoryId,
    required int amountPesewas,
    required String description,
    required DateTime date,
  }) async {
    return transaction(() async {
      final bucketId = categoryId ?? await freeMoneyId();
      final id = await into(expenses).insert(
        ExpensesCompanion.insert(
          categoryId: Value(bucketId),
          amount: amountPesewas,
          description: description,
          date: date,
          createdAt: DateTime.now(),
        ),
      );
      final cat = await categoryById(bucketId);
      await (update(categories)..where((c) => c.id.equals(bucketId))).write(
        CategoriesCompanion(
            currentAmount: Value(cat.currentAmount - amountPesewas)),
      );
      return id;
    });
  }

  Future<DateTime?> lastIncomeDate() async {
    final row = await (select(incomes)
          ..orderBy([(i) => OrderingTerm.desc(i.date)])
          ..limit(1))
        .getSingleOrNull();
    return row?.date;
  }

  Stream<List<Income>> watchIncomes() {
    return (select(incomes)..orderBy([(i) => OrderingTerm.desc(i.date)]))
        .watch();
  }

  Stream<List<Expense>> watchExpenses() {
    return (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  Future<List<Allocation>> allocationsForIncome(int incomeId) {
    return (select(allocations)..where((a) => a.incomeId.equals(incomeId)))
        .get();
  }

  Future<List<MonthExportRow>> monthExport(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final incomeRows = await (select(incomes)
          ..where((i) =>
              i.date.isBiggerOrEqualValue(start) &
              i.date.isSmallerThanValue(end)))
        .get();
    final expenseRows = await (select(expenses)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(start) &
              e.date.isSmallerThanValue(end)))
        .get();
    final cats = {for (final c in await select(categories).get()) c.id: c};

    final out = <MonthExportRow>[];
    for (final income in incomeRows) {
      final splits = await allocationsForIncome(income.id);
      for (final split in splits) {
        out.add(
          MonthExportRow(
            kind: 'income_allocation',
            date: income.date,
            title: income.source,
            bucket: cats[split.categoryId]?.name ?? 'Unknown',
            amountPesewas: split.amount,
          ),
        );
      }
    }
    for (final expense in expenseRows) {
      out.add(
        MonthExportRow(
          kind: 'expense',
          date: expense.date,
          title: expense.description,
          bucket: cats[expense.categoryId]?.name ?? 'Free money',
          amountPesewas: -expense.amount,
        ),
      );
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  Future<MonthlyRecap> monthlyRecap(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final incomeRows = await (select(incomes)
          ..where((i) =>
              i.date.isBiggerOrEqualValue(start) &
              i.date.isSmallerThanValue(end)))
        .get();
    final expenseRows = await (select(expenses)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(start) &
              e.date.isSmallerThanValue(end)))
        .get();
    final cats = {for (final c in await select(categories).get()) c.id: c};
    var saved = 0;
    var spent = 0;
    final spendByBucket = <int, int>{};
    for (final income in incomeRows) {
      for (final split in await allocationsForIncome(income.id)) {
        final cat = cats[split.categoryId];
        if (cat?.isGoal == true) saved += split.amount;
      }
    }
    for (final expense in expenseRows) {
      spent += expense.amount;
      final id = expense.categoryId;
      if (id != null) {
        spendByBucket[id] = (spendByBucket[id] ?? 0) + expense.amount;
      }
    }
    String? top;
    var topAmt = 0;
    spendByBucket.forEach((id, amount) {
      if (amount > topAmt) {
        topAmt = amount;
        top = cats[id]?.name;
      }
    });
    return MonthlyRecap(
      savedPesewas: saved,
      spentPesewas: spent,
      topSpendBucket: top,
      incomeCount: incomeRows.length,
    );
  }
}

class MonthExportRow {
  const MonthExportRow({
    required this.kind,
    required this.date,
    required this.title,
    required this.bucket,
    required this.amountPesewas,
  });

  final String kind;
  final DateTime date;
  final String title;
  final String bucket;
  final int amountPesewas;
}

class MonthlyRecap {
  const MonthlyRecap({
    required this.savedPesewas,
    required this.spentPesewas,
    required this.topSpendBucket,
    required this.incomeCount,
  });

  final int savedPesewas;
  final int spentPesewas;
  final String? topSpendBucket;
  final int incomeCount;
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'splytwise.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
