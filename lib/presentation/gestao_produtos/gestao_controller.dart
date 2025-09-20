import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Dependências das outras camadas
import '../../data/repositories/gestao_repository_impl.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/produto.dart';
import '../../domain/repositories/i_gestao_repository.dart';

// Importando todos os UseCases
import '../../domain/usecases/categoria/create_categoria.dart';
import '../../domain/usecases/categoria/delete_categoria.dart';
import '../../domain/usecases/categoria/get_categorias.dart';
import '../../domain/usecases/categoria/reorder_categorias.dart';
import '../../domain/usecases/categoria/update_categoria_name.dart';
import '../../domain/usecases/produto/create_produto.dart';
import '../../domain/usecases/produto/delete_produto.dart';
import '../../domain/usecases/produto/get_all_produtos.dart';
import '../../domain/usecases/produto/get_produtos_by_categoria.dart';
import '../../domain/usecases/produto/undo_delete_produto.dart';
import '../../domain/usecases/produto/update_produto_name.dart';
import '../../domain/usecases/produto/update_produto_price.dart';

// Importando o State
import 'gestao_state.dart';

// --- Provedores ---

final gestaoRepositoryProvider = Provider<IGestaoRepository>((ref) {
  return GestaoRepositoryImpl();
});

// Provider principal do nosso controller
final gestaoControllerProvider =
    NotifierProvider<GestaoController, GestaoState>(
  () => GestaoController(),
);

/// Controller responsável por gerenciar o estado da tela de gestão.
/// Orquestra as chamadas aos UseCases e atualiza o estado da UI.
class GestaoController extends Notifier<GestaoState> {
  late final GetCategorias _getCategorias;
  late final CreateCategoria _createCategoria;
  late final DeleteCategoria _deleteCategoria;
  late final ReorderCategorias _reorderCategorias;
  late final UpdateCategoriaName _updateCategoriaName;
  late final GetProdutosByCategoria _getProdutosByCategoria;
  late final CreateProduto _createProduto;
  late final DeleteProduto _deleteProduto;
  late final UpdateProdutoName _updateProdutoName;
  late final UpdateProdutoPrice _updateProdutoPrice;
  late final UndoDeleteProduto _undoDeleteProduto;
  late final GetAllProdutos _getAllProdutos;

