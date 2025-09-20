import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:precifica/data/models/produto.dart';
import 'package:precifica/gestao_produtos/gestao_controller.dart';
import 'package:precifica/gestao_produtos/widgets/item_produto.dart';

class ProductListView extends ConsumerWidget {
  /// Callback para notificar a página pai que um produto foi tocado duas vezes.
  final Function(Produto) onProdutoDoubleTap;
  final String categoriaId;

  const ProductListView({
    super.key,
    required this.onProdutoDoubleTap,
    required this.categoriaId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produtos = ref.watch(gestaoControllerProvider.select(
            (state) => state.produtos.where((p) => p.categoriaId == categoriaId).toList()));

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.separated(
        itemCount: produtos.length,
        itemBuilder: (context, index) {
          final produto = produtos[index];
          return ItemProduto(
            produto: produto,
            onDoubleTap: () => onProdutoDoubleTap(produto),
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