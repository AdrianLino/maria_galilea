import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    final dir = await getApplicationDocumentsDirectory();

    if (Isar.instanceNames.isEmpty) {
      return await Isar.open(
        [ChatMessageSchema, ChatConversationSchema],
        directory: dir.path,
        inspector: true, // Permite inspeccionar la DB en modo desarrollo
      );
    }

    return Future.value(Isar.getInstance());
  }

  // Métodos para ChatMessage
  Future<List<ChatMessage>> getAllMessages(String conversationId) async {
    final isar = await db;
    return await isar.chatMessages
        .filter()
        .conversationIdEqualTo(conversationId)
        .sortByTimestampDesc()
        .findAll();
  }

  Future<void> saveMessage(ChatMessage message) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.chatMessages.put(message);
    });
  }

  Future<void> deleteMessage(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.chatMessages.delete(id);
    });
  }

  // Métodos para ChatConversation
  Future<List<ChatConversation>> getAllConversations() async {
    final isar = await db;
    return await isar.chatConversations
        .where()
        .sortByLastModifiedDesc()
        .findAll();
  }

  Future<ChatConversation?> getConversation(Id id) async {
    final isar = await db;
    return await isar.chatConversations.get(id);
  }

  Future<Id> saveConversation(ChatConversation conversation) async {
    final isar = await db;
    return await isar.writeTxn(() async {
      return await isar.chatConversations.put(conversation);
    });
  }

  Future<void> deleteConversation(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.chatMessages.filter().conversationIdEqualTo(id.toString()).deleteAll();
      await isar.chatConversations.delete(id);
    });
  }

  Future<void> deleteAllConversations() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.chatMessages.clear();
      await isar.chatConversations.clear();
    });
  }
}