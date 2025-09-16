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
  final Produto? ultimoProdutoDeletado; // For UNDO
  final String? idCategoriaProdutoDeletado; // For UNDO

  GestaoState({
    this.categorias = const [],
    List<Produto> produtosParam = const [], 
    this.categoriaSelecionadaId,
    this.errorMessage,
    this.isReordering = false,
    this.ultimoProdutoDeletado,
    this.idCategoriaProdutoDeletado,
  }) : this.produtos = produtosParam;

  GestaoState copyWith({
    List<Categoria>? categorias,
    List<Produto>? produtos,
    String? categoriaSelecionadaId,
    String? errorMessage,
    bool? isReordering,
    Produto? ultimoProdutoDeletado,
    String? idCategoriaProdutoDeletado,
    bool clearErrorMessage = false,
    bool clearUltimoProdutoDeletado = false,
    bool clearIdCategoriaProdutoDeletado = false,
  }) {
    return GestaoState(
      categorias: categorias ?? this.categorias,
      produtosParam: produtos ?? this.produtos, 
      categoriaSelecionadaId:
          categoriaSelecionadaId ?? this.categoriaSelecionadaId,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      isReordering: isReordering ?? this.isReordering,
      ultimoProdutoDeletado: clearUltimoProdutoDeletado
          ? null
          : ultimoProdutoDeletado ?? this.ultimoProdutoDeletado,
      idCategoriaProdutoDeletado: clearIdCategoriaProdutoDeletado
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
          produtosParam: produtos, 
          categoriaSelecionadaId: primeiraCategoriaId,
        );
      }
    } catch (e) {
      // Consider logging to a crash reporting service in production
      return GestaoState(errorMessage: "Falha ao carregar dados.");
    }
    return GestaoState(); 
  }

  void clearError() {
    state = state.copyWith(
      produtos: state.produtos, 
      clearErrorMessage: true
    );
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
            categorias: [], produtosParam: [], categoriaSelecionadaId: null); 
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
        clearUltimoProdutoDeletado: true,
        clearIdCategoriaProdutoDeletado: true,
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

  Future<void> deletarProduto(String produtoId) async {
    if (state.categoriaSelecionadaId == null) {
      state = state.copyWith(errorMessage: 'Nenhuma categoria selecionada para deletar o produto.');
      return;
    }

    final Produto produtoParaDeletar;
    try {
      produtoParaDeletar = state.produtos.firstWhere((p) => p.id == produtoId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Produto não encontrado para deletar.');
      return;
    }
    
    final categoriaDoProdutoDeletado = state.categoriaSelecionadaId!;

    try {
      await _repository.deletarProduto(produtoId, categoriaDoProdutoDeletado);
      final produtosAtualizados = _repository.getProdutosPorCategoria(categoriaDoProdutoDeletado);
      state = state.copyWith(
        produtos: produtosAtualizados,
        ultimoProdutoDeletado: produtoParaDeletar,
        idCategoriaProdutoDeletado: categoriaDoProdutoDeletado,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao deletar produto.');
    }
  }

  Future<void> desfazerDeletarProduto() async {
    if (state.ultimoProdutoDeletado != null && state.idCategoriaProdutoDeletado != null) {
      final Produto produtoParaRestaurar = state.ultimoProdutoDeletado!;
      final String categoriaOriginalDoProduto = state.idCategoriaProdutoDeletado!;
      
      try {
        await _repository.adicionarProdutoObjeto(produtoParaRestaurar);
        
        if (state.categoriaSelecionadaId == categoriaOriginalDoProduto) {
          List<Produto> produtosRecarregados = _repository.getProdutosPorCategoria(categoriaOriginalDoProduto);
          
          state = GestaoState(
            categorias: state.categorias, 
            produtosParam: produtosRecarregados, 
            categoriaSelecionadaId: categoriaOriginalDoProduto,
            ultimoProdutoDeletado: null, 
            idCategoriaProdutoDeletado: null, 
            errorMessage: null, 
            isReordering: state.isReordering 
          );
        } else {
          state = state.copyWith(
            clearUltimoProdutoDeletado: true,
            clearIdCategoriaProdutoDeletado: true,
          );
        }

      } catch (e) {
        state = state.copyWith(
          errorMessage: 'Falha ao desfazer a exclusão do produto.',
          clearUltimoProdutoDeletado: true,
          clearIdCategoriaProdutoDeletado: true,
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
        // Considerar um feedback de erro para o usuário
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
