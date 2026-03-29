class ReminderModel {
  final int id;
  final String title;
  final String type; // medication | hydration | food | exercise
  final String time; // HH:mm
  final String frequency;
  bool isActive;

  ReminderModel({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.frequency,
    this.isActive = true,
  });

  String get typeEmoji {
    const map = {
      'medication': '💊', 'hydration': '💧',
      'food': '🥗', 'exercise': '🏃', 'other': '🔔',
    };
    return map[type] ?? '🔔';
  }

  factory ReminderModel.fromJson(Map<String, dynamic> j) => ReminderModel(
    id: j['id'], title: j['title'], type: j['type'],
    time: j['time'], frequency: j['frequency'],
    isActive: j['is_active'] ?? true,
  );
}
