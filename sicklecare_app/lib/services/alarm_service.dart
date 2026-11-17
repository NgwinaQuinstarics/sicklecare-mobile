import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/reminder.dart';

class AlarmHealthStatus {
  final bool notificationsAllowed;
  final bool allRequiredPermissionsGranted;
  final List<NotificationPermission> missingPermissions;
  final int scheduledCustomAlarms;
  final int scheduledHydrationAlarms;
  final int totalScheduledNotifications;

  const AlarmHealthStatus({
    required this.notificationsAllowed,
    required this.allRequiredPermissionsGranted,
    required this.missingPermissions,
    required this.scheduledCustomAlarms,
    required this.scheduledHydrationAlarms,
    required this.totalScheduledNotifications,
  });

  bool get healthy =>
      notificationsAllowed &&
      allRequiredPermissionsGranted &&
      (scheduledCustomAlarms > 0 || scheduledHydrationAlarms > 0);
}

/// Unified alarm & notification service for SickleCare.
///
/// Uses [AwesomeNotifications] as the sole scheduling engine. All alarms,
/// hydration reminders, daily advice, and instant notifications flow through
/// this single service. No background isolate or manual audio playback is
/// needed — the OS handles sound, vibration, full-screen intent, reboot
/// survival, and doze-mode bypass natively.
class AlarmService {
  AlarmService._();
  static final instance = AlarmService._();

  /// Global navigator key — must be assigned to [MaterialApp.navigatorKey].
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ---------------------------------------------------------------------------
  // Channel keys
  // ---------------------------------------------------------------------------
  static const _alarmChannelKey = 'sicklecare_alarm_reminders_v3';
  static const _hydrationChannelKey = 'sicklecare_hydration_reminders_v4';
  static const _adviceChannelKey = 'sicklecare_daily_advice_v2';
  static const _instantChannelKey = 'sicklecare_instant_v1';

  // ---------------------------------------------------------------------------
  // Notification ID ranges
  // ---------------------------------------------------------------------------
  static const _legacyHydrationNotificationId = 730001;
  static const _legacyHydrationChannelKey = 'sicklecare_hydration_reminders_v3';
  static const _reminderNotificationIdBase = 2000000;
  static const _reminderNotificationIdRange = 1490000000;
  static const _hydrationNotificationIdBase = 1700000000;
  static const _dailyAdviceNotificationId = 730002;
  static const _alarmPermissions = [
    NotificationPermission.Alert,
    NotificationPermission.Sound,
    NotificationPermission.Badge,
    NotificationPermission.Vibration,
    NotificationPermission.Light,
    NotificationPermission.PreciseAlarms,
    NotificationPermission.FullScreenIntent,
  ];

