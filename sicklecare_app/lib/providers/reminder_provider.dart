import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/reminder.dart';
import '../services/alarm_service.dart';

class ReminderProvider extends ChangeNotifier {
  static const _hydrationIntervalKey = 'hydration_interval_minutes';
  static const _hydrationStartMinutesKey = 'hydration_start_minutes';
  static const _scheduleSchemaVersionKey = 'reminder_schedule_schema_version';
  static const _auditLogKey = 'reminder_audit_log';
  static const _scheduleSchemaVersion = 2;
  static const _defaultHydrationStartMinutes = 8 * 60;
  static const _validHydrationIntervals = {30, 60, 120};

  final List<Reminder> _items = [];
  final List<String> _auditLog = [];
  int? _hydrationIntervalMinutes;
  int _hydrationStartMinutes = _defaultHydrationStartMinutes;

  List<Reminder> get items => List.unmodifiable(_items);
  List<String> get auditLog => List.unmodifiable(_auditLog);
  int? get hydrationIntervalMinutes => _hydrationIntervalMinutes;
  TimeOfDay get hydrationStartTime => TimeOfDay(
        hour: _hydrationStartMinutes ~/ 60,
        minute: _hydrationStartMinutes % 60,
      );
  bool get hydrationReminderEnabled => _hydrationIntervalMinutes != null;

  ReminderProvider() {
    load();
  }

  Future<void> load() async {
    _items.clear();
    final box = Hive.box('reminders');
    for (final v in box.values) {
      try {
        _items.add(Reminder.fromMap(Map<String, dynamic>.from(v as Map)));
      } catch (_) {}
    }
    _items.sort((a, b) => a.time.compareTo(b.time));

    final cache = Hive.box('app_cache');
    final storedInterval = cache.get(_hydrationIntervalKey);
    _hydrationIntervalMinutes = storedInterval is int &&
            _validHydrationIntervals.contains(storedInterval)
        ? storedInterval
        : null;
    final storedStartMinutes = cache.get(_hydrationStartMinutesKey);
    _hydrationStartMinutes =
        storedStartMinutes is int && _isValidMinuteOfDay(storedStartMinutes)
            ? storedStartMinutes
            : _defaultHydrationStartMinutes;
    final storedAudit = cache.get(_auditLogKey);
    _auditLog
      ..clear()
      ..addAll(storedAudit is List ? storedAudit.whereType<String>() : []);

    notifyListeners();
    if (cache.get(_scheduleSchemaVersionKey) != _scheduleSchemaVersion) {
      unawaited(_migrateSchedulesInBackground(cache));
    }
  }

  Future<void> add(Reminder r) async {
    await Hive.box('reminders').put(r.id, r.toMap());
    _items.add(r);
    _items.sort((a, b) => a.time.compareTo(b.time));
    if (r.enabled) {
      await AlarmService.instance.schedule(r);
      await _recordAudit('Scheduled custom alarm: ${r.title}');
      await AlarmService.instance.showInstant(
        title: '✅ ${r.title}',
        body: 'Reminder set! You will be notified at the scheduled time.',
      );
    }
    notifyListeners();
  }

  Future<void> toggle(String id, bool enabled) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return;
    final updated = _items[i].copyWith(enabled: enabled);
    _items[i] = updated;
    await Hive.box('reminders').put(id, updated.toMap());
    if (enabled) {
      await AlarmService.instance.schedule(updated);
      await _recordAudit('Enabled alarm: ${updated.title}');
    } else {
      await AlarmService.instance.cancel(id);
      await _recordAudit('Disabled alarm: ${updated.title}');
    }
    notifyListeners();
  }

  Future<void> update(Reminder reminder) async {
    final i = _items.indexWhere((e) => e.id == reminder.id);
    if (i == -1) return;

    await AlarmService.instance.cancel(reminder.id);
    await Hive.box('reminders').put(reminder.id, reminder.toMap());
    _items[i] = reminder;
    _items.sort((a, b) => a.time.compareTo(b.time));

    if (reminder.enabled) {
      await AlarmService.instance.schedule(reminder);
      await _recordAudit('Updated alarm: ${reminder.title}');
    }
    notifyListeners();
  }

  Future<void> setHydrationInterval(int? minutes) async {
    if (minutes != null && !_validHydrationIntervals.contains(minutes)) return;

    _hydrationIntervalMinutes = minutes;
    final cache = Hive.box('app_cache');
    if (minutes == null) {
      await cache.delete(_hydrationIntervalKey);
      await AlarmService.instance.cancelHydrationReminder();
      await _recordAudit('Disabled hydration reminders');
    } else {
      await cache.put(_hydrationIntervalKey, minutes);
      await AlarmService.instance.scheduleHydrationReminder(
        minutes,
        startTime: _hydrationStartDateTime(),
      );
      await _recordAudit(
        'Scheduled hydration every $minutes min from ${_formatTime(hydrationStartTime)}',
      );
    }
    notifyListeners();
  }

  Future<void> setHydrationStartTime(TimeOfDay time) async {
    _hydrationStartMinutes = time.hour * 60 + time.minute;
    await Hive.box('app_cache').put(
      _hydrationStartMinutesKey,
      _hydrationStartMinutes,
    );

    final minutes = _hydrationIntervalMinutes;
    if (minutes != null) {
      await AlarmService.instance.scheduleHydrationReminder(
        minutes,
        startTime: _hydrationStartDateTime(),
      );
      await _recordAudit(
        'Changed hydration start to ${_formatTime(time)}',
      );
    }
    notifyListeners();
  }

  Future<void> remove(String id) async {
    Reminder? removed;
    for (final item in _items) {
      if (item.id == id) {
        removed = item;
        break;
      }
    }
    await AlarmService.instance.cancel(id);
    await Hive.box('reminders').delete(id);
    _items.removeWhere((e) => e.id == id);
    await _recordAudit('Deleted alarm: ${removed?.title ?? id}');
    notifyListeners();
  }

  Future<void> repairSchedules({bool requestPermissions = true}) async {
    await _rescheduleAll(requestPermissions: requestPermissions);
    await _recordAudit(requestPermissions
        ? 'Repaired all local alarm schedules'
        : 'Auto-recovered local alarm schedules');
  }

  Future<void> _rescheduleAll({bool requestPermissions = true}) async {
    await AlarmService.instance.cancelReminderSchedules();
    for (final reminder in _items.where((r) => r.enabled)) {
      await AlarmService.instance.schedule(
        reminder,
        requestPermissions: requestPermissions,
      );
    }
    final minutes = _hydrationIntervalMinutes;
    if (minutes != null) {
      await AlarmService.instance.scheduleHydrationReminder(
        minutes,
        startTime: _hydrationStartDateTime(),
        requestPermissions: requestPermissions,
      );
    }
  }

  Future<void> _migrateSchedulesInBackground(Box cache) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    await _rescheduleAll(requestPermissions: false);
    await cache.put(_scheduleSchemaVersionKey, _scheduleSchemaVersion);
    await _recordAudit('Migrated local alarm schedules');
  }

  DateTime _hydrationStartDateTime() {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      _hydrationStartMinutes ~/ 60,
      _hydrationStartMinutes % 60,
    );
  }

  static bool _isValidMinuteOfDay(int value) => value >= 0 && value < 24 * 60;

  Future<void> _recordAudit(String message) async {
    final stamp = DateTime.now().toIso8601String();
    _auditLog.insert(0, '$stamp|$message');
    if (_auditLog.length > 20) {
      _auditLog.removeRange(20, _auditLog.length);
    }
    await Hive.box('app_cache').put(_auditLogKey, _auditLog);
  }

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
