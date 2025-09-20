import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para atualizar o nome de uma categoria.
class UpdateCategoriaName {
  final IGestaoRepository repository;

  UpdateCategoriaName(this.repository);

  Future<void> call({required String id, required String novoNome}) {
    return repository.atualizarNomeCategoria(id, novoNome);
  }
}