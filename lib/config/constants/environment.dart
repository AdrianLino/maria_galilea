import 'package:flutter_dotenv/flutter_dotenv.dart';



import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../features/conversation/utils/constant.dart' as AppConstants;

/// Clase para manejar variables de entorno y configuración
class Environment {
  // Inicializar entorno y cargar variables
  static Future<void> initEnvironment() async {
    try {
      // Inicializar SharedPreferences (proporcionado por nb_utils)
      await initialize();

      // Cargar archivo .env si existe
      await dotenv.load(fileName: ".env").catchError((e) {
        // Ignorar error si no existe el archivo
        log("No se encontró archivo .env o ocurrió un error: $e");
      });

      // Configurar API key desde .env si existe y no está establecida
      final currentApiKey = getStringAsync(AppConstants.GEMINI_API_KEY);
      if (currentApiKey.isEmpty) {
        final envApiKey = dotenv.env['GEMINI_API_KEY'];
        if (envApiKey != null && envApiKey.isNotEmpty) {
          await setValue(AppConstants.GEMINI_API_KEY, envApiKey);
        }
      }

      log("Entorno inicializado correctamente");
    } catch (e) {
      log("Error al inicializar entorno: $e");
    }
  }

  /// Obtener API key de Gemini
  static String getGeminiApiKey() {
    return getStringAsync(AppConstants.GEMINI_API_KEY);
  }

  /// Verificar si la app está configurada
  static bool isConfigured() {
    final apiKey = getStringAsync(AppConstants.GEMINI_API_KEY);
    return apiKey.isNotEmpty;
  }
  static String apiUrl = dotenv.env['API_URL'] ?? 'No está configurado el API_URL';

}

