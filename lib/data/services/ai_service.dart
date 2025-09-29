import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:precifica/data/api_key.dart';

class AIService {
  final String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey';

  /// Envia os dados JSON para a IA e retorna a versão reorganizada.
  ///
  /// Lança uma exceção se a chamada de API falhar ou retornar um status de erro.
  Future<String> organizarCategorias({required String jsonAtual}) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": '''
                    Você é um especialista em categorização de produtos de mercado.
                    Analise o seguinte JSON e reorganize os produtos em categorias mais lógicas e otimizadas.
                    Você pode criar, fundir ou renomear categorias conforme necessário. O JSON de entrada é:
                    $jsonAtual

                    Retorne APENAS o novo JSON reorganizado, sem nenhum texto, explicação ou formatação de markdown como ```json ```.
                  '''
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // 5. Extração da resposta no formato do Gemini
        return body['candidates'][0]['content']['parts'][0]['text'].trim();
      } else {
        throw Exception(
            'Erro na API de IA: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao comunicar com o serviço de IA: $e');
    }
  }
}
