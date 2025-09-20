import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para criar uma nova categoria.
class CreateCategoria {
  final IGestaoRepository repository;

  CreateCategoria(this.repository);

  Future<void> call(String nome) {
    return repository.criarCategoria(nome);
  }
}