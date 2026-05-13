class HealthData {
  final double painLevel;
  final double hydration;
  final List meals;

  HealthData({
    required this.painLevel,
    required this.hydration,
    required this.meals,
  });

  factory HealthData.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return HealthData(
        painLevel: 0,
        hydration: 0,
        meals: [],
      );
    }

    return HealthData(
      painLevel: (map['painLevel'] ?? 0).toDouble(),
      hydration: (map['hydration'] ?? 0).toDouble(),
      meals: List.from(map['meals'] ?? []),
    );
  }
}