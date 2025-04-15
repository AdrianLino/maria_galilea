import 'package:isar/isar.dart';

part 'chat_conversation.g.dart';

@collection
class ChatConversation {
  Id id = Isar.autoIncrement;

  late String title;
  String description = '';

  // DateTime? para que puedas usar DateTime.now() por defecto en el constructor
  DateTime? createdAt;
  DateTime? lastModified;

  @Index()
  // Si quieres que sea no anulable, usa 'late String modelName'
  // y dale valor por defecto en el constructor.
  late String modelName;

  ChatConversation({
    required this.title,
    this.description = '',
    // Aquí definimos el parámetro como no anulable con valor por defecto
    String modelName = 'gemini-2.0-flash',
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    // Asignamos 'modelName' al campo de la clase
    this.modelName = modelName;

    // Si no nos pasan createdAt/lastModified, se asigna DateTime.now()
    this.createdAt = createdAt ?? DateTime.now();
    this.lastModified = lastModified ?? DateTime.now();
  }

  // Método para convertir desde Map
  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      title: map['title'] ?? 'Nueva conversación',
      description: map['description'] ?? '',
      // Si map['modelName'] fuera nulo, se usará el valor por defecto del constructor
      modelName: map['modelName'] ?? 'gemini-2.0-flash',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      lastModified: map['lastModified'] != null
          ? DateTime.parse(map['lastModified'])
          : null,
    );
  }

  // Método para convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'modelName': modelName,
      'createdAt': createdAt?.toIso8601String() ?? '',
      'lastModified': lastModified?.toIso8601String() ?? '',
    };
  }

  void markAsModified() {
    lastModified = DateTime.now();
  }
}