  bool _ready = false;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialise notification channels and request permissions.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> init({bool requestPermissions = true}) async {
    if (_ready) return;

    try {
      await AwesomeNotifications().initialize(
        null, // default app icon
        [
          NotificationChannel(
            channelGroupKey: 'sicklecare_group',
            channelKey: _alarmChannelKey,
            channelName: 'SickleCare alarms',
            channelDescription: 'Medication, clinic, and health alarms',
            defaultColor: Colors.deepPurple,
            importance: NotificationImportance.Max,
            playSound: true,
            criticalAlerts: true,
            enableVibration: true,
            channelShowBadge: true,
            vibrationPattern: Int64List.fromList([0, 900, 350, 900]),
          ),
          NotificationChannel(
            channelGroupKey: 'sicklecare_group',
            channelKey: _hydrationChannelKey,
            channelName: 'Hydration reminders',
            channelDescription: 'Regular reminders to drink water',
            defaultColor: Colors.blue,
            importance: NotificationImportance.Max,
            playSound: true,
            criticalAlerts: true,
            enableVibration: true,
            channelShowBadge: true,
            vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          ),
          NotificationChannel(
            channelGroupKey: 'sicklecare_group',
            channelKey: _adviceChannelKey,
            channelName: 'Sika daily advice',
            channelDescription: 'Daily health advice from Sika',
            defaultColor: Colors.teal,
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
          ),
          NotificationChannel(
            channelGroupKey: 'sicklecare_group',
            channelKey: _instantChannelKey,
            channelName: 'Instant Notifications',
            channelDescription: 'Instant confirmation notifications',
            defaultColor: Colors.deepPurple,
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
          ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'sicklecare_group',
            channelGroupName: 'SickleCare Reminders',
          ),
        ],
        debug: kDebugMode,
      );

      if (requestPermissions) {
        await _ensureAlarmPermissions();
      }

      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onActionReceived,
        onNotificationCreatedMethod: _onNotificationCreated,
        onNotificationDisplayedMethod: _onNotificationDisplayed,
        onDismissActionReceivedMethod: _onDismissActionReceived,
      );

      _ready = true;
    } catch (e) {
      debugPrint('AlarmService.init failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Reminder scheduling (medication / clinic / custom alarms)
  // ---------------------------------------------------------------------------

  /// Schedule a reminder notification that fires at the reminder's time.
  ///
  /// Uses [NotificationCalendar] with `allowWhileIdle: true` for doze-mode
  /// bypass and `repeats: true` for daily repetition.
  Future<void> schedule(
    Reminder r, {
    bool requestPermissions = true,
  }) async {
    await init(requestPermissions: false);
    if (requestPermissions) {
      await _ensureAlarmPermissions();
    }
    final id = _notificationId(r.id);
    final scheduledDate = _nextOccurrence(r.time);
    final localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _alarmChannelKey,
          title: r.title,
          body: r.body.isEmpty ? 'SickleCare reminder is active.' : r.body,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          payload: {'type': 'reminder', 'id': r.id},
        ),
        schedule: r.repeatDaily
            ? NotificationCalendar(
                hour: scheduledDate.hour,
                minute: scheduledDate.minute,
                second: 0,
                millisecond: 0,
                timeZone: localTimeZone,
                allowWhileIdle: true,
                preciseAlarm: true,
                repeats: true,
              )
            : NotificationCalendar.fromDate(
                date: scheduledDate,
                allowWhileIdle: true,
                preciseAlarm: true,
                repeats: false,
              ),
      );
    } catch (e) {
      debugPrint('AlarmService.schedule failed: $e');
    }
  }

  /// Cancel a pending reminder notification.
  Future<void> cancel(String reminderId) async {
    try {
      await AwesomeNotifications().cancel(_notificationId(reminderId));
    } catch (_) {}
  }

  /// Clear all pending custom alarm schedules on the alarm channel.
  Future<void> cancelReminderSchedules() async {
    await init(requestPermissions: false);
    try {
      await AwesomeNotifications()
          .cancelSchedulesByChannelKey(_alarmChannelKey);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Hydration reminders
  // ---------------------------------------------------------------------------

  /// Schedule hydration reminders from [startTime], repeating every [minutes].
  ///
  /// Awesome Notifications does not need internet access: each hydration slot is
  /// stored locally as a daily repeating calendar alarm, just like custom alarms.
  Future<void> scheduleHydrationReminder(
    int minutes, {
    required DateTime startTime,
    bool requestPermissions = true,
  }) async {
    await init(requestPermissions: false);
    if (requestPermissions) {
      await _ensureAlarmPermissions();
    }
    await cancelHydrationReminder();

    try {
      await _scheduleHydrationSlots(minutes, startTime);
    } catch (e) {
      debugPrint('AlarmService.scheduleHydrationReminder failed: $e');
    }
  }

  /// Cancel the active hydration reminder.
  Future<void> cancelHydrationReminder() async {
    try {
      await _cancelHydrationSchedules(dismissActiveNotifications: true);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Daily health advice
  // ---------------------------------------------------------------------------

  /// Schedule a daily health advice notification at 08:00.
  Future<void> scheduleDailyHealthAdvice(String advice) async {
    await init();
    final localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _dailyAdviceNotificationId,
          channelKey: _adviceChannelKey,
          title: 'Sika daily health tip',
          body: _trimForNotification(advice),
          category: NotificationCategory.Recommendation,
          payload: {'type': 'sika_daily_advice'},
        ),
        schedule: NotificationCalendar(
          hour: 8,
          minute: 0,
          second: 0,
          millisecond: 0,
          timeZone: localTimeZone,
          allowWhileIdle: true,
          preciseAlarm: true,
          repeats: true,
        ),
      );
    } catch (e) {
      debugPrint('AlarmService.scheduleDailyHealthAdvice failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Instant (confirmation) notifications
  // ---------------------------------------------------------------------------

  /// Show an immediate notification (e.g. to confirm a reminder was set).
  Future<void> showInstant({
    required String title,
    required String body,
    int id = 999999,
  }) async {
    await init();
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _instantChannelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: {'type': 'instant'},
        ),
      );
    } catch (e) {
      debugPrint('AlarmService.showInstant failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Dismissal
  // ---------------------------------------------------------------------------

  /// Dismiss the currently active alarm notification and pop the alarm screen.
  Future<void> dismissActiveAlarm() async {
    try {
      await AwesomeNotifications().dismissAllNotifications();
    } catch (_) {}
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    try {
      await AwesomeNotifications().cancelAll();
    } catch (_) {}
  }

  Future<AlarmHealthStatus> getHealthStatus() async {
    await init(requestPermissions: false);
    final notificationsAllowed =
        await AwesomeNotifications().isNotificationAllowed();
    final granted = await AwesomeNotifications()
        .checkPermissionList(permissions: _alarmPermissions);
    final missingPermissions = _alarmPermissions
        .where((permission) => !granted.contains(permission))
        .toList(growable: false);
    final scheduled = await AwesomeNotifications().listScheduledNotifications();

    int scheduledCustomAlarms = 0;
    int scheduledHydrationAlarms = 0;
    for (final notification in scheduled) {
      final channelKey = notification.content?.channelKey;
      if (channelKey == _alarmChannelKey) {
        scheduledCustomAlarms++;
      } else if (channelKey == _hydrationChannelKey ||
          channelKey == _legacyHydrationChannelKey) {
        scheduledHydrationAlarms++;
      }
    }

    return AlarmHealthStatus(
      notificationsAllowed: notificationsAllowed,
      allRequiredPermissionsGranted: missingPermissions.isEmpty,
      missingPermissions: missingPermissions,
      scheduledCustomAlarms: scheduledCustomAlarms,
      scheduledHydrationAlarms: scheduledHydrationAlarms,
      totalScheduledNotifications: scheduled.length,
    );
  }

  Future<void> requestAlarmPermissions() => _ensureAlarmPermissions();

  Future<void> openNotificationSettings() =>
      AwesomeNotifications().showNotificationConfigPage();

  Future<void> openAlarmSettings() => AwesomeNotifications().showAlarmPage();

  // ---------------------------------------------------------------------------
  // Static callbacks (awesome_notifications)
  // ---------------------------------------------------------------------------

  /// Called when the user taps a notification or action button.
  @pragma('vm:entry-point')
  static Future<void> _onActionReceived(ReceivedAction action) async {
    debugPrint('AlarmService._onActionReceived: ${action.payload}');
    final payloadType = action.payload?['type'] ?? '';
    if (payloadType == 'reminder') {
      final title = action.title ?? 'SickleCare Alarm';
      _navigateToAlarmScreen(title);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreated(
      ReceivedNotification notification) async {
    // No-op — available for future analytics / logging.
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayed(
      ReceivedNotification notification) async {
    debugPrint(
        'AlarmService._onNotificationDisplayed: ${notification.payload}');
    final payloadType = notification.payload?['type'] ?? '';
    if (payloadType == 'reminder') {
      final title = notification.title ?? 'SickleCare Alarm';
      _navigateToAlarmScreen(title);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceived(ReceivedAction action) async {
    // No-op — available for future analytics / logging.
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Push the full-screen alarm route. Retries for up to 2 seconds while the
  /// navigator is being attached (cold start from a killed process).
  static Future<void> _navigateToAlarmScreen(String title) async {
    for (int i = 0; i < 20; i++) {
      final nav = navigatorKey.currentState;
      if (nav != null) {
        // Defer to after the current frame to avoid widget-tree conflicts.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          nav.pushNamed('/alarm', arguments: title);
        });
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    debugPrint('AlarmService: failed to push /alarm — navigator not attached.');
  }

  /// Derive a stable, positive int ID from a string reminder ID.
  static int _notificationId(String reminderId) =>
      _reminderNotificationIdBase +
      (_stableStringHash(reminderId) % _reminderNotificationIdRange);

  Future<void> _ensureAlarmPermissions() async {
    final granted = await AwesomeNotifications()
        .checkPermissionList(permissions: _alarmPermissions);
    final missing = _alarmPermissions
        .where((permission) => !granted.contains(permission))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      await AwesomeNotifications()
          .requestPermissionToSendNotifications(permissions: missing);
    }
  }

  Future<void> _scheduleHydrationSlots(int minutes, DateTime startTime) async {
    final localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();
    const minutesPerDay = 24 * 60;
    final slotsPerDay = (minutesPerDay / minutes).ceil();
    var scheduledAt = _timeOfDayOnDate(DateTime.now(), startTime);

    for (var slot = 0; slot < slotsPerDay; slot++) {
      final minuteOfDay = scheduledAt.hour * 60 + scheduledAt.minute;
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _hydrationNotificationId(minutes, minuteOfDay),
          channelKey: _hydrationChannelKey,
          title: 'Drink water',
          body: 'Hydration helps prevent sickle-cell pain crises. '
              'Take a few sips now. (${_intervalLabel(minutes)})',
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          payload: {
            'type': 'hydration',
            'minutes': minutes.toString(),
            'time': _clockLabel(scheduledAt),
          },
        ),
        schedule: NotificationCalendar(
          hour: scheduledAt.hour,
          minute: scheduledAt.minute,
          second: 0,
          millisecond: 0,
          timeZone: localTimeZone,
          allowWhileIdle: true,
          preciseAlarm: true,
          repeats: true,
        ),
      );
      scheduledAt = scheduledAt.add(Duration(minutes: minutes));
    }
  }

  Future<void> _cancelHydrationSchedules({
    required bool dismissActiveNotifications,
  }) async {
    await AwesomeNotifications()
        .cancelSchedulesByChannelKey(_hydrationChannelKey);
    await AwesomeNotifications()
        .cancelSchedulesByChannelKey(_legacyHydrationChannelKey);
    await AwesomeNotifications().cancelSchedule(_legacyHydrationNotificationId);

    if (dismissActiveNotifications) {
      await AwesomeNotifications()
          .cancelNotificationsByChannelKey(_hydrationChannelKey);
      await AwesomeNotifications()
          .cancelNotificationsByChannelKey(_legacyHydrationChannelKey);
      await AwesomeNotifications().cancel(_legacyHydrationNotificationId);
    }
  }

  static int _hydrationNotificationId(int intervalMinutes, int minuteOfDay) =>
      _hydrationNotificationIdBase + intervalMinutes * 1440 + minuteOfDay;

  static int _stableStringHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  static DateTime _timeOfDayOnDate(DateTime date, DateTime time) => DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

  static String _clockLabel(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  /// Compute the next future occurrence of a given time-of-day.
  static DateTime _nextOccurrence(DateTime time) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static String _intervalLabel(int minutes) {
    if (minutes == 30) return 'every 30 minutes';
    if (minutes == 60) return 'every 1 hour';
    if (minutes == 120) return 'every 2 hours';
    return 'every $minutes minutes';
  }

  static String _trimForNotification(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 180) return compact;
    return '${compact.substring(0, 177)}...';
  }
}
