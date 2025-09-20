import '../../../domain/entities/produto.dart';
import '../../../domain/repositories/i_gestao_repository.dart';

class GetAllProdutos {
  final IGestaoRepository repository;

  GetAllProdutos(this.repository);
  List<Produto> call() => repository.getAllProdutos();
}