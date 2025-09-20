import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

// Importando as entidades do domínio
import '../../domain/entities/produto.dart';

// Importando o controller e o state da camada de apresentação
import 'gestao_controller.dart';
import 'gestao_state.dart';

// Importando os widgets da camada de apresentação
import 'widgets/categoria_nav_bar.dart';
import 'widgets/product_list_view.dart';

class GestaoPage extends ConsumerStatefulWidget {
  const GestaoPage({super.key});

  @override
  ConsumerState<GestaoPage> createState() => _GestaoPageState();
}

class _GestaoPageState extends ConsumerState<GestaoPage> {
  late PageController _pageController;
  OverlayEntry? _currentToastOverlayEntry; // Guarda a referência do toast atual

  @override
  void initState() {
    super.initState();
    // Acessa o estado inicial para configurar o PageController
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
    _currentToastOverlayEntry
        ?.remove(); // Garante a remoção do toast ao sair da página
    super.dispose();
  }

  OverlayEntry? _showCustomToast(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Widget? action,
    Duration duration = const Duration(seconds: 5),
  }) {
    _currentToastOverlayEntry?.remove();
    _currentToastOverlayEntry = null;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

        return Positioned(
          bottom: bottomPadding > 0 ? bottomPadding + 16 : 96,
          left: 16,
          width: screenWidth * 0.75, // Ocupa 75% da largura da tela
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (action != null) action,
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    _currentToastOverlayEntry = overlayEntry;

    if (duration != Duration.zero) {
      Future.delayed(duration, () {
        if (overlayEntry == _currentToastOverlayEntry && overlayEntry.mounted) {
          overlayEntry.remove();
          if (_currentToastOverlayEntry == overlayEntry) {
            _currentToastOverlayEntry = null;
          }
        }
      });
    }
    return overlayEntry;
  }

  void _removeCurrentToast() {
    _currentToastOverlayEntry?.remove();
    _currentToastOverlayEntry = null;
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
            backgroundColor: colorScheme.inverseSurface,
            textColor: colorScheme.onInverseSurface,
            action: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _removeCurrentToast();
                ref
                    .read(gestaoControllerProvider.notifier)
                    .desfazerDeletarProduto();
              },
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
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
            _pageController.jumpToPage(newIndex);
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
          ref.read(gestaoControllerProvider.notifier).setDraggingProduto(false);
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
          final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
          gestaoNotifier.deletarCategoria(details.data);
          gestaoNotifier.setReordering(false);
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
