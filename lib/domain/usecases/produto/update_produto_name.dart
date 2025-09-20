import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para atualizar o nome de um produto.
class UpdateProdutoName {
  final IGestaoRepository repository;

  UpdateProdutoName(this.repository);

  Future<void> call({required String id, required String novoNome}) {
    return repository.atualizarNomeProduto(id, novoNome);
  }
}
