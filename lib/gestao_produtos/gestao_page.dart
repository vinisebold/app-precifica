import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/gestao_produtos/gestao_controller.dart';
import 'package:organiza_ae/gestao_produtos/widgets/categoria_nav_bar.dart';
import 'package:organiza_ae/gestao_produtos/widgets/item_produto.dart';
import 'package:share_plus/share_plus.dart';

class GestaoPage extends ConsumerWidget {
  const GestaoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    ref.listen(
      gestaoControllerProvider,
      (previousState, newState) {
        final errorMessage = (newState).errorMessage;
        if (errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
              backgroundColor: colorScheme.errorContainer,
            ),
          );
          ref.read(gestaoControllerProvider.notifier).clearError();
        }
      },
    );

    final gestaoState = ref.watch(gestaoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestão de Preços',
          style: textTheme.titleLarge,
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final textoRelatorio = ref
                  .read(gestaoControllerProvider.notifier)
                  .gerarTextoRelatorio();
              Share.share(textoRelatorio);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _mostrarDialogoNovaCategoria(context, ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: gestaoState.produtos.length,
            itemBuilder: (context, index) {
              final produto = gestaoState.produtos[index];
              return ItemProduto(produto: produto);
            },
          ),
          // Área de lixo que aparece condicionalmente
          if (gestaoState.isReordering) _buildDeleteArea(context, ref),
        ],
      ),
      bottomNavigationBar: const CategoriaNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: gestaoState.categoriaSelecionadaId != null
            ? () => _mostrarDialogoNovoProduto(context, ref)
            : null,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  // Widget para a área de apagar
  Widget _buildDeleteArea(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: DragTarget<String>(
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isHovering ? 120 : 100,
            decoration: BoxDecoration(
              color: isHovering
                  ? colorScheme.errorContainer.withOpacity(0.9)
                  : colorScheme.errorContainer.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(60),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, color: colorScheme.onErrorContainer, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Arraste aqui para apagar',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
                ),
              ],
            ),
          );
        },
        onAcceptWithDetails: (details) {
          ref
              .read(gestaoControllerProvider.notifier)
              .deletarCategoria(details.data);
        },
      ),
    );
  }

  void _mostrarDialogoNovoProduto(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Novo Produto', style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nome do produto"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () {
              final nomeProduto = controller.text;
              if (nomeProduto.isNotEmpty) {
                ref
                    .read(gestaoControllerProvider.notifier)
                    .criarProduto(nomeProduto);
                Navigator.of(context).pop();
              }
            },
            child: Text('Salvar', style: textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNovaCategoria(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Categoria', style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nome da categoria"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: Text('Cancelar', style: textTheme.labelLarge),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Salvar', style: textTheme.labelLarge),
            onPressed: () {
              final nomeCategoria = controller.text;
              if (nomeCategoria.isNotEmpty) {
                ref
                    .read(gestaoControllerProvider.notifier)
                    .criarCategoria(nomeCategoria);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
