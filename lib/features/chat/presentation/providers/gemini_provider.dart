import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:async';

import '../../../../config/constants/app_constans.dart';
import '../../../../config/services/gemini_api_service.dart';
import '../../../conversation/models/question_answer_model.dart';



// Provider para el servicio de Gemini API
final geminiServiceProvider = Provider<GeminiApiService>((ref) {
  final service = GeminiApiService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// Estado para el proveedor de chat
class ChatState {
  final List<QuestionAnswerModel> messages;
  final bool isLoading;
  final String error;
  final int selectedModelIndex;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error = '',
    this.selectedModelIndex = 0,
  });

  ChatState copyWith({
    List<QuestionAnswerModel>? messages,
    bool? isLoading,
    String? error,
    int? selectedModelIndex,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedModelIndex: selectedModelIndex ?? this.selectedModelIndex,
    );
  }
}

// Notifier para manejar el estado del chat
class ChatNotifier extends StateNotifier<ChatState> {
  final GeminiApiService _geminiService;
  StreamSubscription<String>? _streamSubscription;
  List<Map<String, dynamic>> _chatHistory = [];

  ChatNotifier(this._geminiService) : super(ChatState()) {
    _initStreamSubscription();
  }

  void _initStreamSubscription() {
    _streamSubscription = _geminiService.responseStream.listen(
          (chunk) {
        if (state.messages.isNotEmpty) {
          final updatedMessages = List<QuestionAnswerModel>.from(state.messages);
          updatedMessages.first.answer!.write(chunk);
          state = state.copyWith(messages: updatedMessages);
        }
      },
      onError: (error) {
        if (state.messages.isNotEmpty) {
          final updatedMessages = List<QuestionAnswerModel>.from(state.messages);
          updatedMessages.first.answer!.write("Error: $error");
          state = state.copyWith(messages: updatedMessages, error: error.toString());
        }
      },
    );
  }

  void setSelectedModel(int index) {
    state = state.copyWith(selectedModelIndex: index);
  }

  Future<void> sendMessage(String question, {String smartCompose = ''}) async {
    if (question.isEmpty) return;

    final fullQuestion = smartCompose.isNotEmpty ? '$smartCompose$question' : question;

    // Añadir el mensaje del usuario a la lista de mensajes
    final newMessage = QuestionAnswerModel(
      question: fullQuestion,
      answer: StringBuffer(),
      isLoading: true,
      smartCompose: smartCompose,
    );

    final updatedMessages = [newMessage, ...state.messages];
    state = state.copyWith(messages: updatedMessages, isLoading: true);

    try {
      // Guardar mensaje en el historial de chat
      _chatHistory.add({
        'role': 'user',
        'content': fullQuestion
      });

      // Limitar tamaño del historial
      if (_chatHistory.length > 20) {
        _chatHistory = _chatHistory.sublist(_chatHistory.length - 20);
      }

      if (state.selectedModelIndex == 0) {
        // Para el modelo estándar (streaming)
        await _geminiService.generateContentStream(
          prompt: fullQuestion,
          model: AppConstants.DEFAULT_GEMINI_MODEL,
          maxTokens: AppConstants.DEFAULT_MAX_TOKENS,
          temperature: AppConstants.DEFAULT_TEMPERATURE,
        );
      } else {
        // Para el modelo avanzado (chat completo)
        final response = await _geminiService.generateChat(
          messages: _chatHistory,
          model: AppConstants.GEMINI_ADVANCED_MODEL,
          maxTokens: AppConstants.DEFAULT_MAX_TOKENS,
          temperature: AppConstants.DEFAULT_TEMPERATURE,
        );

        if (response.containsKey('candidates') &&
            response['candidates'].isNotEmpty &&
            response['candidates'][0].containsKey('content') &&
            response['candidates'][0]['content'].containsKey('parts') &&
            response['candidates'][0]['content']['parts'].isNotEmpty) {

          final text = response['candidates'][0]['content']['parts'][0]['text'];

          final updatedMessages = List<QuestionAnswerModel>.from(state.messages);
          updatedMessages.first.answer!.write(text);
          state = state.copyWith(messages: updatedMessages);

          // Guardar respuesta en el historial
          _chatHistory.add({
            'role': 'model',
            'content': text
          });
        } else {
          final updatedMessages = List<QuestionAnswerModel>.from(state.messages);
          updatedMessages.first.answer!.write("No se recibió una respuesta válida de la API.");
          state = state.copyWith(messages: updatedMessages);
        }
      }
    } catch (error) {
      final updatedMessages = List<QuestionAnswerModel>.from(state.messages);
      updatedMessages.first.answer!.write("An error occurred: $error");
      state = state.copyWith(messages: updatedMessages, error: error.toString());
    } finally {
      final updatedMessages = List<QuestionAnswerModel>.from(state.messages);
      updatedMessages.first.isLoading = false;
      state = state.copyWith(messages: updatedMessages, isLoading: false);
    }
  }

  void clearChat() {
    _chatHistory.clear();
    state = state.copyWith(messages: []);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

// Proveedor para el estado del chat
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return ChatNotifier(geminiService);
});

// Proveedor para verificar si la API key está configurada
final apiKeyConfiguredProvider = FutureProvider<bool>((ref) async {
  final apiKey = getStringAsync(AppConstants.GEMINI_API_KEY);
  return apiKey.isNotEmpty;
});