class Chat {
  final String chatId;
  final String userId;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  Chat({
    required this.chatId,
    required this.userId,
    required this.createdAt,
    this.lastMessageAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    chatId: json['chat_id'],
    userId: json['user_id'],
    createdAt: DateTime.parse(json['created_at']),
    lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'chat_id': chatId,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'last_message_at': lastMessageAt?.toIso8601String(),
  };
}
