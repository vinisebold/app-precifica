import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para deletar um produto.
class DeleteProduto {
  final IGestaoRepository repository;

  DeleteProduto(this.repository);

  Future<void> call({required String produtoId, required String categoriaId}) {
    return repository.deletarProduto(produtoId, categoriaId);
  }
}