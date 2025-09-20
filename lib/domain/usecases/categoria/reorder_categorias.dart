import '../../../domain/entities/categoria.dart';
import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para reordenar a lista de categorias.
class ReorderCategorias {
  final IGestaoRepository repository;

  ReorderCategorias(this.repository);

  Future<void> call(List<Categoria> categorias) {
    return repository.atualizarOrdemCategorias(categorias);
  }
}