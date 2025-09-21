import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/produto_model.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/produto.dart';
import '../../domain/repositories/i_gestao_repository.dart';

/// Implementação do repositório de gestão que utiliza o Hive como banco de dados local.
///
/// Esta classe é responsável por traduzir as chamadas do domínio em operações
/// específicas do Hive, manipulando os `CategoriaModel` e `ProdutoModel`.

class GestaoRepositoryImpl implements IGestaoRepository {
  static const _categoriasBox = 'categorias_box';
  static const _produtosBox = 'produtos_box';

  static const _uuid = Uuid();

  /// Inicializa o Hive, registra os adaptadores dos modelos e abre as caixas.
  @override
  Future<void> init() async {
    Hive.registerAdapter(CategoriaModelAdapter());
    Hive.registerAdapter(ProdutoModelAdapter());

    await Hive.openBox<CategoriaModel>(_categoriasBox);
    await Hive.openBox<ProdutoModel>(_produtosBox);
  }

  @override
  Future<void> resetAndSeedDatabase(List<Map<String, dynamic>> seedData) async {
    final catBox = Hive.box<CategoriaModel>(_categoriasBox);
    final prodBox = Hive.box<ProdutoModel>(_produtosBox);

    await catBox.clear();
    await prodBox.clear();

    int catOrder = 0;
    for (var catData in seedData) {
      final catId = _uuid.v4();
      final newCat =
          CategoriaModel(id: catId, nome: catData['nome'], ordem: catOrder++);
      await catBox.put(catId, newCat);

      if (catData['produtos'] != null) {
        for (var prodData in (catData['produtos'] as List)) {
          final prodId = _uuid.v4();
          final newProd = ProdutoModel(
            id: prodId,
            nome: prodData['nome'],
            preco: (prodData['preco'] as double?) ?? 0.0,
            categoriaId: catId,
          );
          await prodBox.put(prodId, newProd);
        }
      }
    }
  }

  // --- Métodos para Categoria ---
  @override
  Future<void> criarCategoria(String nome) async {
    final box = Hive.box<CategoriaModel>(_categoriasBox);
    final novaOrdem = box.values.length;
    final novoId = _uuid.v4();
    final novaCategoria =
        CategoriaModel(id: novoId, nome: nome, ordem: novaOrdem);
    await box.put(novoId, novaCategoria);
  }

  @override
  List<Categoria> getCategorias() {
    final box = Hive.box<CategoriaModel>(_categoriasBox);
    final categorias = box.values.toList();
    categorias.sort((a, b) => a.ordem.compareTo(b.ordem));
    return categorias;
  }

  @override
  Future<void> atualizarOrdemCategorias(List<Categoria> categorias) async {
    final box = Hive.box<CategoriaModel>(_categoriasBox);
    final Map<String, CategoriaModel> updates = {};
    for (int i = 0; i < categorias.length; i++) {
      final categoria = categorias[i];
      categoria.ordem = i;
      updates[categoria.id] = CategoriaModel.fromEntity(categoria);
    }
    await box.putAll(updates);
  }

  @override
  Future<void> deletarCategoria(String categoriaId) async {
    final boxCategorias = Hive.box<CategoriaModel>(_categoriasBox);
    final boxProdutos = Hive.box<ProdutoModel>(_produtosBox);

    final produtosParaDeletar =
        boxProdutos.values.where((p) => p.categoriaId == categoriaId).toList();

    final chavesDosProdutos = produtosParaDeletar.map((p) => p.id).toList();

    await boxProdutos.deleteAll(chavesDosProdutos);
    await boxCategorias.delete(categoriaId);
  }

  @override
  Future<void> atualizarNomeCategoria(
      String categoriaId, String novoNome) async {
    final box = Hive.box<CategoriaModel>(_categoriasBox);
    final categoria = box.get(categoriaId);
    if (categoria != null) {
      categoria.nome = novoNome;
      await box.put(categoriaId, categoria);
    }
  }

  // --- Métodos para Produto ---

  @override
  Future<void> criarProduto(String nome, String categoriaId) async {
    final box = Hive.box<ProdutoModel>(_produtosBox);
    final novoId = _uuid.v4();

    final novoProduto = ProdutoModel(
      id: novoId,
      nome: nome,
      categoriaId: categoriaId,
    );
    await box.put(novoId, novoProduto);
  }

  @override
  List<Produto> getProdutosPorCategoria(String categoriaId) {
    final box = Hive.box<ProdutoModel>(_produtosBox);
    return box.values
        .where((produto) => produto.categoriaId == categoriaId)
        .toList();
  }

  @override
  List<Produto> getAllProdutos() {
    final box = Hive.box<ProdutoModel>(_produtosBox);
    return box.values.toList();
  }

  @override
  Future<void> atualizarPrecoProduto(String produtoId, double novoPreco) async {
    final box = Hive.box<ProdutoModel>(_produtosBox);
    final produto = box.get(produtoId);

    if (produto != null) {
      produto.preco = novoPreco;
      await box.put(produtoId, produto);
    }
  }

  @override
  Future<void> deletarProduto(String produtoId, String categoriaId) async {
    final box = Hive.box<ProdutoModel>(_produtosBox);
    await box.delete(produtoId);
  }

  @override
  Future<void> adicionarProdutoObjeto(Produto produto) async {
    final box = Hive.box<ProdutoModel>(_produtosBox);
    final produtoModel = ProdutoModel.fromEntity(produto);
    await box.put(produtoModel.id, produtoModel);
  }

  @override
  Future<void> atualizarNomeProduto(String produtoId, String novoNome) async {
    final box = Hive.box<ProdutoModel>(_produtosBox);
    final produto = box.get(produtoId);
    if (produto != null) {
      produto.nome = novoNome;
      await box.put(produtoId, produto);
    }
  }
}
