import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:precificador/data/api_key.dart';

class AIService {
  final String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

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
              'text': 'Você é um especialista global em categorização e taxonomia de produtos. '
                  'Objetivo: reorganize o JSON enviado pelo usuário em grupos coerentes de categorias, '
                  'preparados para qualquer tipo de item (varejo físico ou digital). Use o arquivo assets/profiles/Hortifruti.json '
                  'apenas como referência de excelência para a organização e nomenclatura, mas adapte-se a todos os contextos.\n\n'
                  'Dados de entrada:\n$jsonAtual\n\n'
                  'Regras:\n'
                  '1. Analise os itens e agrupe-os por similaridade funcional, uso ou segmento (não restringir a alimentos).\n'
                  '2. Crie novas categorias quando necessário; renomeie ou una categorias para evitar sobreposições.\n'
                  '3. Mantenha para cada produto todas as propriedades originais recebidas (nome, códigos, medidas, descrições, etc.).\n'
                  '4. Certifique-se de que cada categoria siga o formato: {"nome": "<nome da categoria>", "produtos": [{...}]}.\n'
                  '5. Remova duplicidades e normalize espaçamentos, mantendo a grafia já existente (inclusive maiúsculas/minúsculas) sempre que fizer sentido.\n'
                  '6. Não deixe categorias vazias; se um item não se encaixar, crie uma categoria "Outros" ou similar e explique brevemente no campo "nome" (ex.: "Outros / Itens Especiais").\n'
                  '7. Ordene categorias e os produtos dentro de cada categoria em ordem alfabética pelo campo "nome".\n'
                  '8. Preserve metadados adicionais presentes no JSON original em cada produto ou categoria.\n'
                  '9. Valide o JSON final (aspas duplas, chaves e colchetes balanceados, sem campos nulos indevidos) antes de responder.\n\n'
                  'Exemplo de saída ilustrativa (adapte conforme os dados reais, preservando todos os campos originais):\n'
                  '[\n'
                  '  {\n'
                  '    "nome": "Bebidas",\n'
                  '    "produtos": [\n'
                  '      {\n'
                  '        "nome": "Suco de Laranja",\n'
                  '        "sku": "123",\n'
                  '        "descricao": "Exemplo de descrição"\n'
                  '      }\n'
                  '    ]\n'
                  '  },\n'
                  '  {\n'
                  '    "nome": "Outros / Itens Especiais",\n'
                  '    "produtos": [\n'
                  '      {\n'
                  '        "nome": "Item Personalizado",\n'
                  '        "codigo_interno": "XYZ-999"\n'
                  '      }\n'
                  '    ]\n'
                  '  }\n'
                  ']\n\n'
                  'Checklist antes de responder:\n'
                  '- Todas as categorias possuem produtos.\n'
                  '- Nenhum item foi perdido ou alterado indevidamente.\n'
                  '- A estrutura final é JSON válido (aspas duplas, sem comentários).\n\n'
                  'Saída: retorne APENAS o JSON reorganizado, sem nenhum texto adicional, comentários ou formatação markdown.'
            }
          ]
        }
      ]
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
