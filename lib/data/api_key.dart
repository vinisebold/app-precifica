// lib/data/api_key.dart
// Carrega a chave da API a partir de uma variável de ambiente/dart-define.
// Defina no build:
// flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
// Em CI (GitHub Actions), passe o segredo como --dart-define (exemplo no README).

const String apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

bool get isApiKeyConfigured => apiKey.isNotEmpty;