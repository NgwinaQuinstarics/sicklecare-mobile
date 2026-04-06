import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ✅ INIT
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await notificationsPlugin.initialize(settings);
  }

  // ✅ SCHEDULE DAILY REMINDER (FIXED)
  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),

      // ✅ REQUIRED FIX
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,

      // ✅ REPEAT DAILY
      matchDateTimeComponents: DateTimeComponents.time,

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ✅ CALCULATE NEXT TIME
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  // ❌ CANCEL REMINDER
  static Future<void> cancel(int id) async {
    await notificationsPlugin.cancel(id);
  }
}