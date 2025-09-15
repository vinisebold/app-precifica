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
    // Adicionamos este "ouvinte" para reagir a erros.
    ref.listen(
      gestaoControllerProvider,
      (previousState, newState) {
        final errorMessage = (newState).errorMessage;
        if (errorMessage != null) {
          // Se uma nova mensagem de erro apareceu no estado, mostramos a SnackBar.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
          // E imediatamente limpamos o erro do estado para não mostrá-lo novamente.
          ref.read(gestaoControllerProvider.notifier).clearError();
        }
      },
    );

    // Este watch continua responsável por reconstruir a UI quando os dados mudam.
    final gestaoState = ref.watch(gestaoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Preços'),
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
      body: ListView.builder(
        itemCount: gestaoState.produtos.length,
        itemBuilder: (context, index) {
          final produto = gestaoState.produtos[index];
          return ItemProduto(produto: produto);
        },
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

  void _mostrarDialogoNovoProduto(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Produto'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nome do produto"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNovaCategoria(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Categoria'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nome da categoria"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Salvar'),
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
