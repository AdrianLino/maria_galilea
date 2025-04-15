# IqonicBot - Chatbot con Gemini AI

Una aplicación móvil desarrollada con Flutter y Riverpod para integrar la API de Gemini AI en un chatbot intuitivo y fácil de usar.

## Características

- 💬 Interfaz de chat intuitiva
- 🧠 Integración con Gemini AI (modelos 2.0 Flash y 1.5 Pro)
- 🗄️ Almacenamiento local con Isar Database
- 🔄 Gestión de estado con Riverpod
- 🎯 Soporte para múltiples conversaciones
- 🔊 Funcionalidad de Text-to-Speech
- 🗣️ Reconocimiento de voz (Speech-to-Text)
- ⚙️ Panel de configuración de API

## Estructura del Proyecto

```
lib/
├── components/           # Widgets reutilizables
├── config/               # Configuración de la aplicación
│   ├── app_constants.dart     # Constantes centralizadas --
│   ├── app_theme.dart         # Temas y estilos
│   ├── environment.dart       # Configuración de entorno
│   └── routes.dart            # Rutas de la aplicación (go_router)
├── models/               # Modelos de datos
│   ├── chat_conversation.dart # Modelo de conversación
│   ├── chat_message.dart      # Modelo de mensaje
│   └── question_answer_model.dart # Modelo de pregunta-respuesta (legacy)
├── providers/            # Proveedores de Riverpod
│   ├── conversation_provider.dart # Gestión de conversaciones y mensajes 
│   └── gemini_provider.dart       # Gestión de la API de Gemini --
├── screens/              # Pantallas de la aplicación
│   ├── chatting_screen.dart       # Pantalla de chat
│   ├── conversations_list_screen.dart # Lista de conversaciones
│   ├── empty_screen.dart          # Pantalla vacía
│   └── settings_screen.dart       # Configuración
├── services/             # Servicios de la aplicación
│   ├── gemini_api_service.dart    # Servicio para la API de Gemini
│   ├── isar_service.dart          # Servicio para Isar DB
│   └── n8n_integration_helper.dart # Servicio para integración con n8n--
├── utils/                # Utilidades
│   ├── colors.dart            # Colores de la aplicación
│   ├── common.dart            # Funciones comunes
│   ├── hive_boxes.dart        # Configuración de Hive
│   └── images.dart            # Rutas de imágenes
└── main.dart             # Punto de entrada de la aplicación
```

## Configuración

Para usar esta aplicación, necesitas:

1. Una API key de Google Gemini AI
2. Flutter 3.10.0 o superior
3. Dart 3.0.0 o superior

### Pasos para la configuración:

1. Clona este repositorio
2. Ejecuta `flutter pub get` para instalar dependencias
3. Crea un archivo `.env` en la raíz del proyecto con:
   ```
   GEMINI_API_KEY=tu_api_key_aquí
   ```
4. También puedes configurar la API key desde la pantalla de configuración de la aplicación

## Dependencias Principales

- **flutter_riverpod**: Gestión de estado
- **isar**: Base de datos local
- **go_router**: Navegación
- **dio**: Cliente HTTP
- **nb_utils**: Utilidades varias
- **speech_to_text**: Reconocimiento de voz
- **flutter_tts**: Síntesis de voz
- **hive_flutter**: Almacenamiento clave-valor
- **flutter_dotenv**: Variables de entorno

## Modelos de Gemini AI

La aplicación soporta dos modelos de Gemini:

- **gemini-2.0-flash**: Modelo estándar (rápido)
- **gemini-1.5-pro-latest**: Modelo avanzado (más capacidades)

## Licencia

Este proyecto está licenciado bajo MIT License.