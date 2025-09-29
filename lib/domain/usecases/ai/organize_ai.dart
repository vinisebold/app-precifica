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
  Future<void> call() async { // Remova o parâmetro apiKey
    final jsonAtual = await repository.exportCurrentDataToJson();
    final jsonOrganizado =
    await aiService.organizarCategorias(jsonAtual: jsonAtual); // Chame sem a chave

    final List<Map<String, dynamic>> dadosOrganizados =
    List.from(jsonDecode(jsonOrganizado));
    await repository.seedDatabase(dadosOrganizados);
  }
}