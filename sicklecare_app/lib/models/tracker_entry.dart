class TrackerEntry {
  final String id;
  final DateTime date;
  final int painLevel; // 0-10
  final int hydrationMl;
  final String mood;
  final String notes;

  TrackerEntry({
    required this.id,
    required this.date,
    required this.painLevel,
    required this.hydrationMl,
    required this.mood,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'painLevel': painLevel,
        'hydrationMl': hydrationMl,
        'mood': mood,
        'notes': notes,
      };

  factory TrackerEntry.fromMap(Map<String, dynamic> m) => TrackerEntry(
        id: m['id'] ?? '',
        date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
        painLevel: (m['painLevel'] ?? 0) as int,
        hydrationMl: (m['hydrationMl'] ?? 0) as int,
        mood: m['mood'] ?? '',
        notes: m['notes'] ?? '',
      );
}
