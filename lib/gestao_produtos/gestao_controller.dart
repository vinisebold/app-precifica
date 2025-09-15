import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:organiza_ae/data/local_storage_service.dart';
import 'package:organiza_ae/data/models/categoria.dart';
import 'package:organiza_ae/data/models/produto.dart';

// PARTE 1: O ESTADO ficou mais completo.
class GestaoState {
  final List<Categoria> categorias;
  final List<Produto>
      produtos; // <- Novo! Lista de produtos da categoria selecionada.
  final String?
      categoriaSelecionadaId; // <- Novo! ID da categoria que está ativa.

  GestaoState({
    this.categorias = const [],
    this.produtos = const [],
    this.categoriaSelecionadaId,
  });

  GestaoState copyWith({
    List<Categoria>? categorias,
    List<Produto>? produtos,
    String? categoriaSelecionadaId,
  }) {
    return GestaoState(
      categorias: categorias ?? this.categorias,
      produtos: produtos ?? this.produtos,
      categoriaSelecionadaId:
          categoriaSelecionadaId ?? this.categoriaSelecionadaId,
    );
  }
}

// PARTE 2: O CONTROLLER ficou mais inteligente.
class GestaoController extends Notifier<GestaoState> {
  final LocalStorageService _storageService = LocalStorageService();

  @override
  GestaoState build() {
    // A inicialização agora é mais robusta.
    final categorias = _storageService.getCategorias();
    if (categorias.isNotEmpty) {
      // Se existem categorias, seleciona a primeira por padrão...
      final primeiraCategoriaId = categorias.first.id;
      // ...e já busca os produtos dela.
      final produtos =
          _storageService.getProdutosPorCategoria(primeiraCategoriaId);
      return GestaoState(
        categorias: categorias,
        produtos: produtos,
        categoriaSelecionadaId: primeiraCategoriaId,
      );
    }
    // Se não há categorias, retorna o estado vazio.
    return GestaoState();
  }

  // --- Funções de Categoria ---

  Future<void> criarCategoria(String nome) async {
    await _storageService.criarCategoria(nome);
    // Após criar, atualiza a lista de categorias no estado.
    state = state.copyWith(categorias: _storageService.getCategorias());
  }

  // Substitua a versão anterior desta função no GestaoController
  Future<void> deletarCategoria(String categoriaId) async {
    await _storageService.deletarCategoria(categoriaId);

    // Rebusca a lista de categorias que sobraram.
    final categoriasAtualizadas = _storageService.getCategorias();

    if (categoriasAtualizadas.isNotEmpty) {
      // Se ainda existem categorias, seleciona a primeira da nova lista...
      final novaCategoriaId = categoriasAtualizadas.first.id;
      final novosProdutos = _storageService.getProdutosPorCategoria(novaCategoriaId);

      // ...e atualiza o estado com TODAS as informações novas de uma vez.
      state = state.copyWith(
        categorias: categoriasAtualizadas, // <- A correção principal está aqui!
        categoriaSelecionadaId: novaCategoriaId,
        produtos: novosProdutos,
      );
    } else {
      // Se não sobrou nenhuma, limpa completamente o estado.
      state = GestaoState(categorias: [], produtos: [], categoriaSelecionadaId: null);
    }
  }

  // --- Novas Funções de Produto ---

  void selecionarCategoria(String categoriaId) {
    // Quando o usuário selecionar uma nova categoria...
    // 1. Busca os produtos dessa nova categoria.
    final produtos = _storageService.getProdutosPorCategoria(categoriaId);
    // 2. Atualiza o estado com o novo ID selecionado e a nova lista de produtos.
    state = state.copyWith(
      categoriaSelecionadaId: categoriaId,
      produtos: produtos,
    );
  }

  Future<void> criarProduto(String nome) async {
    // Só podemos criar um produto se uma categoria estiver selecionada.
    if (state.categoriaSelecionadaId != null) {
      await _storageService.criarProduto(nome, state.categoriaSelecionadaId!);
      // Após criar, atualiza a lista de produtos da categoria atual.
      selecionarCategoria(state.categoriaSelecionadaId!);
    }
  }

  Future<void> atualizarPreco(String produtoId, String precoStringFormatado) async {
    // 1. Remove os separadores de milhar (ponto). Ex: "1.234,56" -> "1234,56"
    final stringSemMilhar = precoStringFormatado.replaceAll('.', '');
    // 2. Substitui a vírgula decimal por um ponto decimal. Ex: "1234,56" -> "1234.56"
    final stringParaParse = stringSemMilhar.replaceAll(',', '.');

    // 3. Tenta converter para double.
    final novoPreco = double.tryParse(stringParaParse);

    if (novoPreco != null) {
      // 4. Envia o número puro (double) para o serviço de armazenamento.
      await _storageService.atualizarPrecoProduto(produtoId, novoPreco);
    }
  }
  String gerarTextoRelatorio() {
    // 1. Pega a data e hora de agora.
    final hoje = DateTime.now();
    // 2. Define o formato que queremos (dia/mês/ano).
    final formatoData = DateFormat('dd/MM/yyyy');
    // 3. Formata a data.
    final dataFormatada = formatoData.format(hoje);

    final todosProdutos = _storageService.getAllProdutos();

    if (todosProdutos.isEmpty) {
      return 'Nenhum produto cadastrado para gerar relatório.';
    }

    final buffer = StringBuffer();
    // 4. Monta o título com a data formatada.
    buffer.writeln('Lista de Preços - $dataFormatada');
    buffer.writeln(); // Adiciona uma linha em branco para espaçamento

    // 5. Itera por TODOS os produtos, sem separar por categoria.
    for (var produto in todosProdutos) {
      final precoFormatado = produto.preco.toStringAsFixed(2).replaceAll('.', ',');
      buffer.writeln('${produto.nome} – R\$ $precoFormatado');
    }

    return buffer.toString();
  }
}

// PARTE 3: O PROVIDER continua o mesmo.
final gestaoControllerProvider =
    NotifierProvider<GestaoController, GestaoState>(
  () => GestaoController(),
);
