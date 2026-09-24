import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/queries/month_export.dart';
import '../services/notification_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await db.ensureSeeded();
  final notifications = NotificationService(db);
  await notifications.init();
  await notifications.refreshSchedules();
});

final settingsProvider = StreamProvider((ref) {
  return ref.watch(databaseProvider).watchSettings();
});

final userProvider = StreamProvider((ref) {
  return ref.watch(databaseProvider).watchUser();
});

final categoriesProvider = StreamProvider((ref) {
  return ref.watch(databaseProvider).watchSpendCategories();
});

final goalsProvider = StreamProvider((ref) {
  return ref.watch(databaseProvider).watchGoals();
});

final allocatableProvider = StreamProvider((ref) {
  return ref.watch(databaseProvider).watchAllocatable();
});

final allBucketsProvider = StreamProvider((ref) {
  return ref.watch(databaseProvider).watchAllBuckets();
});

final incomesProvider = StreamProvider((ref) {
  return ref.watch(databaseProvider).watchIncomes();
});

final expensesProvider = StreamProvider((ref) {
  return ref.watch(databaseProvider).watchExpenses();
});

final allocationsProvider = StreamProvider((ref) {
  return ref.watch(databaseProvider).watchAllocations();
});

final monthlyRecapProvider = FutureProvider((ref) {
  ref.watch(incomesProvider);
  ref.watch(expensesProvider);
  return ref.watch(databaseProvider).monthlyRecap(DateTime.now());
});

final monthExportProvider = Provider((ref) {
  return MonthExportQuery(ref.watch(databaseProvider));
});

final notificationServiceProvider = Provider((ref) {
  return NotificationService(ref.watch(databaseProvider));
});
