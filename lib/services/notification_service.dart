import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/db/app_database.dart';
import '../utils/format.dart';

class NotificationService {
  NotificationService(this.db);

  final AppDatabase db;
  final _plugin = FlutterLocalNotificationsPlugin();

  static const reminderId = 11;
  static const recapId = 12;
  static const lowBalanceId = 13;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Accra'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> refreshSchedules() async {
    final settings = await db.settings();
    if (!settings.notificationsEnabled) {
      await _plugin.cancelAll();
      return;
    }
    await _scheduleIncomeReminder(settings.reminderDays);
    await _scheduleMonthlyRecap();
    await _maybeLowFreeMoney(settings.freeMoneyWarnPesewas);
  }

  Future<void> _scheduleIncomeReminder(int days) async {
    await _plugin.cancel(reminderId);
    final last = await db.lastIncomeDate() ?? DateTime.now();
    final when = tz.TZDateTime.from(last.add(Duration(days: days)), tz.local);
    final fire = when.isBefore(tz.TZDateTime.now(tz.local))
        ? tz.TZDateTime.now(tz.local).add(const Duration(hours: 2))
        : when;
    await _plugin.zonedSchedule(
      reminderId,
      'Give this cedi a purpose',
      'No income logged in a while. Split your next inflow in Splytwise.',
      fire,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habits',
          'Habits',
          channelDescription: 'Income logging reminders',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _scheduleMonthlyRecap() async {
    await _plugin.cancel(recapId);
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1, 1, 9);
    await _plugin.zonedSchedule(
      recapId,
      'Your monthly recap is ready',
      'See what you saved and where the money went.',
      tz.TZDateTime.from(next, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recap',
          'Monthly recap',
          channelDescription: 'End of month summary',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> _maybeLowFreeMoney(int warnAt) async {
    final free = await db.freeMoneyCategory();
    if (free == null || free.currentAmount >= warnAt) {
      await _plugin.cancel(lowBalanceId);
      return;
    }
    await _plugin.show(
      lowBalanceId,
      'Free money is running low',
      'Only ${formatPesewas(free.currentAmount)} left unallocated.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'balance',
          'Balance alerts',
          channelDescription: 'Low free-money warnings',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
