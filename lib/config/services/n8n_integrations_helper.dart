import 'package:dio/dio.dart';
import 'package:nb_utils/nb_utils.dart';

import '../constants/app_constans.dart';


class N8nIntegrationHelper {
  late Dio _dio;

  N8nIntegrationHelper() {
    _initDio();
  }

  void _initDio() async {
    final baseUrl = getStringAsync(AppConstants.N8N_BASE_URL, defaultValue: AppConstants.DEFAULT_N8N_BASE_URL);

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ));
  }

  /// Envia una consulta a la API de Gemini a través de n8n
  /// Esta función utiliza un workflow en n8n que llama a la API de Gemini
  Future<Map<String, dynamic>> generateContentViaN8n({
    required String prompt,
    String model = AppConstants.DEFAULT_GEMINI_MODEL,
    int maxTokens = AppConstants.DEFAULT_MAX_TOKENS,
    double temperature = AppConstants.DEFAULT_TEMPERATURE,
  }) async {
    try {
      final apiKey = getStringAsync(AppConstants.GEMINI_API_KEY);
      final n8nWebhookToken = getStringAsync(AppConstants.N8N_WEBHOOK_TOKEN);

      if (apiKey.isEmpty) {
        throw Exception('API key de Gemini no configurada.');
      }

      if (n8nWebhookToken.isEmpty) {
        throw Exception('Token de webhook de n8n no configurado.');
      }

      // Llamando al workflow de n8n que interactúa con Gemini
      final response = await _dio.post(
        '/webhook/gemini-integration?token=$n8nWebhookToken',
        data: {
          'apiKey': apiKey,
          'model': model,
          'prompt': prompt,
          'maxTokens': maxTokens,
          'temperature': temperature
        },
      );

      return response.data;
    } on DioException catch (e) {
      log('Error en solicitud a n8n: ${e.message}');
      if (e.response != null) {
        log('Respuesta de error: ${e.response?.data}');
        throw Exception('Error de n8n: ${e.response?.data['message'] ?? e.message}');
      }
      throw Exception('Error de conexión con n8n: ${e.message}');
    } catch (e) {
      log('Error general: $e');
      throw Exception('Error: $e');
    }
  }

  /// Sincroniza las conversaciones con n8n para su procesamiento
  Future<Map<String, dynamic>> syncConversations({
    required List<Map<String, dynamic>> conversations,
  }) async {
    try {
      final n8nWebhookToken = getStringAsync(AppConstants.N8N_WEBHOOK_TOKEN);

      if (n8nWebhookToken.isEmpty) {
        throw Exception('Token de webhook de n8n no configurado.');
      }

      final response = await _dio.post(
        '/webhook/sync-conversations?token=$n8nWebhookToken',
        data: {
          'conversations': conversations
        },
      );

      return response.data;
    } on DioException catch (e) {
      log('Error al sincronizar conversaciones: ${e.message}');
      if (e.response != null) {
        log('Respuesta de error: ${e.response?.data}');
        throw Exception('Error de n8n: ${e.response?.data['message'] ?? e.message}');
      }
      throw Exception('Error de conexión con n8n: ${e.message}');
    } catch (e) {
      log('Error general: $e');
      throw Exception('Error: $e');
    }
  }

  /// Programa una notificación para ser enviada más tarde
  Future<Map<String, dynamic>> scheduleNotification({
    required String userId,
    required String message,
    required DateTime scheduledTime,
    String notificationType = 'reminder',
  }) async {
    try {
      final n8nWebhookToken = getStringAsync(AppConstants.N8N_WEBHOOK_TOKEN);

      if (n8nWebhookToken.isEmpty) {
        throw Exception('Token de webhook de n8n no configurado.');
      }

      final response = await _dio.post(
        '/webhook/schedule-notification?token=$n8nWebhookToken',
        data: {
          'userId': userId,
          'message': message,
          'scheduledTime': scheduledTime.toIso8601String(),
          'notificationType': notificationType
        },
      );

      return response.data;
    } on DioException catch (e) {
      log('Error al programar notificación: ${e.message}');
      if (e.response != null) {
        log('Respuesta de error: ${e.response?.data}');
        throw Exception('Error de n8n: ${e.response?.data['message'] ?? e.message}');
      }
      throw Exception('Error de conexión con n8n: ${e.message}');
    } catch (e) {
      log('Error general: $e');
      throw Exception('Error: $e');
    }
  }
}