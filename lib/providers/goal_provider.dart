import 'package:flutter/material.dart';

class GoalProvider extends ChangeNotifier {
  final List<String> _goals = []; // fixed with final

  List<String> get goals => List.unmodifiable(_goals);

  void addGoal(String goal) {
    if (goal.isNotEmpty) {
      _goals.add(goal);
      notifyListeners();
    }
  }

  void removeGoal(String goal) {
    _goals.remove(goal);
    notifyListeners();
  }

  void clearGoals() {
    _goals.clear();
    notifyListeners();
  }
}