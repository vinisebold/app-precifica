// Importa as entidades puras da camada de domínio
import '../entities/categoria.dart';
import '../entities/produto.dart';

/// Define o contrato (as regras) para o repositório de dados da gestão.
///
/// Qualquer classe que implemente esta interface DEVE fornecer uma implementação
/// para todos os métodos aqui definidos. Isso desacopla a lógica de negócio
/// dos detalhes de implementação da fonte de dados.
abstract class IGestaoRepository {
  Future<void> init();

  // --- Métodos para Categoria ---
  /// Cria uma nova categoria.
  Future<void> criarCategoria(String nome);

  /// Retorna uma lista com todas as categorias, ordenadas.
  List<Categoria> getCategorias();

  /// Deleta uma categoria e todos os produtos associados a ela.
  Future<void> deletarCategoria(String categoriaId);

  /// Atualiza a ordem de uma lista de categorias.
  Future<void> atualizarOrdemCategorias(List<Categoria> categorias);

  /// Atualiza o nome de uma categoria existente.
  Future<void> atualizarNomeCategoria(String categoriaId, String novoNome);

  // --- Métodos para Produto ---
  /// Cria um novo produto associado a uma categoria.
  Future<void> criarProduto(String nome, String categoriaId);

  /// Retorna uma lista de produtos que pertencem a uma categoria específica.
  List<Produto> getProdutosPorCategoria(String categoriaId);

  /// Retorna uma lista com todos os produtos de todas as categorias.
  List<Produto> getAllProdutos();

  /// Atualiza o preço de um produto existente.
  Future<void> atualizarPrecoProduto(String produtoId, double novoPreco);

  /// Deleta um produto.
  Future<void> deletarProduto(String produtoId, String categoriaId);

  /// Adiciona um objeto Produto de volta ao banco de dados (usado para "desfazer").
  Future<void> adicionarProdutoObjeto(Produto produto);

  /// Atualiza o nome de um produto existente.
  Future<void> atualizarNomeProduto(String produtoId, String novoNome);
}
