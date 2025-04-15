import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../config/constants/app_constans.dart';
import '../../../conversation/colors.dart';
import '../providers/gemini_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _n8nUrlController = TextEditingController();
  final TextEditingController _n8nTokenController = TextEditingController();
  bool _obscureApiKey = true;
  bool _obscureN8nToken = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _apiKeyController.text = getStringAsync(AppConstants.GEMINI_API_KEY);
    _n8nUrlController.text = getStringAsync(AppConstants.N8N_BASE_URL, defaultValue: AppConstants.DEFAULT_N8N_BASE_URL);
    _n8nTokenController.text = getStringAsync(AppConstants.N8N_WEBHOOK_TOKEN);
  }

  Future<void> _saveSettings() async {
    final apiKey = _apiKeyController.text.trim();
    final n8nUrl = _n8nUrlController.text.trim();
    final n8nToken = _n8nTokenController.text.trim();

    await setValue(AppConstants.GEMINI_API_KEY, apiKey);

    if (n8nUrl.isNotEmpty) {
      await setValue(AppConstants.N8N_BASE_URL, n8nUrl);
    }

    if (n8nToken.isNotEmpty) {
      await setValue(AppConstants.N8N_WEBHOOK_TOKEN, n8nToken);
    }

    toast('Configuración guardada correctamente');

    // Forzar la recarga de los proveedores que dependen de estas configuraciones
    ref.invalidate(apiKeyConfiguredProvider);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _n8nUrlController.dispose();
    _n8nTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
        backgroundColor: appColorPrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API de Gemini',
              style: boldTextStyle(size: 18),
            ),
            16.height,
            Container(
              decoration: boxDecorationDefault(
                borderRadius: radius(8),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Key de Gemini',
                    style: boldTextStyle(),
                  ),
                  8.height,
                  Text(
                    'Introduce tu API key de Google Gemini. Puedes obtenerla en Google AI Studio (https://makersuite.google.com/)',
                    style: secondaryTextStyle(),
                  ),
                  16.height,
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      hintText: 'Introduce tu API key',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureApiKey = !_obscureApiKey;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureApiKey,
                  ),
                ],
              ),
            ),
            32.height,
            Text(
              'Configuración de n8n',
              style: boldTextStyle(size: 18),
            ),
            16.height,
            Container(
              decoration: boxDecorationDefault(
                borderRadius: radius(8),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URL Base de n8n',
                    style: boldTextStyle(),
                  ),
                  8.height,
                  Text(
                    'URL de tu instancia de n8n (ej: https://tu-instancia-n8n.com)',
                    style: secondaryTextStyle(),
                  ),
                  16.height,
                  TextField(
                    controller: _n8nUrlController,
                    decoration: InputDecoration(
                      hintText: 'URL de n8n',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  16.height,
                  Text(
                    'Token de Webhook de n8n',
                    style: boldTextStyle(),
                  ),
                  8.height,
                  Text(
                    'Token de autenticación para tus webhooks de n8n',
                    style: secondaryTextStyle(),
                  ),
                  16.height,
                  TextField(
                    controller: _n8nTokenController,
                    decoration: InputDecoration(
                      hintText: 'Token de webhook',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureN8nToken ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureN8nToken = !_obscureN8nToken;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureN8nToken,
                  ),
                ],
              ),
            ),
            32.height,
            ElevatedButton(
              onPressed: _saveSettings,
              child: Text('Guardar Configuración'),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColorPrimary,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            32.height,
            Container(
              decoration: boxDecorationDefault(
                borderRadius: radius(8),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instrucciones',
                    style: boldTextStyle(),
                  ),
                  8.height,
                  Text(
                    '1. Para la API Key de Gemini:\n'
                        '   - Visita Google AI Studio (https://makersuite.google.com/)\n'
                        '   - Crea o inicia sesión en una cuenta de Google\n'
                        '   - Ve a "API Keys" en el menú\n'
                        '   - Crea una nueva API key\n\n'
                        '2. Para configurar n8n:\n'
                        '   - Configura tu instancia de n8n\n'
                        '   - Importa los workflows proporcionados\n'
                        '   - Configura un token de webhook en n8n\n'
                        '   - Introduce la URL y el token en esta pantalla',
                    style: secondaryTextStyle(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}