import '../../../domain/entities/categoria.dart';
import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para obter a lista de todas as categorias.
class GetCategorias {
  final IGestaoRepository repository;

  GetCategorias(this.repository);

  List<Categoria> call() {
    return repository.getCategorias();
  }
}