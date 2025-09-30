const String apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyBm1cNy55PlhglL7omP1KntroJzCD_Lsc0');

bool get isApiKeyConfigured => apiKey.isNotEmpty;