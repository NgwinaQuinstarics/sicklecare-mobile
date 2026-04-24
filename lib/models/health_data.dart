class HealthData {
  final double painLevel;
  final double hydration;
  final List<dynamic> meals;

  HealthData({
    required this.painLevel,
    required this.hydration,
    required this.meals,
  });

  factory HealthData.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return HealthData(painLevel: 0, hydration: 0, meals: []);
    }

    return HealthData(
      painLevel: (data['painLevel'] ?? 0).toDouble(),
      hydration: (data['hydration'] ?? 0).toDouble(),
      meals: List<dynamic>.from(data['meals'] ?? []),
    );
  }
}