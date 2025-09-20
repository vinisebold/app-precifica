import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:precifica/data/models/produto.dart';
import 'package:precifica/gestao_produtos/gestao_controller.dart';
import 'package:precifica/gestao_produtos/widgets/categoria_nav_bar.dart';
import 'package:precifica/gestao_produtos/widgets/product_list_view.dart';
import 'package:share_plus/share_plus.dart';

class GestaoPage extends ConsumerStatefulWidget {
  const GestaoPage({super.key});

  @override
  ConsumerState<GestaoPage> createState() => _GestaoPageState();
}

class _GestaoPageState extends ConsumerState<GestaoPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final selectedId =
        ref.read(gestaoControllerProvider).categoriaSelecionadaId;
    final categorias = ref.read(gestaoControllerProvider).categorias;
    final initialPage = selectedId != null
        ? categorias.indexWhere((c) => c.id == selectedId)
        : 0;
    _pageController =
        PageController(initialPage: initialPage > -1 ? initialPage : 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showCustomToast(
      BuildContext context,
      String message, {
        Color? backgroundColor,
        Color? textColor,
        Widget? action,
      }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;

        return Positioned(
          bottom: 96,
          left: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: screenWidth * 0.72,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: backgroundColor ??
                    Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: textColor ??
                            Theme.of(context).colorScheme.onInverseSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: 12),
                    action,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 5), () {
      overlayEntry.remove();
    });
  }

  void _mostrarDialogoEditarNome(
      BuildContext context,
      WidgetRef ref, {
        required String titulo,
        required String valorAtual,
        required Function(String) onSalvar,
      }) {
    final controller = TextEditingController(text: valorAtual);
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo, style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Novo nome"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar', style: textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () {
              final novoNome = controller.text;
              if (novoNome.isNotEmpty) {
                onSalvar(novoNome);
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text('Salvar', style: textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<GestaoState>(
      gestaoControllerProvider,
          (previousState, newState) {
        if (newState.errorMessage != null &&
            newState.errorMessage != previousState?.errorMessage) {
          _showCustomToast(
            context,
            newState.errorMessage!,
            backgroundColor: colorScheme.errorContainer,
            textColor: colorScheme.onErrorContainer,
          );
          ref.read(gestaoControllerProvider.notifier).clearError();
        }

        if (newState.ultimoProdutoDeletado != null &&
            newState.ultimoProdutoDeletado !=
                previousState?.ultimoProdutoDeletado) {
          final produtoDeletado = newState.ultimoProdutoDeletado!;
          _showCustomToast(
            context,
            '${produtoDeletado.nome} deletado',
            backgroundColor: colorScheme.secondary,
            textColor: colorScheme.onSecondary,
            action: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref
                    .read(gestaoControllerProvider.notifier)
                    .desfazerDeletarProduto();
              },
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSecondary,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('DESFAZER'),
            ),
          );
        }

        if (previousState?.categoriaSelecionadaId !=
            newState.categoriaSelecionadaId) {
          final newIndex = newState.categorias
              .indexWhere((c) => c.id == newState.categoriaSelecionadaId);
          if (newIndex != -1 && _pageController.page?.round() != newIndex) {
            _pageController.animateToPage(
              newIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      },
    );

    final gestaoState = ref.watch(gestaoControllerProvider);
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text('Gestão de Preços', style: textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              HapticFeedback.lightImpact();
              final textoRelatorio = gestaoNotifier.gerarTextoRelatorio();
              Share.share(textoRelatorio);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              HapticFeedback.lightImpact();
              _mostrarDialogoNovaCategoria(context, ref);
            },
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Stack(
            children: [
              // OTIMIZAÇÃO APLICADA AQUI
              RepaintBoundary(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: gestaoState.categorias.length,
                  onPageChanged: (index) {
                    gestaoNotifier.selecionarCategoriaPorIndice(index);
                  },
                  itemBuilder: (context, index) {
                    return ProductListView(
                      categoriaId: gestaoState.categorias[index].id,
                      onProdutoDoubleTap: (produto) {
                        _mostrarDialogoEditarNome(
                          context,
                          ref,
                          titulo: "Editar Produto",
                          valorAtual: produto.nome,
                          onSalvar: (novoNome) {
                            gestaoNotifier.atualizarNomeProduto(
                                produto.id, novoNome);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              if (gestaoState.isReordering) _buildDeleteArea(context, ref),
              if (gestaoState.isDraggingProduto)
                _buildProdutoDeleteArea(context, ref),
              if (gestaoState.isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CategoriaNavBar(
            onCategoriaDoubleTap: (categoria) {
              _mostrarDialogoEditarNome(
                context,
                ref,
                titulo: "Editar Categoria",
                valorAtual: categoria.nome,
                onSalvar: (novoNome) {
                  gestaoNotifier.atualizarNomeCategoria(categoria.id, novoNome);
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: gestaoState.categoriaSelecionadaId != null
            ? () {
          HapticFeedback.lightImpact();
          _mostrarDialogoNovoProduto(context, ref);
        }
            : null,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Widget _buildProdutoDeleteArea(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: DragTarget<Produto>(
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isHovering ? 120 : 100,
            decoration: BoxDecoration(
              color: isHovering
                  ? colorScheme.errorContainer.withAlpha(230)
                  : colorScheme.errorContainer.withAlpha(180),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(60)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline,
                    color: colorScheme.onErrorContainer, size: 32),
                const SizedBox(height: 8),
                Text('Arraste o produto aqui para apagar',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onErrorContainer)),
              ],
            ),
          );
        },
        onAcceptWithDetails: (details) {
          HapticFeedback.lightImpact();
          ref
              .read(gestaoControllerProvider.notifier)
              .deletarProduto(details.data.id);
        },
      ),
    );
  }

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
                  ? colorScheme.errorContainer.withAlpha(230)
                  : colorScheme.errorContainer.withAlpha(180),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(60)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline,
                    color: colorScheme.onErrorContainer, size: 32),
                const SizedBox(height: 8),
                Text('Arraste aqui para apagar',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onErrorContainer)),
              ],
            ),
          );
        },
        onAcceptWithDetails: (details) {
          HapticFeedback.lightImpact();
          ref
              .read(gestaoControllerProvider.notifier)
              .deletarCategoria(details.data);
        },
      ),
    );
  }

  void _mostrarDialogoNovoProduto(BuildContext pageContext, WidgetRef ref) {
    final controller = TextEditingController();
    final textTheme = Theme.of(pageContext).textTheme;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Novo Produto', style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nome do produto"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar', style: textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              final nomeProduto = controller.text;
              if (nomeProduto.isNotEmpty) {
                ref
                    .read(gestaoControllerProvider.notifier)
                    .criarProduto(nomeProduto);
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text('Salvar', style: textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNovaCategoria(BuildContext pageContext, WidgetRef ref) {
    final controller = TextEditingController();
    final textTheme = Theme.of(pageContext).textTheme;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Nova Categoria', style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nome da categoria"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: Text('Cancelar', style: textTheme.labelLarge),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text('Salvar', style: textTheme.labelLarge),
            onPressed: () {
              HapticFeedback.lightImpact();
              final nomeCategoria = controller.text;
              if (nomeCategoria.isNotEmpty) {
                ref
                    .read(gestaoControllerProvider.notifier)
                    .criarCategoria(nomeCategoria);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}