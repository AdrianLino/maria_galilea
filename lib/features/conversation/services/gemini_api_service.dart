import 'dart:async';
import 'package:dio/dio.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/constant.dart';

class GeminiApiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1';

  late Dio _dio;
  final StreamController<String> _streamController = StreamController<String>.broadcast();

  // Obtener el stream para las respuestas
  Stream<String> get responseStream => _streamController.stream;

  GeminiApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ));
  }

  /// Realiza una solicitud a la API de Gemini para generar contenido
  Future<Map<String, dynamic>> generateContent({
    required String prompt,
    String model = 'gemini-2.0-flash', // Modelo actualizado
    int maxTokens = 4000,
    double temperature = 0.7,
  }) async {
    try {
      final apiKey = getStringAsync(GEMINI_API_KEY);

      if (apiKey.isEmpty) {
        throw Exception('API key no configurada. Por favor configura tu API key de Gemini.');
      }

      final response = await _dio.post(
        '/models/$model:generateContent?key=$apiKey',
        data: {
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': maxTokens,
            'temperature': temperature,
          }
        },
      );

      return response.data;
    } on DioException catch (e) {
      log('Error en solicitud Dio: ${e.message}');
      if (e.response != null) {
        log('Respuesta de error: ${e.response?.data}');
        throw Exception('Error de API: ${e.response?.data['error']['message'] ?? e.message}');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      log('Error general: $e');
      throw Exception('Error: $e');
    }
  }

  /// Versión que simula streaming enviando partes de la respuesta a través del stream
  Future<void> generateContentStream({
    required String prompt,
    String model = 'gemini-2.0-flash', // Modelo actualizado
    int maxTokens = 4000,
    double temperature = 0.7,
  }) async {
    try {
      final result = await generateContent(
        prompt: prompt,
        model: model,
        maxTokens: maxTokens,
        temperature: temperature,
      );

      if (result.containsKey('candidates') &&
          result['candidates'].isNotEmpty &&
          result['candidates'][0].containsKey('content') &&
          result['candidates'][0]['content'].containsKey('parts') &&
          result['candidates'][0]['content']['parts'].isNotEmpty) {

        final text = result['candidates'][0]['content']['parts'][0]['text'];

        // Simular streaming enviando la respuesta en pequeños fragmentos
        // Esto simula el comportamiento de streaming para la UI
        const chunkSize = 10;
        for (int i = 0; i < text.length; i += chunkSize) {
          final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
          _streamController.add(text.substring(i, end));
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } else {
        _streamController.add("No se recibió una respuesta válida de la API.");
      }

    } catch (e) {
      _streamController.addError(e);
    }
  }

  /// Genera una conversación con historial
  Future<Map<String, dynamic>> generateChat({
    required List<Map<String, dynamic>> messages,
    String model = 'gemini-2.0-flash', // Modelo actualizado
    int maxTokens = 4000,
    double temperature = 0.7,
  }) async {
    try {
      final apiKey = getStringAsync(GEMINI_API_KEY);

      if (apiKey.isEmpty) {
        throw Exception('API key no configurada. Por favor configura tu API key de Gemini.');
      }

      // Convertir mensajes al formato que espera la API de Gemini
      final List<Map<String, dynamic>> contents = [];

      for (var message in messages) {
        contents.add({
          'role': message['role'],
          'parts': [{'text': message['content']}]
        });
      }

      final response = await _dio.post(
        '/models/$model:generateContent?key=$apiKey',
        data: {
          'contents': contents,
          'generationConfig': {
            'maxOutputTokens': maxTokens,
            'temperature': temperature,
          }
        },
      );

      return response.data;
    } on DioException catch (e) {
      log('Error en solicitud Dio: ${e.message}');
      if (e.response != null) {
        log('Respuesta de error: ${e.response?.data}');
        throw Exception('Error de API: ${e.response?.data['error']['message'] ?? e.message}');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      log('Error general: $e');
      throw Exception('Error: $e');
    }
  }

  /// Obtiene la lista de modelos disponibles
  Future<Map<String, dynamic>> listModels() async {
    try {
      final apiKey = getStringAsync(GEMINI_API_KEY);

      if (apiKey.isEmpty) {
        throw Exception('API key no configurada. Por favor configura tu API key de Gemini.');
      }

      final response = await _dio.get(
        '/models?key=$apiKey',
      );

      return response.data;
    } on DioException catch (e) {
      log('Error al obtener modelos: ${e.message}');
      if (e.response != null) {
        log('Respuesta de error: ${e.response?.data}');
        throw Exception('Error de API: ${e.response?.data['error']['message'] ?? e.message}');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      log('Error general: $e');
      throw Exception('Error: $e');
    }
  }

  void dispose() {
    _streamController.close();
  }
}