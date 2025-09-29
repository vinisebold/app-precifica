import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:precifica/data/services/ai_service.dart';
import 'package:precifica/domain/usecases/ai/organize_ai.dart';
import 'package:precifica/domain/usecases/produto/update_produto_status.dart';

import 'package:precifica/data/repositories/gestao_repository_impl.dart';
import 'package:precifica/domain/entities/categoria.dart';
import 'package:precifica/domain/entities/produto.dart';
import 'package:precifica/domain/repositories/i_gestao_repository.dart';

import 'package:precifica/domain/usecases/categoria/create_categoria.dart';
import 'package:precifica/domain/usecases/categoria/delete_categoria.dart';
import 'package:precifica/domain/usecases/categoria/get_categorias.dart';
import 'package:precifica/domain/usecases/categoria/reorder_categorias.dart';
import 'package:precifica/domain/usecases/categoria/update_categoria_name.dart';
import 'package:precifica/domain/usecases/produto/create_produto.dart';
import 'package:precifica/domain/usecases/produto/delete_produto.dart';
import 'package:precifica/domain/usecases/produto/get_all_produtos.dart';
import 'package:precifica/domain/usecases/produto/get_produtos_by_categoria.dart';
import 'package:precifica/domain/usecases/produto/undo_delete_produto.dart';
import 'package:precifica/domain/usecases/produto/update_produto_name.dart';
import 'package:precifica/domain/usecases/produto/update_produto_price.dart';

import 'gestao_state.dart';

final gestaoRepositoryProvider = Provider<IGestaoRepository>((ref) {
  final repository = GestaoRepositoryImpl();
  // Retornamos a instância que pode ser usada em `getProfileList`
  return repository;
});

