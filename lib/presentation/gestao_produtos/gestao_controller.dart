import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:precifica/data/services/ai_service.dart';
import 'package:precifica/domain/entities/report_template.dart';
import 'package:precifica/domain/services/report_generator_service.dart';
import 'package:precifica/domain/usecases/ai/organize_ai.dart';
import 'package:precifica/domain/usecases/produto/update_produto_status.dart';

import 'package:precifica/data/repositories/gestao_repository_impl.dart';
import 'package:precifica/data/services/preferences_service.dart';
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
  late GetCategorias _getCategorias;
  late CreateCategoria _createCategoria;
  late DeleteCategoria _deleteCategoria;
  late ReorderCategorias _reorderCategorias;
  late UpdateCategoriaName _updateCategoriaName;
  late GetProdutosByCategoria _getProdutosByCategoria;
  late CreateProduto _createProduto;
  late DeleteProduto _deleteProduto;
  late UpdateProdutoName _updateProdutoName;
  late UpdateProdutoPrice _updateProdutoPrice;
  late UndoDeleteProduto _undoDeleteProduto;
  late GetAllProdutos _getAllProdutos;
  late UpdateProdutoStatus _updateProdutoStatus;
  late OrganizeWithAI _organizeAI;
  final PreferencesService _preferencesService = PreferencesService();
  bool _isInitialized = false;

  void _init() {
    if (_isInitialized) return;
    final repository = ref.read(gestaoRepositoryProvider);
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
    _isInitialized = true;
  }

  @override
  GestaoState build() {
    _init();
    // O estado inicial será definido por _carregarDadosIniciais
    state = GestaoState(isLoading: true);
    _carregarDadosIniciais();
    return state;
  }

  Future<void> organizarComIA() async {
    state = state.copyWith(isLoading: true);
    try {
      await _organizeAI();
      
      // Limpa perfil ao organizar com IA, pois a estrutura foi reorganizada
      _clearPerfilSeNecessario();
      
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
        // Tenta recuperar a última categoria visualizada
        final lastCategoryId = await _preferencesService.getLastCategoryId();
        
        // Verifica se a categoria salva ainda existe
        String categoriaSelecionadaId;
        if (lastCategoryId != null && 
            categorias.any((cat) => cat.id == lastCategoryId)) {
          categoriaSelecionadaId = lastCategoryId;
        } else {
          categoriaSelecionadaId = categorias.first.id;
        }
        
        final produtos = _getProdutosByCategoria(categoriaSelecionadaId);
        final produtosPorCategoria = {
          categoriaSelecionadaId: List<Produto>.from(produtos),
        };
        state = state.copyWith(
          categorias: categorias,
          produtos: produtos,
          produtosPorCategoria: produtosPorCategoria,
          categoriaSelecionadaId: categoriaSelecionadaId,
          perfisSalvos: perfis,
          perfilAtual: nomePerfilCarregado,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          categorias: [],
          produtos: [],
          produtosPorCategoria: const {},
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

    final produtosExistentes =
        state.produtosPorCategoria[categoriaId] ?? _getProdutosByCategoria(categoriaId);
    final produtosPorCategoria = Map<String, List<Produto>>.from(state.produtosPorCategoria)
      ..[categoriaId] = List<Produto>.from(produtosExistentes);

    state = state.copyWith(
      categoriaSelecionadaId: categoriaId,
      clearUltimoProdutoDeletado: true,
      produtos: produtosExistentes,
      produtosPorCategoria: produtosPorCategoria,
    );
    
    // Salva a categoria selecionada nas preferências
    _preferencesService.saveLastCategoryId(categoriaId);
  }

  void _refreshProdutosDaCategoriaAtual() {
    final categoriaId = state.categoriaSelecionadaId;
    if (categoriaId == null) return;
    try {
      final produtos = _getProdutosByCategoria(categoriaId);
      final produtosPorCategoria =
          Map<String, List<Produto>>.from(state.produtosPorCategoria)
            ..[categoriaId] = List<Produto>.from(produtos);
      state = state.copyWith(
        produtos: produtos,
        produtosPorCategoria: produtosPorCategoria,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao recarregar produtos.');
    }
  }

  Future<void> prefetchCategoriaPorIndice(int index) async {
    if (index < 0 || index >= state.categorias.length) return;
    final categoriaId = state.categorias[index].id;
    await prefetchCategoria(categoriaId);
  }

  Future<void> prefetchCategoria(String categoriaId) async {
    if (state.produtosPorCategoria.containsKey(categoriaId)) return;
    try {
      final produtos = _getProdutosByCategoria(categoriaId);
      final produtosPorCategoria =
          Map<String, List<Produto>>.from(state.produtosPorCategoria)
            ..[categoriaId] = List<Produto>.from(produtos);
      state = state.copyWith(produtosPorCategoria: produtosPorCategoria);
    } catch (e) {
      // Prefetch é best-effort: registra erro apenas se categoria selecionada
      if (state.categoriaSelecionadaId == categoriaId) {
        state = state.copyWith(errorMessage: 'Falha ao carregar produtos.');
      }
    }
  }

  void clearError() => state = state.copyWith(clearErrorMessage: true);

  void setReordering(bool value) => state = state.copyWith(isReordering: value);

  void setDraggingProduto(bool value) =>
      state = state.copyWith(isDraggingProduto: value);

  /// Limpa o perfil atual quando o usuário faz alterações sensíveis
  /// que invalidam o perfil aplicado
  void _clearPerfilSeNecessario() {
    if (state.perfilAtual != null) {
      state = state.copyWith(clearPerfilAtual: true);
    }
  }

  Future<void> criarCategoria(String nome) async {
    state = state.copyWith(isLoading: true);
    try {
      await _createCategoria(nome);
      final categoriasAtualizadas = _getCategorias();

      // Seleciona automaticamente a categoria recém-criada (última da lista)
      String? categoriaSelecionadaId = categoriasAtualizadas.isNotEmpty 
          ? categoriasAtualizadas.last.id 
          : null;

      final produtosAtualizados = categoriaSelecionadaId != null
          ? _getProdutosByCategoria(categoriaSelecionadaId)
          : <Produto>[];

      state = state.copyWith(
        categorias: categoriasAtualizadas,
        categoriaSelecionadaId: categoriaSelecionadaId,
        produtos: produtosAtualizados,
        isLoading: false,
      );
    } catch (e) {
      // Captura a mensagem de erro específica para nomes duplicados
      final mensagemErro = e.toString().contains('Já existe uma categoria')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Falha ao criar categoria.';
      state = state.copyWith(
          errorMessage: mensagemErro, isLoading: false);
    }
  }

  Future<void> deletarCategoria(String categoriaId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _deleteCategoria(categoriaId);
      final categoriasAtualizadas = _getCategorias();

      // Limpa perfil ao deletar categoria
      _clearPerfilSeNecessario();

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
      
      // Limpa perfil ao reordenar categorias
      _clearPerfilSeNecessario();
      
      state = state.copyWith(categorias: categorias);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Falha ao reordenar categorias.');
    }
  }

  Future<void> atualizarNomeCategoria(String id, String novoNome) async {
    try {
      await _updateCategoriaName(id: id, novoNome: novoNome);
      
      // Limpa perfil ao modificar nome da categoria
      _clearPerfilSeNecessario();
      
      state = state.copyWith(categorias: _getCategorias());
    } catch (e) {
      // Captura a mensagem de erro específica para nomes duplicados
      final mensagemErro = e.toString().contains('Já existe uma categoria')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Falha ao atualizar nome da categoria.';
      state = state.copyWith(errorMessage: mensagemErro);
    }
  }

  Future<void> criarProduto(String nome) async {
    if (state.categoriaSelecionadaId == null) {
      state = state.copyWith(
          errorMessage:
              'Crie ou selecione uma categoria antes de adicionar produtos.');
      return;
    }
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
    Produto? produtoParaDeletar;
    String? categoriaDoProdutoDeletado;
    
    try {
      produtoParaDeletar =
          state.produtos.firstWhere((p) => p.id == produtoId);
      categoriaDoProdutoDeletado = state.categoriaSelecionadaId!;

      final produtosAtuais = List<Produto>.from(state.produtos)
        ..removeWhere((p) => p.id == produtoId);
      final produtosPorCategoria =
          Map<String, List<Produto>>.from(state.produtosPorCategoria)
            ..[categoriaDoProdutoDeletado] = List<Produto>.from(produtosAtuais);
      state = state.copyWith(
        produtos: produtosAtuais,
        produtosPorCategoria: produtosPorCategoria,
        ultimoProdutoDeletado: produtoParaDeletar,
        idCategoriaProdutoDeletado: categoriaDoProdutoDeletado,
      );

      await _deleteProduto(
          produtoId: produtoId, categoriaId: categoriaDoProdutoDeletado);
      
      // Limpa perfil ao deletar produto
      _clearPerfilSeNecessario();
    } on StateError catch (_) {
      // Produto não encontrado na lista
      state = state.copyWith(
        errorMessage: 'Produto não encontrado.',
      );
      return;
    } catch (e) {
      if (categoriaDoProdutoDeletado == null) return;
      
      final produtosRestaurados =
          _getProdutosByCategoria(categoriaDoProdutoDeletado);
      final produtosPorCategoriaRestaurado =
          Map<String, List<Produto>>.from(state.produtosPorCategoria)
            ..[categoriaDoProdutoDeletado] =
                List<Produto>.from(produtosRestaurados);
      state = state.copyWith(
        produtos: produtosRestaurados,
        produtosPorCategoria: produtosPorCategoriaRestaurado,
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
      
      // Limpa perfil ao modificar nome do produto
      _clearPerfilSeNecessario();
      
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

  /// Salva a posição de rolagem da categoria atual.
  Future<void> saveScrollPosition(String categoryId, double position) async {
    await _preferencesService.saveScrollPosition(categoryId, position);
  }

  /// Recupera a posição de rolagem salva para uma categoria.
  Future<double> getScrollPosition(String categoryId) async {
    return await _preferencesService.getScrollPosition(categoryId);
  }

  String gerarTextoRelatorio() {
    // Usa o modelo padrão para manter compatibilidade com código existente
    final templatePadrao = ReportTemplate.padrao();
    return gerarTextoRelatorioComTemplate(templatePadrao);
  }

  String gerarTextoRelatorioComTemplate(ReportTemplate template) {
    final categorias = _getCategorias();
    final todosProdutos = _getAllProdutos();
    final reportGenerator = ReportGeneratorService();

    return reportGenerator.gerarRelatorio(
      template: template,
      categorias: categorias,
      todosProdutos: todosProdutos,
    );
  }
}
