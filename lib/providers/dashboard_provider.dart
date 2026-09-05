import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import 'app_providers.dart';

class HistoryItem {
  const HistoryItem({
    required this.kind,
    required this.id,
    required this.amountPesewas,
    required this.title,
    required this.date,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.icon,
  });

  final String kind; // income | expense
  final int id;
  final int amountPesewas;
  final String title;
  final DateTime date;
  final int? categoryId;
  final String? categoryName;
  final int? categoryColor;
  final String? icon;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.totalBalance,
    required this.freeMoney,
    required this.goalSaved,
    required this.spentThisMonth,
    required this.weeksOnTrack,
    required this.spendByBucket,
    required this.protectedWarnings,
  });

  final int totalBalance;
  final Category? freeMoney;
  final int goalSaved;
  final int spentThisMonth;
  final int weeksOnTrack;
  final List<({Category category, int spent})> spendByBucket;
  final List<Category> protectedWarnings;
}

int consecutiveWeeksOnTrack(List<Income> incomes, DateTime now) {
  if (incomes.isEmpty) return 0;
  final weeks = incomes
      .map((i) => DateTime(i.date.year, i.date.month, i.date.day))
      .map((d) => d.subtract(Duration(days: d.weekday - 1)))
      .map((monday) => DateTime(monday.year, monday.month, monday.day))
      .toSet();
  var count = 0;
  var cursor = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  while (weeks.contains(cursor)) {
    count += 1;
    cursor = cursor.subtract(const Duration(days: 7));
  }
  return count;
}

final dashboardProvider = Provider<AsyncValue<DashboardSnapshot>>((ref) {
  final buckets = ref.watch(allBucketsProvider);
  final incomes = ref.watch(incomesProvider);
  final expenses = ref.watch(expensesProvider);
  final settings = ref.watch(settingsProvider);
  return buckets.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (cats) {
      return incomes.when(
        loading: () => const AsyncLoading(),
        error: AsyncError.new,
        data: (incomeRows) {
          return expenses.when(
            loading: () => const AsyncLoading(),
            error: AsyncError.new,
            data: (expenseRows) {
              return settings.when(
                loading: () => const AsyncLoading(),
                error: AsyncError.new,
                data: (appSettings) {
                  final now = DateTime.now();
                  final start = DateTime(now.year, now.month, 1);
                  final free = cats.where((c) => c.systemKey == freeMoneyKey).firstOrNull;
                  final total = cats.fold<int>(0, (s, c) => s + c.currentAmount);
                  final goalSaved = cats.where((c) => c.isGoal).fold<int>(0, (s, c) => s + c.currentAmount);
                  final monthSpend = expenseRows
                      .where((e) => !e.date.isBefore(start))
                      .fold<int>(0, (s, e) => s + e.amount);
                  final spendMap = <int, int>{};
                  for (final e in expenseRows.where((e) => !e.date.isBefore(start))) {
                    if (e.categoryId == null) continue;
                    spendMap[e.categoryId!] = (spendMap[e.categoryId!] ?? 0) + e.amount;
                  }
                  final spendByBucket = spendMap.entries
                      .map((e) {
                        final cat = cats.where((c) => c.id == e.key).firstOrNull;
                        if (cat == null) return null;
                        return (category: cat, spent: e.value);
                      })
                      .whereType<({Category category, int spent})>()
                      .toList()
                    ..sort((a, b) => b.spent.compareTo(a.spent));
                  final warnAt = appSettings.freeMoneyWarnPesewas;
                  final protectedWarnings = cats
                      .where((c) => c.protected && c.currentAmount < warnAt)
                      .toList();
                  if (free != null && free.currentAmount < warnAt) {
                    protectedWarnings.add(free);
                  }
                  return AsyncData(
                    DashboardSnapshot(
                      totalBalance: total,
                      freeMoney: free,
                      goalSaved: goalSaved,
                      spentThisMonth: monthSpend,
                      weeksOnTrack: consecutiveWeeksOnTrack(incomeRows, now),
                      spendByBucket: spendByBucket,
                      protectedWarnings: protectedWarnings.toSet().toList(),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    },
  );
});

final historyProvider = Provider<AsyncValue<List<HistoryItem>>>((ref) {
  final incomes = ref.watch(incomesProvider);
  final expenses = ref.watch(expensesProvider);
  final buckets = ref.watch(allBucketsProvider);
  return incomes.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (incomeRows) {
      return expenses.when(
        loading: () => const AsyncLoading(),
        error: AsyncError.new,
        data: (expenseRows) {
          return buckets.when(
            loading: () => const AsyncLoading(),
            error: AsyncError.new,
            data: (cats) {
              final byId = {for (final c in cats) c.id: c};
              final items = <HistoryItem>[
                ...incomeRows.map(
                  (row) => HistoryItem(
                    kind: 'income',
                    id: row.id,
                    amountPesewas: row.amount,
                    title: row.source,
                    date: row.date,
                    icon: 'spark',
                  ),
                ),
                ...expenseRows.map((row) {
                  final cat = row.categoryId == null ? null : byId[row.categoryId];
                  return HistoryItem(
                    kind: 'expense',
                    id: row.id,
                    amountPesewas: row.amount,
                    title: row.description,
                    date: row.date,
                    categoryId: row.categoryId,
                    categoryName: cat?.name,
                    categoryColor: cat?.color,
                    icon: cat?.icon,
                  );
                }),
              ]..sort((a, b) => b.date.compareTo(a.date));
              return AsyncData(items);
            },
          );
        },
      );
    },
  );
});
