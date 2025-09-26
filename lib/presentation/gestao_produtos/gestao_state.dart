import 'package:precifica/domain/entities/categoria.dart';
import 'package:precifica/domain/entities/produto.dart';
import 'package:precifica/app/core/services/thermal_printer_service.dart';

/// Representa todos os possíveis estados da tela de gestão.
class GestaoState {
  final List<Categoria> categorias;
  final List<Produto> produtos;
  final String? categoriaSelecionadaId;
  final String? errorMessage;
  final bool isReordering;
  final bool isLoading;
  final Produto? ultimoProdutoDeletado;
  final String? idCategoriaProdutoDeletado;
  final bool isDraggingProduto;
  final List<String> perfisSalvos;
  final String? perfilAtual;
  final List<ThermalPrinterDevice> impressorasDisponiveis;
  final ThermalPrinterDevice? impressoraConectada;
  final bool isBuscandoImpressoras;
  final bool isConectandoImpressora;
  final bool isImprimindo;
  final String? mensagemImpressora;

  GestaoState({
    this.categorias = const [],
    this.produtos = const [],
    this.categoriaSelecionadaId,
    this.errorMessage,
    this.isReordering = false,
    this.isLoading = false,
    this.ultimoProdutoDeletado,
    this.idCategoriaProdutoDeletado,
    this.isDraggingProduto = false,
    this.perfisSalvos = const [],
    this.perfilAtual,
    this.impressorasDisponiveis = const [],
    this.impressoraConectada,
    this.isBuscandoImpressoras = false,
    this.isConectandoImpressora = false,
    this.isImprimindo = false,
    this.mensagemImpressora,
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
    bool? isDraggingProduto,
    bool clearErrorMessage = false,
    bool clearUltimoProdutoDeletado = false,
    List<String>? perfisSalvos,
    String? perfilAtual,
    bool clearPerfilAtual = false,
    List<ThermalPrinterDevice>? impressorasDisponiveis,
    ThermalPrinterDevice? impressoraConectada,
    bool? isBuscandoImpressoras,
    bool? isConectandoImpressora,
    bool? isImprimindo,
    String? mensagemImpressora,
    bool clearMensagemImpressora = false,
    bool clearImpressoraConectada = false,
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
      isDraggingProduto: isDraggingProduto ?? this.isDraggingProduto,
      perfisSalvos: perfisSalvos ?? this.perfisSalvos,
      perfilAtual: clearPerfilAtual ? null : perfilAtual ?? this.perfilAtual,
      impressorasDisponiveis:
          impressorasDisponiveis ?? this.impressorasDisponiveis,
      impressoraConectada: clearImpressoraConectada
          ? null
          : impressoraConectada ?? this.impressoraConectada,
      isBuscandoImpressoras:
          isBuscandoImpressoras ?? this.isBuscandoImpressoras,
      isConectandoImpressora:
          isConectandoImpressora ?? this.isConectandoImpressora,
      isImprimindo: isImprimindo ?? this.isImprimindo,
      mensagemImpressora: clearMensagemImpressora
          ? null
          : mensagemImpressora ?? this.mensagemImpressora,
    );
  }
}
