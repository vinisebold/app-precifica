import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para criar um novo produto.
class CreateProduto {
  final IGestaoRepository repository;

  CreateProduto(this.repository);

  Future<void> call({required String nome, required String categoriaId}) {
    return repository.criarProduto(nome, categoriaId);
  }
}