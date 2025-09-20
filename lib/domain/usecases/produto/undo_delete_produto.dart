import '../../../domain/entities/produto.dart';
import '../../../domain/repositories/i_gestao_repository.dart';

class UndoDeleteProduto {
  final IGestaoRepository repository;

  UndoDeleteProduto(this.repository);
  Future<void> call(Produto produto) => repository.adicionarProdutoObjeto(produto);
}