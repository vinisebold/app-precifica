import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para atualizar o preço de um produto.
class UpdateProdutoPrice {
  final IGestaoRepository repository;

  UpdateProdutoPrice(this.repository);

  Future<void> call({required String id, required double novoPreco}) {
    return repository.atualizarPrecoProduto(id, novoPreco);
  }
}