import 'package:hive_flutter/hive_flutter.dart';
import 'package:organiza_ae/data/models/categoria.dart';
import 'package:organiza_ae/data/models/produto.dart';
import 'package:uuid/uuid.dart';

import '../../gestao_produtos/domain/i_gestao_repository.dart';

class HiveGestaoRepository implements IGestaoRepository {
  // Nomes das "caixas" (tabelas) do nosso banco de dados.
  static const _categoriasBox = 'categorias_box';
  static const _produtosBox = 'produtos_box';

  // Instância do gerador de IDs
  final _uuid = Uuid();

  // Métod para inicializar o Hive e registrar os adaptadores
  @override
  Future<void> init() async {
    Hive.registerAdapter(CategoriaAdapter());
    Hive.registerAdapter(ProdutoAdapter());

    await Hive.openBox<Categoria>(_categoriasBox);
    await Hive.openBox<Produto>(_produtosBox);
  }

  // Criar categoria
  @override
  Future<void> criarCategoria(String nome) async {
    final box = Hive.box<Categoria>(_categoriasBox);
    final novaOrdem = box.values.length;
    final novoId = _uuid.v4();
    final novaCategoria = Categoria(id: novoId, nome: nome, ordem: novaOrdem);
    await box.put(novoId, novaCategoria);
  }

  // Listar categorias
  @override
  List<Categoria> getCategorias() {
    final box = Hive.box<Categoria>(_categoriasBox);
    final categorias = box.values.toList();
    categorias.sort((a, b) => a.ordem.compareTo(b.ordem));
    return categorias;
  }

  @override
  Future<void> atualizarOrdemCategorias(List<Categoria> categorias) async {
    final box = Hive.box<Categoria>(_categoriasBox);
    final Map<String, Categoria> updates = {};
    for (int i = 0; i < categorias.length; i++) {
      final categoria = categorias[i];
      categoria.ordem = i;
      updates[categoria.id] = categoria;
    }
    await box.putAll(updates);
  }

  @override
  Future<void> deletarCategoria(String categoriaId) async {
    final boxCategorias = Hive.box<Categoria>(_categoriasBox);
    final boxProdutos = Hive.box<Produto>(_produtosBox);

    final produtosParaDeletar =
        boxProdutos.values.where((p) => p.categoriaId == categoriaId).toList();

    final chavesDosProdutos = produtosParaDeletar.map((p) => p.id).toList();

    await boxProdutos.deleteAll(chavesDosProdutos);
    await boxCategorias.delete(categoriaId);
  }

  @override
  Future<void> atualizarNomeCategoria(
      String categoriaId, String novoNome) async {
    final box = Hive.box<Categoria>(_categoriasBox);
    final categoria = box.get(categoriaId);
    if (categoria != null) {
      categoria.nome = novoNome;
      await box.put(categoriaId, categoria);
    }
  }

  // --- Métodos para Produto ---
  @override
  Future<void> criarProduto(String nome, String categoriaId) async {
    final box = Hive.box<Produto>(_produtosBox);
    final novoId = _uuid.v4();

    final novoProduto = Produto(
      id: novoId,
      nome: nome,
      categoriaId: categoriaId,
    );
    await box.put(novoId, novoProduto);
  }

  @override
  List<Produto> getProdutosPorCategoria(String categoriaId) {
    final box = Hive.box<Produto>(_produtosBox);
    return box.values
        .where((produto) => produto.categoriaId == categoriaId)
        .toList();
  }

  @override
  List<Produto> getAllProdutos() {
    final box = Hive.box<Produto>(_produtosBox);
    return box.values.toList();
  }

  @override
  Future<void> atualizarPrecoProduto(String produtoId, double novoPreco) async {
    final box = Hive.box<Produto>(_produtosBox);
    final produto = box.get(produtoId);

    if (produto != null) {
      produto.preco = novoPreco;
      await box.put(produtoId, produto);
    }
  }

  @override
  Future<void> deletarProduto(String produtoId, String categoriaId) async {
    final box = Hive.box<Produto>(_produtosBox);
    await box.delete(produtoId);
  }

  @override
  Future<void> adicionarProdutoObjeto(Produto produto) async {
    final box = Hive.box<Produto>(_produtosBox);
    await box.put(produto.id, produto); // Add the product back using its ID
  }

  @override
  Future<void> atualizarNomeProduto(String produtoId, String novoNome) async {
    final box = Hive.box<Produto>(_produtosBox);
    final produto = box.get(produtoId);
    if (produto != null) {
      produto.nome = novoNome;
      await box.put(produtoId, produto);
    }
  }
}
