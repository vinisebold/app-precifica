import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/data/models/produto.dart';
import 'package:organiza_ae/gestao_produtos/gestao_controller.dart';
import 'package:organiza_ae/gestao_produtos/widgets/item_produto.dart';

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
    // Observa o estado para reconstruir a lista quando os produtos mudarem
    final gestaoState = ref.watch(gestaoControllerProvider);
    // Filtra os produtos com base no categoriaId recebido
    final produtos = gestaoState.produtos
        .where((p) => p.categoriaId == categoriaId)
        .toList();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Mensagem para quando não há categorias criadas
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

    // Mensagem para quando uma categoria está vazia
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

    // A lista de produtos, agora com padding vertical
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.separated(
        itemCount: produtos.length,
        itemBuilder: (context, index) {
          final produto = produtos[index];
          return ItemProduto(
            produto: produto,
            // Chama a função de callback quando o item é tocado duas vezes
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
