import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  final List<Reminder> _items = [];
  List<Reminder> get items => List.unmodifiable(_items);

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
    notifyListeners();
  }

  Future<void> add(Reminder r) async {
    await Hive.box('reminders').put(r.id, r.toMap());
    _items.add(r);
    if (r.enabled) {
      await NotificationService.instance.schedule(r);
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
      await NotificationService.instance.schedule(updated);
    } else {
      await NotificationService.instance.cancel(id);
    }
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await NotificationService.instance.cancel(id);
    await Hive.box('reminders').delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
