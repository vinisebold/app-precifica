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
    final gestaoState = ref.watch(gestaoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Preços'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 3. Chamar a função do controller para pegar o texto...
              final textoRelatorio = ref.read(gestaoControllerProvider.notifier).gerarTextoRelatorio();
              // 4. ...e usar o pacote Share para mostrá-lo.
              Share.share(textoRelatorio);
            },
          ),
          // Botão para adicionar NOVAS CATEGORIAS
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _mostrarDialogoNovaCategoria(context, ref),
          ),
        ],
      ),
      // O corpo agora exibe a lista de produtos da categoria selecionada
      body: ListView.builder(
        itemCount: gestaoState.produtos.length,
        itemBuilder: (context, index) {
          final produto = gestaoState.produtos[index];
          return ItemProduto(produto: produto);
        },
      ),
      // Nosso novo widget de navegação de categorias
      bottomNavigationBar: const CategoriaNavBar(),
      // O botão flutuante agora adiciona NOVOS PRODUTOS
      floatingActionButton: FloatingActionButton(
        onPressed: gestaoState.categoriaSelecionadaId != null
            ? () => _mostrarDialogoNovoProduto(context, ref)
            : null, // Desabilita o botão se nenhuma categoria existe
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  // Diálogo para CRIAR PRODUTO
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
                ref.read(gestaoControllerProvider.notifier).criarProduto(nomeProduto);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para CRIAR CATEGORIA (o mesmo de antes, mas chamado de outro lugar)
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
                ref.read(gestaoControllerProvider.notifier).criarCategoria(nomeCategoria);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}