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
  final bool isLoading;
  final Produto? ultimoProdutoDeletado;
  final String? idCategoriaProdutoDeletado;

  GestaoState({
    this.categorias = const [],
    this.produtos = const [],
    this.categoriaSelecionadaId,
    this.errorMessage,
    this.isReordering = false,
    this.isLoading = false,
    this.ultimoProdutoDeletado,
    this.idCategoriaProdutoDeletado,
  });

  GestaoState copyWith({
    List<Categoria>? categorias,
    List<Produto>? produtos,
    String? categoriaSelecionadaId,
    String? errorMessage,
    bool? isReordering,
    bool? isLoading,
    Produto? ultimoProdutoDeletado,
    String? idCategoriaProdutoDeletado,
    bool clearErrorMessage = false,
    bool clearUltimoProdutoDeletado = false,
  }) {
    return GestaoState(
      categorias: categorias ?? this.categorias,
      produtos: produtos ?? this.produtos,
      categoriaSelecionadaId:
          categoriaSelecionadaId ?? this.categoriaSelecionadaId,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      isReordering: isReordering ?? this.isReordering,
      isLoading: isLoading ?? this.isLoading,
      ultimoProdutoDeletado: clearUltimoProdutoDeletado
          ? null
          : ultimoProdutoDeletado ?? this.ultimoProdutoDeletado,
      idCategoriaProdutoDeletado: clearUltimoProdutoDeletado
          ? null
          : idCategoriaProdutoDeletado ?? this.idCategoriaProdutoDeletado,
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
      state = state.copyWith(isLoading: true);
      await _repository.atualizarOrdemCategorias(categorias);
      state = state.copyWith(categorias: categorias, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Falha ao reordenar categorias.', isLoading: false);
    }
  }

  Future<void> criarCategoria(String nome) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.criarCategoria(nome);
      state = state.copyWith(
          categorias: _repository.getCategorias(), isLoading: false);
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Falha ao criar categoria.', isLoading: false);
    }
  }

  Future<void> deletarCategoria(String categoriaId) async {
    try {
      state = state.copyWith(isLoading: true);
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
          isLoading: false,
        );
      } else {
        state = GestaoState(
            categorias: [],
            produtos: [],
            categoriaSelecionadaId: null,
            isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Falha ao apagar categoria.', isLoading: false);
    }
  }

  void selecionarCategoria(String categoriaId) {
    try {
      final produtos = _repository.getProdutosPorCategoria(categoriaId);
      state = state.copyWith(
        categoriaSelecionadaId: categoriaId,
        produtos: produtos,
        clearUltimoProdutoDeletado: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao carregar produtos.');
    }
  }

  Future<void> criarProduto(String nome) async {
    if (state.categoriaSelecionadaId != null) {
      try {
        state = state.copyWith(isLoading: true);
        await _repository.criarProduto(nome, state.categoriaSelecionadaId!);
        selecionarCategoria(state.categoriaSelecionadaId!);
        state = state.copyWith(isLoading: false);
      } catch (e) {
        state = state.copyWith(
            errorMessage: 'Falha ao criar produto.', isLoading: false);
      }
    }
  }

  Future<void> deletarProduto(String produtoId) async {
    if (state.categoriaSelecionadaId == null) {
      state = state.copyWith(errorMessage: 'Nenhuma categoria selecionada.');
      return;
    }

    final Produto produtoParaDeletar;
    try {
      produtoParaDeletar = state.produtos.firstWhere((p) => p.id == produtoId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Produto não encontrado.');
      return;
    }

    final categoriaDoProdutoDeletado = state.categoriaSelecionadaId!;

    // Remove o produto da lista na UI imediatamente
    final produtosAtuais = List<Produto>.from(state.produtos);
    produtosAtuais.removeWhere((p) => p.id == produtoId);

    state = state.copyWith(
      produtos: produtosAtuais,
      ultimoProdutoDeletado: produtoParaDeletar,
      idCategoriaProdutoDeletado: categoriaDoProdutoDeletado,
    );

    try {
      // Deleta do banco de dados em segundo plano
      await _repository.deletarProduto(produtoId, categoriaDoProdutoDeletado);
    } catch (e) {
      // Se a exclusão falhar, restaura a lista e mostra o erro
      final produtosRecarregados =
          _repository.getProdutosPorCategoria(categoriaDoProdutoDeletado);
      state = state.copyWith(
        produtos: produtosRecarregados,
        errorMessage: 'Falha ao deletar produto.',
        clearUltimoProdutoDeletado: true,
      );
    }
  }

  Future<void> desfazerDeletarProduto() async {
    if (state.ultimoProdutoDeletado != null &&
        state.idCategoriaProdutoDeletado != null) {
      final produtoParaRestaurar = state.ultimoProdutoDeletado!;
      final categoriaOriginalId = state.idCategoriaProdutoDeletado!;

      try {
        state = state.copyWith(isLoading: true);
        await _repository.adicionarProdutoObjeto(produtoParaRestaurar);

        if (state.categoriaSelecionadaId == categoriaOriginalId) {
          final produtosRecarregados =
              _repository.getProdutosPorCategoria(categoriaOriginalId);
          state = state.copyWith(
            produtos: produtosRecarregados,
            clearUltimoProdutoDeletado: true,
            isLoading: false,
          );
        } else {
          state = state.copyWith(
              clearUltimoProdutoDeletado: true, isLoading: false);
        }
      } catch (e) {
        state = state.copyWith(
          errorMessage: 'Falha ao desfazer a exclusão.',
          clearUltimoProdutoDeletado: true,
          isLoading: false,
        );
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
        // Opcional: Adicionar feedback de erro
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
