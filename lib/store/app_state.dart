import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/reminder_model.dart';
import '../models/goal_model.dart';

// ─── Auth Provider ────────────────────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  void setUser(UserModel? u) { _user = u; notifyListeners(); }
  void setLoading(bool v)    { _loading = v; notifyListeners(); }
  void setError(String? e)   { _error = e; notifyListeners(); }
  void clear()               { _user = null; notifyListeners(); }
}

// ─── Reminders Provider ───────────────────────────────────────────────────────

class ReminderProvider extends ChangeNotifier {
  final List<ReminderModel> _reminders = [
    // Seed data — replaced by API when backend ready
    ReminderModel(id: 1, title: 'Hydroxyurea 500mg', type: 'medication', time: '08:00', frequency: 'daily'),
    ReminderModel(id: 2, title: 'Morning water',     type: 'hydration',  time: '08:30', frequency: 'daily'),
    ReminderModel(id: 3, title: 'Lunch + iron meal', type: 'food',       time: '13:00', frequency: 'weekdays'),
    ReminderModel(id: 4, title: 'Folic Acid 5mg',    type: 'medication', time: '21:00', frequency: 'daily'),
    ReminderModel(id: 5, title: 'Sleep reminder',    type: 'other',      time: '22:00', frequency: 'daily', isActive: false),
  ];

  List<ReminderModel> get all => _reminders;

  List<ReminderModel> get morning   => _reminders.where((r) {
    final h = int.tryParse(r.time.split(':').first) ?? 0;
    return h >= 5 && h < 12;
  }).toList();

  List<ReminderModel> get afternoon => _reminders.where((r) {
    final h = int.tryParse(r.time.split(':').first) ?? 0;
    return h >= 12 && h < 17;
  }).toList();

  List<ReminderModel> get evening => _reminders.where((r) {
    final h = int.tryParse(r.time.split(':').first) ?? 0;
    return h >= 17 || h < 5;
  }).toList();

  void add(ReminderModel r) { _reminders.insert(0, r); notifyListeners(); }

  void toggle(int id, bool val) {
    final i = _reminders.indexWhere((r) => r.id == id);
    if (i != -1) { _reminders[i].isActive = val; notifyListeners(); }
  }

  void remove(int id) {
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}

// ─── Goals Provider ───────────────────────────────────────────────────────────

class GoalProvider extends ChangeNotifier {
  final List<GoalModel> _goals = [
    GoalModel(id: 1, title: 'Daily Hydration',      category: 'hydration',  targetValue: 8,  currentValue: 5, unit: 'glasses', frequency: 'daily'),
    GoalModel(id: 2, title: 'Medication Adherence', category: 'medication', targetValue: 3,  currentValue: 2, unit: 'meds',    frequency: 'daily'),
    GoalModel(id: 3, title: 'Light Exercise 30min', category: 'exercise',   targetValue: 1,  currentValue: 1, unit: 'session', frequency: 'daily', isCompleted: true),
    GoalModel(id: 4, title: 'Sleep 8 Hours',        category: 'sleep',      targetValue: 8,  currentValue: 7, unit: 'hours',   frequency: 'daily'),
    GoalModel(id: 5, title: 'Iron-rich Meals',      category: 'nutrition',  targetValue: 3,  currentValue: 1, unit: 'meals',   frequency: 'daily'),
  ];

  List<GoalModel> get all => _goals;
  int get completed => _goals.where((g) => g.isCompleted).length;
  double get weeklyPct => _goals.isEmpty ? 0 : completed / _goals.length;

  void add(GoalModel g) { _goals.insert(0, g); notifyListeners(); }
}

// ─── Hydration Provider ───────────────────────────────────────────────────────

class HydrationProvider extends ChangeNotifier {
  int _glasses = 5;
  final int goal = 8;
  final List<int> _weekStreak = [1, 1, 1, 0, 1, 1, 2]; // 1=done,0=miss,2=today

  int get glasses => _glasses;
  List<int> get weekStreak => _weekStreak;
  double get percentage => _glasses / goal;

  void logGlass() {
    if (_glasses < goal) { _glasses++; notifyListeners(); }
  }

  void setGlasses(int v) { _glasses = v; notifyListeners(); }
}
