import 'package:flutter/material.dart';

class HydrationProvider extends ChangeNotifier {
  final List<String> _hydrationReminders = [];

  List<String> get reminders => List.unmodifiable(_hydrationReminders);

  void addReminder(String reminder) {
    if (reminder.isNotEmpty) {
      _hydrationReminders.add(reminder);
      notifyListeners();
    }
  }

  void removeReminder(String reminder) {
    _hydrationReminders.remove(reminder);
    notifyListeners();
  }

  void clearReminders() {
    _hydrationReminders.clear();
    notifyListeners();
  }
}