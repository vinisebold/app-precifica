import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:precifica/domain/entities/produto.dart';
import '../gestao_controller.dart';
import 'item_produto.dart';

class ProductListView extends ConsumerStatefulWidget {
  final Function(Produto) onProdutoDoubleTap;
  final Function(Produto) onProdutoTap;
  final String categoriaId;

  const ProductListView({
    super.key,
    required this.onProdutoDoubleTap,
    required this.onProdutoTap,
    required this.categoriaId,
  });

  @override
  ConsumerState<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends ConsumerState<ProductListView> {
  late List<FocusNode> _focusNodes;
  late List<Produto> _produtos;

  @override
  void initState() {
    super.initState();
    _produtos =
        ref.read(gestaoControllerProvider.select((state) => state.produtos));
    _focusNodes = List.generate(_produtos.length, (index) => FocusNode());
  }

  @override
  void didUpdateWidget(covariant ProductListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProdutos =
    ref.watch(gestaoControllerProvider.select((state) => state.produtos));

    // Apenas recria os FocusNodes se o número de produtos mudar
    if (_produtos.length != newProdutos.length) {
      _produtos = newProdutos;
      _disposeFocusNodes();
      _focusNodes = List.generate(_produtos.length, (index) => FocusNode());
    }
  }

  void _disposeFocusNodes() {
    for (var node in _focusNodes) {
      node.dispose();
    }
  }

  @override
  void dispose() {
    _disposeFocusNodes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produtos =
    ref.watch(gestaoControllerProvider.select((state) => state.produtos));

    // Garante que temos a quantidade correta de FocusNodes
    if (produtos.length != _focusNodes.length) {
      // Usa um PostFrameCallback para evitar erros de build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _disposeFocusNodes();
            _focusNodes = List.generate(produtos.length, (index) => FocusNode());
          });
        }
      });
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


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.separated(
        itemCount: produtos.length,
        itemBuilder: (context, index) {
          final produto = produtos[index];
          final isLastItem = index == produtos.length - 1;

          return ItemProduto(
            produto: produto,
            focusNode: _focusNodes[index],
            onDoubleTap: () => widget.onProdutoDoubleTap(produto),
            onTap: () => widget.onProdutoTap(produto),
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
        separatorBuilder: (context, index) => const Divider(
          height: 14,
          thickness: 1,
          indent: 16,
          endIndent: 16,
        ),
      ),
    );
  }
}