final gestaoControllerProvider =
    NotifierProvider<GestaoController, GestaoState>(
  () => GestaoController(),
);

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
  late final UpdateProdutoStatus _updateProdutoStatus;
  late final OrganizeWithAI _organizeAI;

  @override
  GestaoState build() {
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
    _updateProdutoStatus = UpdateProdutoStatus(repository);

    final aiService = AIService();
    _organizeAI = OrganizeWithAI(repository, aiService);

    // O estado inicial será definido por _carregarDadosIniciais
    state = GestaoState(isLoading: true);
    _carregarDadosIniciais();
    return state;
  }

  Future<void> organizarComIA() async { // Remova o parâmetro apiKey
    state = state.copyWith(isLoading: true);
    try {
      await _organizeAI(); // Chame sem a chave
      await _carregarDadosIniciais();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Falha ao organizar com IA: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> _carregarDadosIniciais({String? nomePerfilCarregado}) async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(gestaoRepositoryProvider);
      final perfis = await repository.getProfileList();
      final categorias = _getCategorias();

      if (categorias.isNotEmpty) {
        final primeiraCategoriaId = categorias.first.id;
        final produtos = _getProdutosByCategoria(primeiraCategoriaId);
        state = state.copyWith(
          categorias: categorias,
          produtos: produtos,
          categoriaSelecionadaId: primeiraCategoriaId,
          perfisSalvos: perfis,
          perfilAtual: nomePerfilCarregado,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          categorias: [],
          produtos: [],
          categoriaSelecionadaId: null,
          perfisSalvos: perfis,
          perfilAtual: nomePerfilCarregado,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
          errorMessage: "Falha ao carregar dados.", isLoading: false);
    }
  }

  Future<void> carregarPerfil(String nomePerfil) async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(gestaoRepositoryProvider);
      final jsonString = await repository.getProfileContent(nomePerfil);
      final List<Map<String, dynamic>> data = List.from(jsonDecode(jsonString));
      await repository.seedDatabase(data);
      await _carregarDadosIniciais(nomePerfilCarregado: nomePerfil);
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Falha ao carregar o perfil.', isLoading: false);
    }
  }

  Future<void> salvarPerfilAtual(String nomePerfil) async {
    if (nomePerfil.trim().isEmpty) {
      state =
          state.copyWith(errorMessage: 'O nome do perfil não pode ser vazio.');
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(gestaoRepositoryProvider);
      await repository.saveCurrentDataAsProfile(nomePerfil);
      final perfis = await repository.getProfileList();
      state = state.copyWith(
          perfisSalvos: perfis, perfilAtual: nomePerfil, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Falha ao salvar o perfil.', isLoading: false);
    }
  }

  Future<void> excluirPerfil(String nomePerfil) async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(gestaoRepositoryProvider);
      await repository.deleteProfile(nomePerfil);
      final perfis = await repository.getProfileList();

      if (state.perfilAtual == nomePerfil) {
        state = state.copyWith(
            perfisSalvos: perfis, clearPerfilAtual: true, isLoading: false);
      } else {
        state = state.copyWith(perfisSalvos: perfis, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Falha ao excluir o perfil.', isLoading: false);
    }
  }

  Future<void> importarPerfil() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final nomePerfil = p.basenameWithoutExtension(file.path);

        final appDir = await getApplicationDocumentsDirectory();
        final profilesDir = Directory(p.join(appDir.path, 'profiles'));
        final newPath = p.join(profilesDir.path, '$nomePerfil.json');
        await file.copy(newPath);

        final perfis =
            await ref.read(gestaoRepositoryProvider).getProfileList();
        state = state.copyWith(perfisSalvos: perfis);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao importar o perfil.');
    }
  }

  Future<void> exportarPerfil(String nomePerfil) async {
    try {
      final repository = ref.read(gestaoRepositoryProvider);
      final jsonString = await repository.getProfileContent(nomePerfil);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Exportar Perfil',
        fileName: '$nomePerfil.json',
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao exportar o perfil.');
    }
  }

  Future<void> resetAndSeedDatabase(List<Map<String, dynamic>> seedData) async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(gestaoRepositoryProvider);
      await repository.seedDatabase(seedData);
      await _carregarDadosIniciais();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Falha ao carregar o perfil.', isLoading: false);
    }
  }

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
    _refreshProdutosDaCategoriaAtual();
  }

  void _refreshProdutosDaCategoriaAtual() {
    if (state.categoriaSelecionadaId == null) return;
    try {
      final produtos = _getProdutosByCategoria(state.categoriaSelecionadaId!);
      state = state.copyWith(produtos: produtos);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao recarregar produtos.');
    }
  }

  void clearError() => state = state.copyWith(clearErrorMessage: true);

  void setReordering(bool value) => state = state.copyWith(isReordering: value);

  void setDraggingProduto(bool value) =>
      state = state.copyWith(isDraggingProduto: value);

  Future<void> criarCategoria(String nome) async {
    state = state.copyWith(isLoading: true);
    try {
      await _createCategoria(nome);
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
      _refreshProdutosDaCategoriaAtual();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao criar produto.');
    } finally {
      state = state.copyWith(isLoading: false);
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
        _refreshProdutosDaCategoriaAtual();
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Falha ao desfazer a exclusão.',
      );
    } finally {
      state =
          state.copyWith(clearUltimoProdutoDeletado: true, isLoading: false);
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
      } catch (e) {
        state = state.copyWith(errorMessage: 'Falha ao salvar o preço.');
      }
    }
  }

  Future<void> atualizarNomeProduto(String id, String novoNome) async {
    try {
      await _updateProdutoName(id: id, novoNome: novoNome);
      _refreshProdutosDaCategoriaAtual();
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Falha ao atualizar nome do produto.');
    }
  }

  Future<void> atualizarStatusProduto(String id, bool isAtivo) async {
    try {
      await _updateProdutoStatus(id: id, isAtivo: isAtivo);
      _refreshProdutosDaCategoriaAtual();
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Falha ao atualizar status do produto.');
    }
  }

  String gerarTextoRelatorio() {
    final hoje = DateTime.now();
    final formatoData = DateFormat('dd/MM/yy');
    final formatoDiaSemana = DateFormat('EEEE', 'pt_BR');
    final dataFormatada = formatoData.format(hoje);
    final diaSemanaFormatado = formatoDiaSemana.format(hoje);
    final categorias = _getCategorias();
    final todosProdutos = _getAllProdutos();

    if (todosProdutos.isEmpty) {
      return 'Nenhum produto cadastrado para gerar relatório.';
    }

    final buffer = StringBuffer();
    buffer.writeln('*Preços: $diaSemanaFormatado*');
    buffer.writeln(dataFormatada);
    buffer.writeln();

    for (var categoria in categorias) {
      final produtosDaCategoria = todosProdutos
          .where(
              (p) => p.categoriaId == categoria.id && p.isAtivo && p.preco > 0)
          .toList();
      if (produtosDaCategoria.isNotEmpty) {
        buffer.writeln('${categoria.nome.toUpperCase()}: ⬇️');
        for (var produto in produtosDaCategoria) {
          final precoFormatado =
              produto.preco.toStringAsFixed(2).replaceAll('.', ',');

          final palavras = produto.nome.split(' ');
          final primeiraPalavra = palavras.first;
          final restoDoNome = palavras.skip(1).join(' ');

          if (restoDoNome.isEmpty) {
            buffer.writeln(' *$primeiraPalavra*: $precoFormatado');
          } else {
            buffer.writeln(' *$primeiraPalavra* $restoDoNome: $precoFormatado');
          }
        }
        buffer.writeln();
      }
    }

    final report = buffer.toString();
    if (report.split('\n').where((line) => line.isNotEmpty).length <= 2) {
      return 'Nenhum produto com preço cadastrado para gerar relatório.';
    }

    return report;
  }
}
