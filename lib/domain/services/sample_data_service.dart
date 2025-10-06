import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/produto.dart';

class SampleDataService {
  static List<Categoria>? _cachedCategorias;
  static List<Produto>? _cachedProdutos;

  static Future<void> loadSampleData() async {
    if (_cachedCategorias != null && _cachedProdutos != null) {
      return;
    }

    final jsonString = await rootBundle.loadString('assets/profiles/Hortifruti.json');
    final List<dynamic> data = jsonDecode(jsonString);

    final categorias = <Categoria>[];
    final produtos = <Produto>[];

    for (int i = 0; i < data.length; i++) {
      final catData = data[i];
      final catId = 'sample_cat_$i';
      
      categorias.add(
        Categoria(
          id: catId,
          nome: catData['nome'],
          ordem: i,
        ),
      );

      final produtosList = catData['produtos'] as List? ?? [];
      for (int j = 0; j < produtosList.length; j++) {
        final prodData = produtosList[j];
        final precoAleatorio = (5.0 + (j % 20) * 2.5); // Preços variados para exemplo
        
        produtos.add(
          Produto(
            id: 'sample_prod_${i}_$j',
            nome: prodData['nome'],
            preco: precoAleatorio,
            categoriaId: catId,
            isAtivo: true,
          ),
        );
      }
    }

    _cachedCategorias = categorias;
    _cachedProdutos = produtos;
  }

  static List<Categoria> getCategorias() {
    return _cachedCategorias ?? [];
  }

  static List<Produto> getProdutos() {
    return _cachedProdutos ?? [];
  }

  static List<Categoria> getCategoriasSample({int limit = 2}) {
    final categorias = getCategorias();
    return categorias.take(limit).toList();
  }

  static List<Produto> getProdutosSample({int categoriaLimit = 2, int produtoLimit = 3}) {
    final categorias = getCategoriasSample(limit: categoriaLimit);
    final produtos = getProdutos();
    
    return categorias
        .expand((cat) => produtos
            .where((p) => p.categoriaId == cat.id)
            .take(produtoLimit))
        .toList();
  }
}
