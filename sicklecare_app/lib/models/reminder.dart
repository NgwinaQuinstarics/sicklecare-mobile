class Reminder {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool repeatDaily;
  final bool enabled;

  Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.repeatDaily = true,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
        'repeatDaily': repeatDaily,
        'enabled': enabled,
      };

  factory Reminder.fromMap(Map<String, dynamic> m) => Reminder(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        time: DateTime.tryParse(m['time'] ?? '') ?? DateTime.now(),
        repeatDaily: m['repeatDaily'] ?? true,
        enabled: m['enabled'] ?? true,
      );

  Reminder copyWith({bool? enabled}) => Reminder(
        id: id,
        title: title,
        body: body,
        time: time,
        repeatDaily: repeatDaily,
        enabled: enabled ?? this.enabled,
      );
}
