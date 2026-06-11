import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Android 13+ : la permission notifications doit etre demandee a
    // l'execution, sinon aucune notification/rappel ne s'affiche.
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    // iOS : alertes / sons / badges
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _ready = true;
  }

  Future<void> schedule(Reminder r) async {
    await init();
    final id = r.id.hashCode & 0x7fffffff;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, r.time.hour, r.time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    try {
      await _plugin.zonedSchedule(
        id,
        r.title,
        r.body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sicklecare_reminders',
            'Reminders',
            channelDescription: 'SickleCare reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            r.repeatDaily ? DateTimeComponents.time : null,
      );
    } catch (_) {}
  }

  Future<void> cancel(String id) async {
    await _plugin.cancel(id.hashCode & 0x7fffffff);
  }
}