  @override
  GestaoState build() {
    // Inicializa todos os casos de uso com a instância do repositório
    final repository = ref.watch(gestaoRepositoryProvider);
    _getCategorias = GetCategorias(repository);
    _createCategoria = CreateCategoria(repository);
    _deleteCategoria = DeleteCategoria(repository);
    _reorderCategorias = ReorderCategorias(repository);
    _updateCategoriaName = UpdateCategoriaName(repository);
    _getProdutosByCategoria = GetProdutosByCategoria(repository);
    _createProduto = CreateProduto(repository);
    _deleteProduto = DeleteProduto(repository);
    _updateProdutoName = UpdateProdutoName(repository);
    _updateProdutoPrice = UpdateProdutoPrice(repository);
    _undoDeleteProduto = UndoDeleteProduto(repository);
    _getAllProdutos = GetAllProdutos(repository);

    // Lógica para carregar o estado inicial
    try {
      final categorias = _getCategorias();
      if (categorias.isNotEmpty) {
        final primeiraCategoriaId = categorias.first.id;
        final produtos = _getProdutosByCategoria(primeiraCategoriaId);
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

  // --- Métodos de UI ---

  void selecionarCategoriaPorIndice(int index) {
    if (index >= 0 && index < state.categorias.length) {
      final categoriaId = state.categorias[index].id;
      selecionarCategoria(categoriaId);
    }
  }

  void selecionarCategoria(String categoriaId) {
    if (state.categoriaSelecionadaId == categoriaId) return;

    state = state.copyWith(
      categoriaSelecionadaId: categoriaId,
      clearUltimoProdutoDeletado: true,
    );

    try {
      final produtos = _getProdutosByCategoria(categoriaId);
      state = state.copyWith(produtos: produtos);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao carregar produtos.');
    }
  }

  void clearError() => state = state.copyWith(clearErrorMessage: true);

  void setReordering(bool value) => state = state.copyWith(isReordering: value);

  void setDraggingProduto(bool value) =>
      state = state.copyWith(isDraggingProduto: value);

  // --- Métodos que chamam os UseCases ---

  Future<void> criarCategoria(String nome) async {
    state = state.copyWith(isLoading: true);
    try {
      await _createCategoria(nome);
      // Recarrega as categorias após a criação
      state = state.copyWith(categorias: _getCategorias(), isLoading: false);
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Falha ao criar categoria.', isLoading: false);
    }
  }

  Future<void> deletarCategoria(String categoriaId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _deleteCategoria(categoriaId);
      final categoriasAtualizadas = _getCategorias();

      if (categoriasAtualizadas.isNotEmpty) {
        final novaCategoriaId = categoriasAtualizadas.first.id;
        final novosProdutos = _getProdutosByCategoria(novaCategoriaId);
        state = state.copyWith(
          categorias: categoriasAtualizadas,
          categoriaSelecionadaId: novaCategoriaId,
          produtos: novosProdutos,
          isLoading: false,
        );
      } else {
        // Se não houver mais categorias, zera o estado
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
      await _reorderCategorias(categorias);
      state = state.copyWith(categorias: categorias);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao reordenar categorias.');
    }
  }

  Future<void> atualizarNomeCategoria(String id, String novoNome) async {
    try {
      await _updateCategoriaName(id: id, novoNome: novoNome);
      state = state.copyWith(categorias: _getCategorias());
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Falha ao atualizar nome da categoria.');
    }
  }

  Future<void> criarProduto(String nome) async {
    if (state.categoriaSelecionadaId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await _createProduto(
          nome: nome, categoriaId: state.categoriaSelecionadaId!);
      // Recarrega os produtos da categoria selecionada diretamente
      final produtosAtualizados = _getProdutosByCategoria(state.categoriaSelecionadaId!);
      state = state.copyWith(produtos: produtosAtualizados, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Falha ao criar produto.', isLoading: false);
    }
  }

  Future<void> deletarProduto(String produtoId) async {
    final produtoParaDeletar =
        state.produtos.firstWhere((p) => p.id == produtoId);
    final categoriaDoProdutoDeletado = state.categoriaSelecionadaId!;

    final produtosAtuais = List<Produto>.from(state.produtos)
      ..removeWhere((p) => p.id == produtoId);
    state = state.copyWith(
      produtos: produtosAtuais,
      ultimoProdutoDeletado: produtoParaDeletar,
      idCategoriaProdutoDeletado: categoriaDoProdutoDeletado,
    );

    try {
      await _deleteProduto(
          produtoId: produtoId, categoriaId: categoriaDoProdutoDeletado);
    } catch (e) {
      state = state.copyWith(
        produtos: _getProdutosByCategoria(categoriaDoProdutoDeletado),
        // Restaura
        errorMessage: 'Falha ao deletar produto.',
        clearUltimoProdutoDeletado: true,
      );
    }
  }

  Future<void> desfazerDeletarProduto() async {
    if (state.ultimoProdutoDeletado == null ||
        state.idCategoriaProdutoDeletado == null) {
      return;
    }

    final produtoParaRestaurar = state.ultimoProdutoDeletado!;
    final categoriaOriginalId = state.idCategoriaProdutoDeletado!;
    state = state.copyWith(isLoading: true);

    try {
      await _undoDeleteProduto(produtoParaRestaurar);
      if (state.categoriaSelecionadaId == categoriaOriginalId) {
        state = state.copyWith(
          produtos: _getProdutosByCategoria(categoriaOriginalId),
          clearUltimoProdutoDeletado: true,
          isLoading: false,
        );
      } else {
        state =
            state.copyWith(clearUltimoProdutoDeletado: true, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Falha ao desfazer a exclusão.',
        clearUltimoProdutoDeletado: true,
        isLoading: false,
      );
    }
  }

  Future<void> atualizarPreco(
      String produtoId, String precoStringFormatado) async {
    final stringSemMilhar = precoStringFormatado.replaceAll('.', '');
    final stringParaParse = stringSemMilhar.replaceAll(',', '.');
    final novoPreco = double.tryParse(stringParaParse);

    if (novoPreco != null) {
      try {
        await _updateProdutoPrice(id: produtoId, novoPreco: novoPreco);
        // Opcional: recarregar produtos se precisar validar o salvamento
      } catch (e) {
        state = state.copyWith(errorMessage: 'Falha ao salvar o preço.');
      }
    }
  }

  Future<void> atualizarNomeProduto(String id, String novoNome) async {
    try {
      await _updateProdutoName(id: id, novoNome: novoNome);
      selecionarCategoria(state.categoriaSelecionadaId!);
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Falha ao atualizar nome do produto.');
    }
  }

  String gerarTextoRelatorio() {
    final hoje = DateTime.now();
    final formatoData = DateFormat('dd/MM/yyyy');
    final dataFormatada = formatoData.format(hoje);
    final todosProdutos = _getAllProdutos();

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
