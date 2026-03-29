class GoalModel {
  final int id;
  final String title;
  final String category;
  final double targetValue;
  double currentValue;
  final String unit;
  final String frequency;
  bool isCompleted;

  GoalModel({
    required this.id,
    required this.title,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.frequency,
    this.isCompleted = false,
  });

  double get percentage => targetValue == 0 ? 0 : (currentValue / targetValue).clamp(0, 1);

  String get categoryEmoji {
    const map = {
      'hydration': '💧', 'medication': '💊',
      'exercise': '🚶', 'sleep': '😴', 'nutrition': '🥗',
    };
    return map[category] ?? '🎯';
  }

  factory GoalModel.fromJson(Map<String, dynamic> j) => GoalModel(
    id: j['id'], title: j['title'], category: j['category'],
    targetValue: (j['target_value'] as num).toDouble(),
    currentValue: (j['current_value'] as num).toDouble(),
    unit: j['unit'], frequency: j['frequency'],
    isCompleted: j['is_completed'] ?? false,
  );
}
