import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:precifica/domain/entities/produto.dart';
import '../gestao_controller.dart';
import '../../shared/providers/modo_compacto_provider.dart';
import 'item_produto.dart';

class ProductListView extends ConsumerStatefulWidget {
  final Function(Produto) onProdutoDoubleTap;
  final Function(Produto) onProdutoTap;
  final String categoriaId;
  final ValueChanged<bool>? onFabVisibilityRequest;
  final bool forceBarVisible;

  const ProductListView({
    super.key,
    required this.onProdutoDoubleTap,
    required this.onProdutoTap,
    required this.categoriaId,
    this.onFabVisibilityRequest,
    this.forceBarVisible = false,
  });

  @override
  ConsumerState<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends ConsumerState<ProductListView>
    with AutomaticKeepAliveClientMixin {
  late List<FocusNode> _focusNodes;
  late List<Produto> _produtos;
  final ScrollController _scrollController = ScrollController();
  bool _isFabCurrentlyVisible = true;
  bool _isRestoringScroll = false;

  @override
  bool get wantKeepAlive => true;

  // Scroll threshold: distância mínima de rolagem (em pixels) antes de acionar
  // a mudança de visibilidade do FAB. Evita que o FAB fique piscando
  // durante pequenos movimentos de scroll.
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
  _produtos = ref.read(gestaoControllerProvider.select((state) =>
    state.produtosPorCategoria[widget.categoriaId] ?? const <Produto>[]));
    _focusNodes = List.generate(_produtos.length, (index) => FocusNode());
    
    // Adiciona listener para salvar a posição de rolagem
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFabVisibilityRequest?.call(true);
    });
    
    // Restaura a posição de rolagem após o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
    });
  }

  double _accumulatedScroll = 0.0;

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Ignora eventos de scroll durante restauração da posição
    if (_isRestoringScroll) return;

    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;

    // Detecta mudança de direção → zera acúmulo
    if (delta.sign != _accumulatedScroll.sign) {
      _accumulatedScroll = 0.0;
    }

    _accumulatedScroll += delta;

    const hideThreshold = 48.0;
    const showThreshold = 48.0;

    // Scroll para baixo (acumulado)
    if (_accumulatedScroll > hideThreshold && offset > 56) {
      _notifyFabVisibility(false);
      _accumulatedScroll = 0.0;
    }
    // Scroll para cima (acumulado)
    else if (_accumulatedScroll < -showThreshold || offset <= 32) {
      _notifyFabVisibility(true);
      _accumulatedScroll = 0.0;
    }

    _lastScrollOffset = offset;
  }



  void _notifyFabVisibility(bool visible) {
    if (_isFabCurrentlyVisible == visible) return;
    _isFabCurrentlyVisible = visible;
    widget.onFabVisibilityRequest?.call(visible);
  }

  Future<void> _restoreScrollPosition() async {
    if (!mounted || !_scrollController.hasClients) return;
    
    final savedPosition = await ref.read(gestaoControllerProvider.notifier)
        .getScrollPosition(widget.categoriaId);
    
    if (mounted && _scrollController.hasClients && savedPosition > 0) {
      // Marca que estamos restaurando para ignorar eventos de scroll
      _isRestoringScroll = true;

      // Aguarda um frame para garantir que a lista foi renderizada
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetPosition = savedPosition > maxScroll ? maxScroll : savedPosition;
        
        _scrollController.jumpTo(targetPosition);

        // Sincroniza o _lastScrollOffset para a nova posição
        _lastScrollOffset = targetPosition;
        _accumulatedScroll = 0.0;
      }

      // Aguarda um pouco para garantir que o scroll terminou
      await Future.delayed(const Duration(milliseconds: 50));
      _isRestoringScroll = false;
    }
  }

  @override
  void didUpdateWidget(covariant ProductListView oldWidget) {
    super.didUpdateWidget(oldWidget);
  final newProdutos = ref.read(gestaoControllerProvider.select((state) =>
    state.produtosPorCategoria[widget.categoriaId] ?? const <Produto>[]));

    // Se o pai forçou a barra visível (ex: swipe horizontal), sincroniza o estado interno
    if (widget.forceBarVisible && !oldWidget.forceBarVisible) {
      _accumulatedScroll = 0.0;
      _isFabCurrentlyVisible = true;
    }

    // Se mudou de categoria, reseta o estado de scroll acumulado
    if (oldWidget.categoriaId != widget.categoriaId) {
      // Reseta o estado de scroll acumulado para evitar comportamentos inesperados
      _accumulatedScroll = 0.0;
      _lastScrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;

      // Garante que a barra/FAB fiquem visíveis ao trocar de categoria
      if (!_isFabCurrentlyVisible) {
        _isFabCurrentlyVisible = true;
        widget.onFabVisibilityRequest?.call(true);
      }

      // Não restaura scroll aqui - o scroll é mantido pelo AutomaticKeepAlive
      // ou restaurado no initState quando o widget é criado
    }

    // Apenas recria os FocusNodes se o número de produtos mudar
    if (_produtos.length != newProdutos.length) {
      _produtos = newProdutos;
      _ensureFocusNodesCount(_produtos);
    }
  }

  void _disposeFocusNodes() {
    for (var node in _focusNodes) {
      node.dispose();
    }
  }

  void _ensureFocusNodesCount(List<Produto> produtos) {
    if (_focusNodes.length == produtos.length) {
      return;
    }

    if (_focusNodes.length > produtos.length) {
      for (var i = produtos.length; i < _focusNodes.length; i++) {
        _focusNodes[i].dispose();
      }
      _focusNodes = List<FocusNode>.from(_focusNodes.take(produtos.length));
    } else {
      final additional = produtos.length - _focusNodes.length;
      _focusNodes = [
        ..._focusNodes,
        for (var i = 0; i < additional; i++) FocusNode(),
      ];
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _disposeFocusNodes();
    widget.onFabVisibilityRequest?.call(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para AutomaticKeepAliveClientMixin
    final produtos = ref.watch(gestaoControllerProvider.select((state) =>
        state.produtosPorCategoria[widget.categoriaId] ?? const <Produto>[]));
    final produtosSelecionados = ref.watch(
      gestaoControllerProvider.select((state) => state.produtosSelecionados),
    );
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
    final isSelectionMode = produtosSelecionados.isNotEmpty;

    _ensureFocusNodesCount(produtos);

    // Garante que temos a quantidade correta de FocusNodes
    if (produtos.length != _focusNodes.length) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final gestaoState = ref.watch(gestaoControllerProvider);

    if (gestaoState.categorias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Bem-vindo!\n\nCrie sua primeira categoria no ícone ➕ na barra superior para começar a organizar.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: colorScheme.outline),
          ),
        ),
      );
    }

    if (produtos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Esta categoria está vazia.\n\nAdicione um novo produto usando o botão 🛒 no canto inferior.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: colorScheme.outline),
          ),
        ),
      );
    }

    // Se a lista de focus nodes estiver vazia (após deleção, por exemplo), não tenta construir a lista de produtos
    if (produtos.isNotEmpty && _focusNodes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final modoCompacto = ref.watch(modoCompactoProvider);
    final dividerHeight = modoCompacto ? 8.0 : 14.0;

    final verticalPadding = modoCompacto ? 4.0 : 8.0;
    final bottomSpacer = modoCompacto ? 92.0 : 112.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: ListView.separated(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0, 0, 0, bottomSpacer),
        itemCount: produtos.length,
        itemBuilder: (context, index) {
          final produto = produtos[index];
          final isLastItem = index == produtos.length - 1;
          final isSelected = produtosSelecionados.contains(produto.id);

          return ItemProduto(
            produto: produto,
            focusNode: _focusNodes[index],
            onDoubleTap: () => widget.onProdutoDoubleTap(produto),
            onTap: () {
              if (isSelectionMode) {
                gestaoNotifier.alternarSelecaoProduto(produto.id);
              } else {
                widget.onProdutoTap(produto);
              }
            },
            onLongPress: () {
              gestaoNotifier.alternarSelecaoProduto(produto.id);
            },
            isSelected: isSelected,
            isSelectionMode: isSelectionMode,
            textInputAction:
            isLastItem ? TextInputAction.done : TextInputAction.next,
            onSubmitted: () {
              if (!isLastItem) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else {
                FocusScope.of(context).unfocus();
              }
            },
          );
        },
        separatorBuilder: (context, index) => Divider(
          height: dividerHeight,
          thickness: 1,
          indent: 16,
          endIndent: 16,
        ),
      ),
    );
  }
}