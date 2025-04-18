// App-wide constants centralized in one file
class AppConstants {
  // API Keys and endpoints
  static const String DEFAULT_N8N_BASE_URL = 'https://your-n8n-instance.com';

  // Storage keys
  static const String GEMINI_API_KEY = 'AIzaSyCsZt5Dhy1C_HZd4q_uMeODusTcNjhubog';
  static const String N8N_WEBHOOK_TOKEN = 'n8n_webhook_token';
  static const String N8N_BASE_URL = 'n8n_base_url';
  static const String IN_APP_STORE_REVIEW = 'inAppStoreReview';

  // Gemini API Configuration
  static const String DEFAULT_GEMINI_MODEL = 'gemini-1.5-pro';
  static const String GEMINI_ADVANCED_MODEL = 'gemini-1.5-pro';
  static const int DEFAULT_MAX_TOKENS = 200;
  static const double DEFAULT_TEMPERATURE = 0.7;

  // UI/UX
  static const int SHOW_AD_COUNT = 4;

  // Default system prompt for Gemini
  static const String DEFAULT_SYSTEM_PROMPT =
      "You are a helpful assistant that provides clear, accurate, and concise answers. "
      "Respond in a friendly and conversational manner. "
      "If you are not sure about an answer, acknowledge that instead of providing incorrect information.";
}