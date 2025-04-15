import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

/// Inicializa Hive y Isar para almacenamiento local
Future<void> initHiveBoxes() async {
  // Inicializar Hive
  await Hive.initFlutter();

  // Registrar adaptadores si se usan objetos personalizados
  // Hive.registerAdapter(MiModeloAdapter());

  // Inicializar boxes principales
  await Hive.openBox('settings');
  await Hive.openBox('app_state');

  // Inicializar Isar si no se ha hecho en el servicio
  try {
    final dir = await getApplicationDocumentsDirectory();

    if (Isar.instanceNames.isEmpty) {
      await Isar.open(
        [ChatMessageSchema, ChatConversationSchema],
        directory: dir.path,
        inspector: true, // Permite inspeccionar la DB en modo desarrollo
      );
    }
  } catch (e) {
    print('Error al inicializar Isar: $e');
  }
}

/// Clase de ayuda para acceder a los boxes de Hive
class HiveBoxes {
  static Box get settings => Hive.box('settings');
  static Box get appState => Hive.box('app_state');

  // Métodos de ayuda para configuración
  static String? getGeminiApiKey() => settings.get('gemini_api_key');
  static Future<void> setGeminiApiKey(String value) => settings.put('gemini_api_key', value);

  static String? getN8nWebhookToken() => settings.get('n8n_webhook_token');
  static Future<void> setN8nWebhookToken(String value) => settings.put('n8n_webhook_token', value);

  static String? getN8nBaseUrl() => settings.get('n8n_base_url');
  static Future<void> setN8nBaseUrl(String value) => settings.put('n8n_base_url', value);
}