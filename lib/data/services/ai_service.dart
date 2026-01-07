import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:precifica/data/api_key.dart';

class AIService {
  final String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  /// Envia os dados JSON para a IA (Gemini) e retorna a versão reorganizada.
  ///
  /// Lança uma exceção se a chamada de API falhar ou retornar um status de erro.
  Future<String> organizarCategorias({required String jsonAtual}) async {
    if (!isApiKeyConfigured) {
      throw Exception(
        'GEMINI_API_KEY não configurada. Defina via --dart-define=GEMINI_API_KEY=SUACHAVE ou variável de ambiente no pipeline.',
      );
    }
    final headers = {
      'x-goog-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    // Monta o corpo da requisição no formato aceito pelo Gemini
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text': 'Reorganize o JSON em categorias coerentes por similaridade funcional. '
                  'JSON:\n$jsonAtual\n\n'
                  'Regras:\n'
                  '1. Agrupe itens por similaridade (funcional, uso ou segmento)\n'
                  '2. Nomes de categorias: curtos (máx 2-3 palavras), didáticos e intuitivos. Evite termos técnicos ou complicados\n'
                  '3. Crie, renomeie ou una categorias conforme necessário\n'
                  '4. Preserve TODAS as propriedades originais de cada produto\n'
                  '5. Formato: {"nome": "Categoria", "produtos": [{...}]}\n'
                  '6. Remova duplicidades e normalize espaçamentos\n'
                  '7. Sem categorias vazias (use "Outros" se necessário)\n'
                  '8. Ordene alfabeticamente categorias e produtos por "nome"\n'
                  '9. JSON válido (aspas duplas, estrutura balanceada)\n\n'
                  'Retorne APENAS o JSON reorganizado, sem texto adicional ou markdown.'
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
      }
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody.containsKey('candidates') &&
            responseBody['candidates'].isNotEmpty) {
          final text =
              responseBody['candidates'][0]['content']['parts'][0]['text'];
          return text.trim();
        } else {
          throw Exception(
              'Resposta da API em formato inesperado: ${response.body}');
        }
      } else {
        throw Exception(
            'Erro na API do Gemini: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao comunicar com o serviço de IA: $e');
    }
  }
}
