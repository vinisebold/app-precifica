import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/produto_model.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/produto.dart';
import '../../domain/repositories/i_gestao_repository.dart';

class GestaoRepositoryImpl implements IGestaoRepository {
  static const _categoriasBox = 'categorias_box';
  static const _produtosBox = 'produtos_box';
  static const _uuid = Uuid();

  Future<Directory> _getProfilesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final profilesDir = Directory(p.join(appDir.path, 'profiles'));
    if (!await profilesDir.exists()) {
      await profilesDir.create(recursive: true);
    }
    return profilesDir;
  }

  Future<void> _seedInitialProfilesFromAssets() async {
    final dir = await _getProfilesDirectory();
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    // Filtra para encontrar todos os ficheiros dentro de 'assets/profiles/'
    final profileAssets = assetManifest
        .listAssets()
        .where((string) => string.startsWith('assets/profiles/'))
        .toList();

    for (String assetPath in profileAssets) {
      String fileName = p.basename(assetPath);
      final profileFile = File(p.join(dir.path, fileName));

      if (!await profileFile.exists()) {
        final jsonString = await rootBundle.loadString(assetPath);
        await profileFile.writeAsString(jsonString);
      }
    }
  }

  @override
  Future<void> init() async {
    Hive.registerAdapter(CategoriaModelAdapter());
    Hive.registerAdapter(ProdutoModelAdapter());

    await Hive.openBox<CategoriaModel>(_categoriasBox);
    await Hive.openBox<ProdutoModel>(_produtosBox);

    await _seedInitialProfilesFromAssets();
  }

  @override
  Future<void> seedDatabase(List<Map<String, dynamic>> seedData) async {
    final catBox = Hive.box<CategoriaModel>(_categoriasBox);
    final prodBox = Hive.box<ProdutoModel>(_produtosBox);

    await catBox.clear();
    await prodBox.clear();

    int catOrder = 0;
    for (var catData in seedData) {
      final catId = _uuid.v4();
      final List<String> produtoIds = [];

      if (catData['produtos'] != null) {
        for (var prodData in (catData['produtos'] as List)) {
          final prodId = _uuid.v4();
          produtoIds.add(prodId);

          final newProd = ProdutoModel(
            id: prodId,
            nome: prodData['nome'],
            preco: (prodData['preco'] as num?)?.toDouble() ?? 0.0,
            categoriaId: catId,
            isAtivo: (prodData['isAtivo'] as bool?) ?? true,
          );
          await prodBox.put(prodId, newProd);
        }
      }

      final newCat = CategoriaModel(
        id: catId,
        nome: catData['nome'],
        ordem: catOrder++,
        produtoIds: produtoIds,
      );
      await catBox.put(catId, newCat);
    }
  }

  @override
  Future<void> resetStorage() async {
    final categoriasBox = Hive.box<CategoriaModel>(_categoriasBox);
    final produtosBox = Hive.box<ProdutoModel>(_produtosBox);

    await categoriasBox.clear();
    await produtosBox.clear();

    final profilesDir = await _getProfilesDirectory();
    if (await profilesDir.exists()) {
      final entities = profilesDir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          await entity.delete();
        }
      }
    }

    await _seedInitialProfilesFromAssets();
  }

  @override
  Future<String> exportCurrentDataToJson() async {
    final catBox = Hive.box<CategoriaModel>(_categoriasBox);
    final prodBox = Hive.box<ProdutoModel>(_produtosBox);
    final List<Map<String, dynamic>> data = [];

    final categorias = catBox.values.toList();
    categorias.sort((a, b) => a.ordem.compareTo(b.ordem));

    for (final categoria in categorias) {
      final List<Map<String, dynamic>> produtosData = [];
      for (final produtoId in categoria.produtoIds) {
        final produto = prodBox.get(produtoId);
        if (produto != null) {
          produtosData.add({
            'nome': produto.nome,
            'preco': produto.preco,
            'isAtivo': produto.isAtivo,
          });
        }
      }
      data.add({
        'nome': categoria.nome,
        'produtos': produtosData,
      });
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  @override
  Future<List<String>> getProfileList() async {
    final dir = await _getProfilesDirectory();
    final files = await dir.list().toList();
    return files
        .where((file) => file.path.endsWith('.json'))
        .map((file) => p.basenameWithoutExtension(file.path))
        .toList()
      ..sort();
  }

  @override
  Future<void> saveCurrentDataAsProfile(String profileName) async {
    final dir = await _getProfilesDirectory();
    final file = File(p.join(dir.path, '$profileName.json'));
    final jsonString = await exportCurrentDataToJson();
    await file.writeAsString(jsonString);
  }

  @override
  Future<String> getProfileContent(String profileName) async {
    final dir = await _getProfilesDirectory();
    final file = File(p.join(dir.path, '$profileName.json'));
    if (await file.exists()) {
      return file.readAsString();
    }
    throw Exception('Perfil não encontrado');
  }

  @override
  Future<void> deleteProfile(String profileName) async {
    final dir = await _getProfilesDirectory();
    final file = File(p.join(dir.path, '$profileName.json'));
    if (await file.exists()) {
      await file.delete();
    }
  }

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
      final model = box.get(categoria.id);
      if (model != null) {
        model.ordem = i;
        updates[model.id] = model;
      }
    }
    await box.putAll(updates);
  }

  @override
  Future<void> deletarCategoria(String categoriaId) async {
    final categoriasBox = Hive.box<CategoriaModel>(_categoriasBox);
    final produtosBox = Hive.box<ProdutoModel>(_produtosBox);
    final categoria = categoriasBox.get(categoriaId);

    if (categoria == null) return;

    await produtosBox.deleteAll(categoria.produtoIds);
    await categoriasBox.delete(categoriaId);
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

  @override
  Future<void> criarProduto(String nome, String categoriaId) async {
    final produtosBox = Hive.box<ProdutoModel>(_produtosBox);
    final categoriasBox = Hive.box<CategoriaModel>(_categoriasBox);
    final novoId = _uuid.v4();

    final novoProduto =
        ProdutoModel(id: novoId, nome: nome, categoriaId: categoriaId);
    await produtosBox.put(novoId, novoProduto);

    final categoria = categoriasBox.get(categoriaId);
    if (categoria != null) {
      categoria.produtoIds.add(novoId);
      await categoriasBox.put(categoriaId, categoria);
    }
  }

  @override
  List<Produto> getProdutosPorCategoria(String categoriaId) {
    final produtosBox = Hive.box<ProdutoModel>(_produtosBox);
    final categoriasBox = Hive.box<CategoriaModel>(_categoriasBox);
    final categoria = categoriasBox.get(categoriaId);

    if (categoria == null) return [];

    final produtos = categoria.produtoIds
        .map((id) => produtosBox.get(id))
        .where((produto) => produto != null)
        .cast<Produto>()
        .toList();

    // Ordenar alfabeticamente por nome (case-insensitive)
    produtos
        .sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    return produtos;
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
    final produtosBox = Hive.box<ProdutoModel>(_produtosBox);
    final categoriasBox = Hive.box<CategoriaModel>(_categoriasBox);
    await produtosBox.delete(produtoId);

    final categoria = categoriasBox.get(categoriaId);
    if (categoria != null) {
      categoria.produtoIds.remove(produtoId);
      await categoriasBox.put(categoriaId, categoria);
    }
  }

  @override
  Future<void> adicionarProdutoObjeto(Produto produto) async {
    final produtosBox = Hive.box<ProdutoModel>(_produtosBox);
    final categoriasBox = Hive.box<CategoriaModel>(_categoriasBox);
    final produtoModel = ProdutoModel.fromEntity(produto);

    await produtosBox.put(produtoModel.id, produtoModel);

    final categoria = categoriasBox.get(produto.categoriaId);
    if (categoria != null && !categoria.produtoIds.contains(produto.id)) {
      categoria.produtoIds.add(produto.id);

      // Ordenar produtos alfabeticamente
      _ordenarProdutosPorNome(categoria.produtoIds, produtosBox);

      await categoriasBox.put(produto.categoriaId, categoria);
    }
  }

  @override
  Future<void> atualizarNomeProduto(String produtoId, String novoNome) async {
    final produtosBox = Hive.box<ProdutoModel>(_produtosBox);
    final categoriasBox = Hive.box<CategoriaModel>(_categoriasBox);
    final produto = produtosBox.get(produtoId);

    if (produto != null) {
      produto.nome = novoNome;
      await produtosBox.put(produtoId, produto);

      // Reordenar produtos na categoria após alterar o nome
      final categoria = categoriasBox.get(produto.categoriaId);
      if (categoria != null) {
        _ordenarProdutosPorNome(categoria.produtoIds, produtosBox);
        await categoriasBox.put(produto.categoriaId, categoria);
      }
    }
  }

  @override
  Future<void> atualizarStatusProduto(String produtoId, bool isAtivo) async {
    final box = Hive.box<ProdutoModel>(_produtosBox);
    final produto = box.get(produtoId);
    if (produto != null) {
      produto.isAtivo = isAtivo;
      await box.put(produtoId, produto);
    }
  }

  /// Ordena uma lista de IDs de produtos alfabeticamente baseado nos nomes
  void _ordenarProdutosPorNome(
      List<String> produtoIds, Box<ProdutoModel> produtosBox) {
    produtoIds.sort((idA, idB) {
      final produtoA = produtosBox.get(idA);
      final produtoB = produtosBox.get(idB);

      if (produtoA == null || produtoB == null) return 0;

      return produtoA.nome.toLowerCase().compareTo(produtoB.nome.toLowerCase());
    });
  }
}
