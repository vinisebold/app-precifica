import 'package:organiza_ae/data/models/categoria.dart';
import 'package:organiza_ae/data/models/produto.dart';

/// Define o contrato (as regras) para o repositório de dados da gestão.
///
/// Qualquer classe que gerencie os dados de categorias e produtos
/// DEVE implementar todos os métodos definidos aqui.
abstract class IGestaoRepository {
  Future<void> init();

  // --- Métodos para Categoria ---
  Future<void> criarCategoria(String nome);
  List<Categoria> getCategorias();
  Future<void> deletarCategoria(String categoriaId);

  // --- Métodos para Produto ---
  Future<void> criarProduto(String nome, String categoriaId);
  List<Produto> getProdutosPorCategoria(String categoriaId);
  List<Produto> getAllProdutos();
  Future<void> atualizarPrecoProduto(String produtoId, double novoPreco);
}