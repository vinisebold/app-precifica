import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:organiza_ae/data/models/categoria.dart';
import 'package:organiza_ae/data/models/produto.dart';
import 'package:organiza_ae/data/repositories/hive_gestao_repository.dart';
import 'package:organiza_ae/gestao_produtos/domain/i_gestao_repository.dart';

class GestaoState {
  final List<Categoria> categorias;
  final List<Produto> produtos;
  final String? categoriaSelecionadaId;
  final String? errorMessage;
  final bool isReordering;

  GestaoState({
    this.categorias = const [],
    this.produtos = const [],
    this.categoriaSelecionadaId,
    this.errorMessage,
    this.isReordering = false,
  });

  GestaoState copyWith({
    List<Categoria>? categorias,
    List<Produto>? produtos,
    String? categoriaSelecionadaId,
    String? errorMessage,
    bool? isReordering,
    bool clearErrorMessage = false,
  }) {
    return GestaoState(
      categorias: categorias ?? this.categorias,
      produtos: produtos ?? this.produtos,
      categoriaSelecionadaId:
          categoriaSelecionadaId ?? this.categoriaSelecionadaId,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      isReordering: isReordering ?? this.isReordering,
    );
  }
}

final gestaoRepositoryProvider = Provider<IGestaoRepository>((ref) {
  return HiveGestaoRepository();
});

class GestaoController extends Notifier<GestaoState> {
  late final IGestaoRepository _repository;

  @override
  GestaoState build() {
    _repository = ref.watch(gestaoRepositoryProvider);
    try {
      final categorias = _repository.getCategorias();
      if (categorias.isNotEmpty) {
        final primeiraCategoriaId = categorias.first.id;
        final produtos =
            _repository.getProdutosPorCategoria(primeiraCategoriaId);
        return GestaoState(
          categorias: categorias,
          produtos: produtos,
          categoriaSelecionadaId: primeiraCategoriaId,
        );
      }
    } catch (e) {
      print("Erro ao inicializar o estado: $e");
      return GestaoState(errorMessage: "Falha ao carregar dados.");
    }
    return GestaoState();
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  void setReordering(bool value) {
    state = state.copyWith(isReordering: value);
  }

  Future<void> reordenarCategoria(
      String draggedItemId, String targetItemId) async {
    final categorias = List<Categoria>.from(state.categorias);

    final draggedIndex =
        categorias.indexWhere((cat) => cat.id == draggedItemId);
    final targetIndex = categorias.indexWhere((cat) => cat.id == targetItemId);

    if (draggedIndex == -1 || targetIndex == -1) return;

    final item = categorias.removeAt(draggedIndex);
    categorias.insert(targetIndex, item);

    try {
      await _repository.atualizarOrdemCategorias(categorias);
      state = state.copyWith(categorias: categorias);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao reordenar categorias.');
    }
  }

  Future<void> criarCategoria(String nome) async {
    try {
      await _repository.criarCategoria(nome);
      state = state.copyWith(categorias: _repository.getCategorias());
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao criar categoria.');
    }
  }

  Future<void> deletarCategoria(String categoriaId) async {
    try {
      await _repository.deletarCategoria(categoriaId);
      final categoriasAtualizadas = _repository.getCategorias();

      if (categoriasAtualizadas.isNotEmpty) {
        final novaCategoriaId = categoriasAtualizadas.first.id;
        final novosProdutos =
            _repository.getProdutosPorCategoria(novaCategoriaId);
        state = state.copyWith(
          categorias: categoriasAtualizadas,
          categoriaSelecionadaId: novaCategoriaId,
          produtos: novosProdutos,
        );
      } else {
        state = GestaoState(
            categorias: [], produtos: [], categoriaSelecionadaId: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao apagar categoria.');
    }
  }

  void selecionarCategoria(String categoriaId) {
    try {
      final produtos = _repository.getProdutosPorCategoria(categoriaId);
      state = state.copyWith(
        categoriaSelecionadaId: categoriaId,
        produtos: produtos,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao carregar produtos.');
    }
  }

  Future<void> criarProduto(String nome) async {
    if (state.categoriaSelecionadaId != null) {
      try {
        await _repository.criarProduto(nome, state.categoriaSelecionadaId!);
        selecionarCategoria(state.categoriaSelecionadaId!);
      } catch (e) {
        state = state.copyWith(errorMessage: 'Falha ao criar produto.');
      }
    }
  }

  Future<void> atualizarPreco(
      String produtoId, String precoStringFormatado) async {
    final stringSemMilhar = precoStringFormatado.replaceAll('.', '');
    final stringParaParse = stringSemMilhar.replaceAll(',', '.');
    final novoPreco = double.tryParse(stringParaParse);

    if (novoPreco != null) {
      try {
        await _repository.atualizarPrecoProduto(produtoId, novoPreco);
      } catch (e) {
        print("ERRO AO ATUALIZAR PREÇO: $e");
      }
    }
  }

  String gerarTextoRelatorio() {
    final hoje = DateTime.now();
    final formatoData = DateFormat('dd/MM/yyyy');
    final dataFormatada = formatoData.format(hoje);
    final todosProdutos = _repository.getAllProdutos();

    if (todosProdutos.isEmpty) {
      return 'Nenhum produto cadastrado para gerar relatório.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Lista de Preços - $dataFormatada');
    buffer.writeln();

    for (var produto in todosProdutos) {
      final precoFormatado =
          produto.preco.toStringAsFixed(2).replaceAll('.', ',');
      buffer.writeln('${produto.nome} – R\$ $precoFormatado');
    }

    return buffer.toString();
  }
}

final gestaoControllerProvider =
    NotifierProvider<GestaoController, GestaoState>(
  () => GestaoController(),
);
