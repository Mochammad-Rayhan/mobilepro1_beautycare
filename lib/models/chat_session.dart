class ChatSession {
  final int? id;
  final int userId;
  final String title;
  final DateTime timestamp;

  ChatSession({
    this.id,
    required this.userId,
    required this.title,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
