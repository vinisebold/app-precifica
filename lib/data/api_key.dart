const String apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

bool get isApiKeyConfigured => apiKey.isNotEmpty;