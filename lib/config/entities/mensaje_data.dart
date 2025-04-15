class Mensaje {
  final String messageId;
  final String chatId;
  final String senderType; // Enum: user, bot
  final String? textContent;
  final DateTime timestamp;
  final Map<String, dynamic>? metaInfo;

  Mensaje({
    required this.messageId,
    required this.chatId,
    required this.senderType,
    this.textContent,
    required this.timestamp,
    this.metaInfo,
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) => Mensaje(
    messageId: json['message_id'],
    chatId: json['chat_id'],
    senderType: json['sender_type'],
    textContent: json['text_content'],
    timestamp: DateTime.parse(json['timestamp']),
    metaInfo: json['meta_info'] != null ? Map<String, dynamic>.from(json['meta_info']) : null,
  );

  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'chat_id': chatId,
    'sender_type': senderType,
    'text_content': textContent,
    'timestamp': timestamp.toIso8601String(),
    'meta_info': metaInfo,
  };
}
