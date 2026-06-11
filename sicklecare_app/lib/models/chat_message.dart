class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime time;
  ChatMessage({required this.role, required this.content, required this.time});

  Map<String, dynamic> toMap() =>
      {'role': role, 'content': content, 'time': time.toIso8601String()};

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        role: m['role'] ?? 'assistant',
        content: m['content'] ?? '',
        time: DateTime.tryParse(m['time'] ?? '') ?? DateTime.now(),
      );
}
