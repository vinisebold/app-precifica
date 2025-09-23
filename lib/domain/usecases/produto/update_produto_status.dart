import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para atualizar o status de um produto.
class UpdateProdutoStatus {
  final IGestaoRepository repository;

  UpdateProdutoStatus(this.repository);

  Future<void> call({required String id, required bool isAtivo}) {
    return repository.atualizarStatusProduto(id, isAtivo);
  }
}
