import 'dart:convert';

import '../../../data/services/ai_service.dart';
import '../../repositories/i_gestao_repository.dart';

/// Caso de uso para organizar as categorias e produtos usando IA.
class OrganizeWithAI {
  final IGestaoRepository repository;
  final AIService aiService;

  OrganizeWithAI(this.repository, this.aiService);

  /// Executa o fluxo completo:
  /// 1. Exporta os dados atuais para JSON.
  /// 2. Envia para o serviço de IA.
  /// 3. Importa o resultado de volta para o banco de dados.
  Future<void> call() async {
    final jsonAtual = await repository.exportCurrentDataToJson();
    final respostaDaIA =
        await aiService.organizarCategorias(jsonAtual: jsonAtual);

    final sanitizedResponse = _sanitizeJsonResponse(respostaDaIA);

    dynamic decoded;
    try {
      decoded = jsonDecode(sanitizedResponse);
    } on FormatException catch (e) {
      throw FormatException(
        'Resposta da IA não é um JSON válido. Erro original: ${e.message}. Conteúdo recebido: $sanitizedResponse',
      );
    }

    final dadosOrganizados = _ensureListOfMaps(decoded);

    await repository.seedDatabase(dadosOrganizados);
  }

  List<Map<String, dynamic>> _ensureListOfMaps(dynamic decoded) {
    if (decoded is List) {
      return decoded.map<Map<String, dynamic>>((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        throw FormatException(
            'Produto no formato inesperado: ${item.runtimeType}.');
      }).toList();
    }

    throw FormatException(
        'Estrutura de resposta inesperada. Esperado array, obtido ${decoded.runtimeType}.');
  }

  String _sanitizeJsonResponse(String response) {
    var result = response.trim();

    if (result.startsWith('```')) {
      final fenceEnd = result.indexOf('\n');
      if (fenceEnd != -1) {
        result = result.substring(fenceEnd + 1);
      } else {
        result = result.replaceFirst('```', '');
      }
    }

    if (result.endsWith('```')) {
      final lastFence = result.lastIndexOf('```');
      result = result.substring(0, lastFence).trimRight();
    }

    final startBracket = result.indexOf('[');
    final startBrace = result.indexOf('{');
    var startIndex = -1;
    if (startBracket != -1 && startBrace != -1) {
      startIndex = startBracket < startBrace ? startBracket : startBrace;
    } else if (startBracket != -1) {
      startIndex = startBracket;
    } else {
      startIndex = startBrace;
    }

    final endBracket = result.lastIndexOf(']');
    final endBrace = result.lastIndexOf('}');
    var endIndex = -1;
    if (endBracket > endIndex) {
      endIndex = endBracket;
    }
    if (endBrace > endIndex) {
      endIndex = endBrace;
    }

    if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
      result = result.substring(startIndex, endIndex + 1);
    }

    return result.trim();
  }
}
