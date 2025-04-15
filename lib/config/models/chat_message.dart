import 'package:isar/isar.dart';

part 'chat_message.g.dart';

@collection
class ChatMessage {
  Id id = Isar.autoIncrement;

  @Index()
  late String conversationId;

  late String role;       // "user" o "model"
  late String content;

  // Ahora es DateTime? para que coincida con el constructor
  DateTime? timestamp;

  bool isError;
  String errorMessage;

  ChatMessage({
    required this.conversationId,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isError = false,
    this.errorMessage = '',
  }) {
    // Si no recibimos un timestamp, se asigna DateTime.now().
    this.timestamp = timestamp ?? DateTime.now();
  }

  // Convierte un Map en una instancia de ChatMessage
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      conversationId: map['conversationId'] ?? '',
      role: map['role'] ?? 'user',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : null, // null => se usa DateTime.now() en el constructor
      isError: map['isError'] ?? false,
      errorMessage: map['errorMessage'] ?? '',
    );
  }

  // Convierte la instancia en un Map
  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'role': role,
      'content': content,
      'timestamp': timestamp?.toIso8601String() ?? '',
      'isError': isError,
      'errorMessage': errorMessage,
    };
  }

  // Formato simplificado para Gemini API
  Map<String, dynamic> toGeminiFormat() {
    return {
      'role': role,
      'content': content,
    };
  }
}
