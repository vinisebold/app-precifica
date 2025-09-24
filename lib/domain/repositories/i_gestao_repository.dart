import '../entities/categoria.dart';
import '../entities/produto.dart';

abstract class IGestaoRepository {
  Future<void> init();

  /// Popula o banco de dados com um conjunto de dados, substituindo os existentes.
  Future<void> seedDatabase(List<Map<String, dynamic>> seedData);

  /// Exporta os dados atualmente no banco de dados (perfil ativo) para uma string JSON.
  Future<String> exportCurrentDataToJson();

  // --- Gerenciamento de Perfis ---
  Future<List<String>> getProfileList();
  Future<void> saveCurrentDataAsProfile(String profileName);
  Future<String> getProfileContent(String profileName);
  Future<void> deleteProfile(String profileName);

  // --- Métodos para Categoria ---
  Future<void> criarCategoria(String nome);

  List<Categoria> getCategorias();

  Future<void> deletarCategoria(String categoriaId);

  Future<void> atualizarOrdemCategorias(List<Categoria> categorias);

  Future<void> atualizarNomeCategoria(String categoriaId, String novoNome);

  // --- Métodos para Produto ---
  Future<void> criarProduto(String nome, String categoriaId);
  List<Produto> getProdutosPorCategoria(String categoriaId);
  List<Produto> getAllProdutos();
  Future<void> atualizarPrecoProduto(String produtoId, double novoPreco);
  Future<void> deletarProduto(String produtoId, String categoriaId);
  Future<void> adicionarProdutoObjeto(Produto produto);
  Future<void> atualizarNomeProduto(String produtoId, String novoNome);
  Future<void> atualizarStatusProduto(String produtoId, bool isAtivo);
}
