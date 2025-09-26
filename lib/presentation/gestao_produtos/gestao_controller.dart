import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:precifica/app/core/services/thermal_printer_service.dart';
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
  late final ThermalPrinterService _printerService;
  StreamSubscription<List<ThermalPrinterDevice>>? _printerDevicesSubscription;
  StreamSubscription<PrinterConnectionUpdate>? _printerConnectionSubscription;
  StreamSubscription<bool>? _printerScanningSubscription;
  bool _printerListenersInitialized = false;

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
    _printerService = ref.read(thermalPrinterServiceProvider);

    // O estado inicial será definido por _carregarDadosIniciais
    state = GestaoState(isLoading: true);

    if (!_printerListenersInitialized) {
      _initializePrinterListeners();
      _printerListenersInitialized = true;
      ref.onDispose(() {
        _printerDevicesSubscription?.cancel();
        _printerConnectionSubscription?.cancel();
        _printerScanningSubscription?.cancel();
      });
    }
    _carregarDadosIniciais();
    return state;
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

  void _initializePrinterListeners() {
    _printerDevicesSubscription =
        _printerService.devicesStream.listen((devices) {
      state = state.copyWith(impressorasDisponiveis: devices);
    });

    _printerConnectionSubscription =
        _printerService.connectionStream.listen(_handlePrinterConnection);

    _printerScanningSubscription =
        _printerService.scanningStream.listen((isScanning) {
      state = state.copyWith(isBuscandoImpressoras: isScanning);
    });

    final connectedDevice = _printerService.connectedDevice;
    if (connectedDevice != null) {
      state = state.copyWith(impressoraConectada: connectedDevice);
    }
  }

  void _handlePrinterConnection(PrinterConnectionUpdate update) {
    switch (update.status) {
      case PrinterConnectionStatus.connected:
        state = state.copyWith(
          impressoraConectada: update.device ?? state.impressoraConectada,
          isConectandoImpressora: false,
          mensagemImpressora: update.message ??
              'Conectado a ${update.device?.name ?? 'impressora'}.',
        );
        break;
      case PrinterConnectionStatus.connecting:
        state = state.copyWith(
          impressoraConectada: update.device ?? state.impressoraConectada,
          isConectandoImpressora: true,
          mensagemImpressora: update.message ?? 'Conectando à impressora...',
        );
        break;
      case PrinterConnectionStatus.disconnected:
        state = state.copyWith(
          isConectandoImpressora: false,
          isImprimindo: false,
          mensagemImpressora: update.message ?? 'Impressora desconectada.',
          clearImpressoraConectada: true,
        );
        break;
      case PrinterConnectionStatus.error:
        final shouldClearConnection = update.device == null ||
            state.impressoraConectada?.id == update.device?.id;
        state = state.copyWith(
          isConectandoImpressora: false,
          isImprimindo: false,
          mensagemImpressora:
              update.message ?? 'Falha na conexão com a impressora.',
          clearImpressoraConectada: shouldClearConnection,
        );
        break;
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

  Future<void> buscarImpressoras() async {
    final granted = await _printerService.ensurePermissions();
    if (!granted) {
      state = state.copyWith(
        mensagemImpressora:
            'Permissões de Bluetooth necessárias não foram concedidas.',
        isBuscandoImpressoras: false,
      );
      return;
    }

    try {
      state = state.copyWith(
        mensagemImpressora: 'Buscando impressoras próximas...',
        isBuscandoImpressoras: true,
      );
      await _printerService.startScan();
    } catch (e) {
      state = state.copyWith(
        mensagemImpressora:
            'Erro ao buscar impressoras: ${_mapPrinterError(e)}',
        isBuscandoImpressoras: false,
      );
    }
  }

  Future<void> pararBuscaImpressoras() async {
    try {
      await _printerService.stopScan();
    } finally {
      state = state.copyWith(isBuscandoImpressoras: false);
    }
  }

  Future<void> conectarImpressora(ThermalPrinterDevice device) async {
    final jaConectada = state.impressoraConectada?.id == device.id;
    final conectado = await _printerService.isConnected();

    if (jaConectada && conectado) {
      state = state.copyWith(
        mensagemImpressora: 'Impressora já está conectada.',
      );
      return;
    }

    try {
      await _printerService.connect(device);
    } catch (e) {
      state = state.copyWith(
        mensagemImpressora: 'Erro ao conectar: ${_mapPrinterError(e)}',
        isConectandoImpressora: false,
      );
    }
  }

  Future<void> desconectarImpressora() async {
    try {
      await _printerService.disconnect();
      state = state.copyWith(
        mensagemImpressora: 'Impressora desconectada.',
        clearImpressoraConectada: true,
      );
    } catch (e) {
      state = state.copyWith(
        mensagemImpressora: 'Erro ao desconectar: ${_mapPrinterError(e)}',
      );
    }
  }

  Future<void> imprimirRelatorioAtual() async {
    final linhas = _buildTicketLines();
    if (linhas.isEmpty) {
      state = state.copyWith(
        mensagemImpressora:
            'Nenhum produto com preço cadastrado para imprimir.',
      );
      return;
    }

    state = state.copyWith(
      isImprimindo: true,
      mensagemImpressora: 'Enviando dados para a impressora...',
    );

    try {
      await _printerService.printLines(linhas, config: {
        'width': 58,
        'gap': 2,
      });
      state = state.copyWith(
        isImprimindo: false,
        mensagemImpressora: 'Impressão enviada com sucesso!',
      );
    } catch (e) {
      state = state.copyWith(
        isImprimindo: false,
        mensagemImpressora: 'Falha ao imprimir: ${_mapPrinterError(e)}',
      );
    }
  }

  void limparMensagemImpressora() {
    state = state.copyWith(clearMensagemImpressora: true);
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

  List<LineText> _buildTicketLines() {
    final hoje = DateTime.now();
    final formatoData = DateFormat('dd/MM/yy');
    final formatoHora = DateFormat('HH:mm');
    final formatoDiaSemana = DateFormat('EEEE', 'pt_BR');
    final dataFormatada = formatoData.format(hoje);
    final horaFormatada = formatoHora.format(hoje);
    final diaSemanaBruto = formatoDiaSemana.format(hoje);
    final diaSemanaFormatado = diaSemanaBruto.isEmpty
        ? diaSemanaBruto
        : '${diaSemanaBruto[0].toUpperCase()}${diaSemanaBruto.substring(1)}';

    final categorias = _getCategorias();
    final produtosValidos =
        _getAllProdutos().where((p) => p.isAtivo && p.preco > 0).toList();

    if (produtosValidos.isEmpty) {
      return [];
    }

    final linhas = <LineText>[
      LineText(
        type: LineText.TYPE_TEXT,
        content: 'PRECIFICADOR',
        align: LineText.ALIGN_CENTER,
        weight: 2,
        height: 2,
      ),
      LineText(
        type: LineText.TYPE_TEXT,
        content: 'Preços: $diaSemanaFormatado',
        align: LineText.ALIGN_CENTER,
        weight: 1,
      ),
      LineText(
        type: LineText.TYPE_TEXT,
        content: dataFormatada,
        align: LineText.ALIGN_CENTER,
      ),
      LineText(linefeed: 1),
    ];

    for (final categoria in categorias) {
      final produtosCategoria =
          produtosValidos.where((p) => p.categoriaId == categoria.id).toList();
      if (produtosCategoria.isEmpty) continue;

      linhas.add(
        LineText(
          type: LineText.TYPE_TEXT,
          content: categoria.nome.toUpperCase(),
          align: LineText.ALIGN_LEFT,
          weight: 1,
        ),
      );
      linhas.add(
        LineText(
          type: LineText.TYPE_TEXT,
          content: '-' * 32,
          align: LineText.ALIGN_LEFT,
        ),
      );

      for (final produto in produtosCategoria) {
        final precoFormatado =
            produto.preco.toStringAsFixed(2).replaceAll('.', ',');
        final linha = _formatTicketLine(produto.nome, precoFormatado);
        linhas.add(
          LineText(
            type: LineText.TYPE_TEXT,
            content: linha,
            align: LineText.ALIGN_LEFT,
          ),
        );
      }

      linhas.add(LineText(linefeed: 1));
    }

    linhas
      ..add(
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'Gerado às $horaFormatada',
          align: LineText.ALIGN_CENTER,
        ),
      )
      ..add(LineText(linefeed: 2));

    return linhas;
  }

  String _formatTicketLine(String nome, String preco) {
    const maxChars = 32;
    final precoTexto = 'R\$ $preco';

    if (nome.length + precoTexto.length + 1 <= maxChars) {
      final spaces = maxChars - nome.length - precoTexto.length;
      final padding = spaces > 0 ? ' ' * spaces : ' ';
      return '$nome$padding$precoTexto';
    }

    return '$nome\n$precoTexto';
  }

  String _mapPrinterError(Object error) {
    final message = error.toString();
    if (message.toLowerCase().contains('permiss')) {
      return 'Verifique as permissões de Bluetooth e localização.';
    }
    return message;
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
