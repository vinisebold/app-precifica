import '../../../domain/entities/produto.dart';
import '../../../domain/repositories/i_gestao_repository.dart';

/// Caso de uso para obter os produtos de uma categoria específica.
class GetProdutosByCategoria {
  final IGestaoRepository repository;

  GetProdutosByCategoria(this.repository);

  List<Produto> call(String categoriaId) {
    return repository.getProdutosPorCategoria(categoriaId);
  }
}
