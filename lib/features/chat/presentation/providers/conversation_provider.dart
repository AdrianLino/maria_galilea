import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../../config/constants/app_constans.dart';
import '../../../../config/models/chat_conversation.dart';
import '../../../../config/models/chat_message.dart';
import '../../../../config/services/isar_service.dart';


// Proveedor del servicio Isar
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

// Estado para las conversaciones
class ConversationsState {
  final List<ChatConversation> conversations;
  final bool isLoading;
  final String error;

  ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error = '',
  });

  ConversationsState copyWith({
    List<ChatConversation>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier para manejar las conversaciones
class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final IsarService _isarService;

  ConversationsNotifier(this._isarService) : super(ConversationsState()) {
    // Cargar conversaciones al inicializar
    loadConversations();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true);
    try {
      final conversations = await _isarService.getAllConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<ChatConversation?> getConversation(Id id) async {
    return await _isarService.getConversation(id);
  }

  Future<Id> createConversation(String title, {String model = AppConstants.DEFAULT_GEMINI_MODEL}) async {
    final conversation = ChatConversation(
      title: title,
      modelName: model,
    );

    final id = await _isarService.saveConversation(conversation);
    await loadConversations(); // Recargar la lista
    return id;
  }

  Future<void> updateConversation(ChatConversation conversation) async {
    conversation.markAsModified();
    await _isarService.saveConversation(conversation);
    await loadConversations(); // Recargar la lista
  }

  Future<void> deleteConversation(Id id) async {
    await _isarService.deleteConversation(id);
    await loadConversations(); // Recargar la lista
  }

  Future<void> deleteAllConversations() async {
    await _isarService.deleteAllConversations();
    await loadConversations(); // Recargar la lista
  }
}

// Proveedor para las conversaciones
final conversationsProvider = StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return ConversationsNotifier(isarService);
});

// Estado para los mensajes de una conversación
class MessagesState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String error;
  final String conversationId;

  MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error = '',
    this.conversationId = '',
  });

  MessagesState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? conversationId,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}

// Notifier para manejar los mensajes
class MessagesNotifier extends StateNotifier<MessagesState> {
  final IsarService _isarService;

  MessagesNotifier(this._isarService, String initialConversationId)
      : super(MessagesState(conversationId: initialConversationId)) {
    // Cargar mensajes de la conversación al inicializar
    if (initialConversationId.isNotEmpty) {
      loadMessages();
    }
  }

  Future<void> loadMessages() async {
    if (state.conversationId.isEmpty) return;

    state = state.copyWith(isLoading: true);
    try {
      final messages = await _isarService.getAllMessages(state.conversationId);
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> setConversationId(String conversationId) async {
    state = state.copyWith(conversationId: conversationId);
    await loadMessages();
  }

  Future<void> addMessage(String role, String content, {bool isError = false, String errorMessage = ''}) async {
    if (state.conversationId.isEmpty) return;

    final message = ChatMessage(
      conversationId: state.conversationId,
      role: role,
      content: content,
      isError: isError,
      errorMessage: errorMessage,
    );

    await _isarService.saveMessage(message);
    await loadMessages(); // Recargar mensajes
  }

  Future<void> deleteMessage(Id id) async {
    await _isarService.deleteMessage(id);
    await loadMessages(); // Recargar mensajes
  }

  List<Map<String, dynamic>> getMessagesForGemini() {
    return state.messages
        .where((msg) => !msg.isError) // No incluir mensajes con error
        .map((msg) => msg.toGeminiFormat())
        .toList();
  }
}

// Proveedor de fábrica para mensajes basado en ID de conversación
final messagesProvider = StateNotifierProvider.family<MessagesNotifier, MessagesState, String>(
        (ref, conversationId) {
      final isarService = ref.watch(isarServiceProvider);
      return MessagesNotifier(isarService, conversationId);
    }
);