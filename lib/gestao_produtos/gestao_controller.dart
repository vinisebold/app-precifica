import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:organiza_ae/data/repositories/hive_gestao_repository.dart';
import 'package:organiza_ae/data/models/categoria.dart';
import 'package:organiza_ae/data/models/produto.dart';
import 'package:organiza_ae/gestao_produtos/domain/i_gestao_repository.dart';

class GestaoState {
  final List<Categoria> categorias;
  final List<Produto> produtos;
  final String? categoriaSelecionadaId;

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

// Este provider decide qual implementação do nosso contrato será usada.
// No nosso caso, é o HiveGestaoRepository.
final gestaoRepositoryProvider = Provider<IGestaoRepository>((ref) {
  return HiveGestaoRepository();
});

class GestaoController extends Notifier<GestaoState> {
  late final IGestaoRepository _repository;

  @override
  GestaoState build() {
    // Pega a instância do repositório fornecida pelo Provider
    _repository = ref.watch(gestaoRepositoryProvider);

    // O resto da lógica de inicialização usa `_repository`
    final categorias = _repository.getCategorias();
    if (categorias.isNotEmpty) {
      final primeiraCategoriaId = categorias.first.id;
      final produtos = _repository.getProdutosPorCategoria(primeiraCategoriaId);
      return GestaoState(
        categorias: categorias,
        produtos: produtos,
        categoriaSelecionadaId: primeiraCategoriaId,
      );
    }
    return GestaoState();
  }

  // --- Funções de Categoria ---
  Future<void> criarCategoria(String nome) async {
    await _repository.criarCategoria(nome);
    state = state.copyWith(categorias: _repository.getCategorias());
  }

  Future<void> deletarCategoria(String categoriaId) async {
    await _repository.deletarCategoria(categoriaId);

    // Rebusca a lista de categorias que sobraram.
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
  }

  void selecionarCategoria(String categoriaId) {
    final produtos = _repository.getProdutosPorCategoria(categoriaId);
    state = state.copyWith(
      categoriaSelecionadaId: categoriaId,
      produtos: produtos,
    );
  }

  // --- Funções de Produto ---
  Future<void> criarProduto(String nome) async {
    // Só podemos criar um produto se uma categoria estiver selecionada.
    if (state.categoriaSelecionadaId != null) {
      await _repository.criarProduto(nome, state.categoriaSelecionadaId!);
      // Após criar, atualiza a lista de produtos da categoria atual.
      selecionarCategoria(state.categoriaSelecionadaId!);
    }
  }

  Future<void> atualizarPreco(
      String produtoId, String precoStringFormatado) async {
    final stringSemMilhar = precoStringFormatado.replaceAll('.', '');
    final stringParaParse = stringSemMilhar.replaceAll(',', '.');

    // 3. Tenta converter para double.
    final novoPreco = double.tryParse(stringParaParse);

    if (novoPreco != null) {
      // 4. Envia o número puro (double) para o serviço de armazenamento.
      await _repository.atualizarPrecoProduto(produtoId, novoPreco);
    }
  }

  String gerarTextoRelatorio() {
    // 1. Pega a data e hora de agora.
    final hoje = DateTime.now();
    // 2. Define o formato que queremos (dia/mês/ano).
    final formatoData = DateFormat('dd/MM/yyyy');
    // 3. Formata a data.
    final dataFormatada = formatoData.format(hoje);

    final todosProdutos = _repository.getAllProdutos();

    if (todosProdutos.isEmpty) {
      return 'Nenhum produto cadastrado para gerar relatório.';
    }

    final buffer = StringBuffer();
    // 4. Monta o título com a data formatada.
    buffer.writeln('Lista de Preços - $dataFormatada');
    buffer.writeln(); // Adiciona uma linha em branco para espaçamento

    // 5. Itera por TODOS os produtos, sem separar por categoria.
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
