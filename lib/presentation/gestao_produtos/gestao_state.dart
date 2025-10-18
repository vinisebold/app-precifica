import 'package:precifica/domain/entities/categoria.dart';
import 'package:precifica/domain/entities/produto.dart';

/// Representa todos os possíveis estados da tela de gestão.
class GestaoState {
  final List<Categoria> categorias;
  final List<Produto> produtos;
  final Map<String, List<Produto>> produtosPorCategoria;
  final String? categoriaSelecionadaId;
  final String? errorMessage;
  final bool isReordering;
  final bool isLoading;
  final Produto? ultimoProdutoDeletado;
  final String? idCategoriaProdutoDeletado;
  final bool isDraggingProduto;
  final List<String> perfisSalvos;
  final String? perfilAtual;

  GestaoState({
    this.categorias = const [],
    this.produtos = const [],
    this.produtosPorCategoria = const {},
    this.categoriaSelecionadaId,
    this.errorMessage,
    this.isReordering = false,
    this.isLoading = false,
    this.ultimoProdutoDeletado,
    this.idCategoriaProdutoDeletado,
    this.isDraggingProduto = false,
    this.perfisSalvos = const [],
    this.perfilAtual,
  });

  GestaoState copyWith({
    List<Categoria>? categorias,
    List<Produto>? produtos,
    Map<String, List<Produto>>? produtosPorCategoria,
    String? categoriaSelecionadaId,
    String? errorMessage,
    bool? isReordering,
    bool? isLoading,
    Produto? ultimoProdutoDeletado,
    String? idCategoriaProdutoDeletado,
    bool? isDraggingProduto,
    bool clearErrorMessage = false,
    bool clearUltimoProdutoDeletado = false,
    List<String>? perfisSalvos,
    String? perfilAtual,
    bool clearPerfilAtual = false,
  }) {
    return GestaoState(
      categorias: categorias ?? this.categorias,
      produtos: produtos ?? this.produtos,
    produtosPorCategoria:
      produtosPorCategoria ?? this.produtosPorCategoria,
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
      isDraggingProduto: isDraggingProduto ?? this.isDraggingProduto,
      perfisSalvos: perfisSalvos ?? this.perfisSalvos,
      perfilAtual: clearPerfilAtual ? null : perfilAtual ?? this.perfilAtual,
    );
  }
}
