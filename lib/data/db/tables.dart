import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get currency => text().withDefault(const Constant('GHS'))();
  TextColumn get profileImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get color => integer()();
  TextColumn get icon => text()();
  BoolColumn get isGoal => boolean().withDefault(const Constant(false))();
  IntColumn get targetAmount => integer().nullable()();
  IntColumn get currentAmount => integer().withDefault(const Constant(0))();
  BoolColumn get protected => boolean().withDefault(const Constant(false))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  TextColumn get systemKey => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();
  TextColumn get source => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

class Allocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get incomeId =>
      integer().references(Incomes, #id, onDelete: KeyAction.cascade)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get amount => integer()();
  RealColumn get percent => real()();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get amount => integer()();
  TextColumn get description => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pinHash => text().nullable()();
  BoolColumn get pinEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get reminderDays => integer().withDefault(const Constant(7))();
  IntColumn get freeMoneyWarnPesewas =>
      integer().withDefault(const Constant(5000))();
  BoolColumn get onboardingComplete =>
      boolean().withDefault(const Constant(false))();
  TextColumn get themeMode => text().withDefault(const Constant('light'))();
}
