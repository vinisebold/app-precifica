import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para deletar uma categoria.
class DeleteCategoria {
  final IGestaoRepository repository;

  DeleteCategoria(this.repository);

  Future<void> call(String categoriaId) {
    return repository.deletarCategoria(categoriaId);
  }
}
