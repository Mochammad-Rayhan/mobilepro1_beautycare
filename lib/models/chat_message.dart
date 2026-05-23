class ChatMessage {
  final int? id;
  final int sessionId;
  final int userId;
  final String message;
  final bool isUser;
  final String? imagePath;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.sessionId,
    required this.userId,
    required this.message,
    required this.isUser,
    this.imagePath,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'message': message,
      'isUser': isUser ? 1 : 0,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      sessionId: map['sessionId'],
      userId: map['userId'],
      message: map['message'],
      isUser: map['isUser'] == 1,
      imagePath: map['imagePath'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
