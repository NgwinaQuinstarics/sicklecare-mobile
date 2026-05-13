class DailyHealth {
  double painLevel;
  double hydration;

  List<String> meals;
  List<Map<String, dynamic>> reminders;

  bool fatigue;
  bool fever;
  bool headache;

  String notes;

  DailyHealth({
    this.painLevel = 0,
    this.hydration = 0,
    this.meals = const [],
    this.reminders = const [],
    this.fatigue = false,
    this.fever = false,
    this.headache = false,
    this.notes = "",
  });

  Map<String, dynamic> toMap() {
    return {
      "painLevel": painLevel,
      "hydration": hydration,
      "meals": meals,
      "reminders": reminders,
      "fatigue": fatigue,
      "fever": fever,
      "headache": headache,
      "notes": notes,
    };
  }

  static DailyHealth fromMap(Map<String, dynamic>? map) {
    if (map == null) return DailyHealth();

    return DailyHealth(
      painLevel: (map["painLevel"] ?? 0).toDouble(),
      hydration: (map["hydration"] ?? 0).toDouble(),
      meals: List<String>.from(map["meals"] ?? []),
      reminders: List<Map<String, dynamic>>.from(map["reminders"] ?? []),
      fatigue: map["fatigue"] ?? false,
      fever: map["fever"] ?? false,
      headache: map["headache"] ?? false,
      notes: map["notes"] ?? "",
    );
  }
}