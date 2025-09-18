// lib/gestao_produtos/gestao_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/data/models/produto.dart'; // NOVO: Importe o modelo Produto
import 'package:organiza_ae/gestao_produtos/gestao_controller.dart';
import 'package:organiza_ae/gestao_produtos/widgets/categoria_nav_bar.dart';
import 'package:organiza_ae/gestao_produtos/widgets/product_list_view.dart';
import 'package:share_plus/share_plus.dart';

class GestaoPage extends ConsumerWidget {
  const GestaoPage({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
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
      },
    );

    final gestaoState = ref.watch(gestaoControllerProvider);
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
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
              ProductListView(
                onProdutoDoubleTap: (produto) {
                  _mostrarDialogoEditarNome(
                    context,
                    ref,
                    titulo: "Editar Produto",
                    valorAtual: produto.nome,
                    onSalvar: (novoNome) {
                      gestaoNotifier.atualizarNomeProduto(produto.id, novoNome);
                    },
                  );
                },
              ),
              if (gestaoState.isReordering) _buildDeleteArea(context, ref),
              // NOVO: Adicione estas linhas para mostrar a área de exclusão do produto
              if (gestaoState.isDraggingProduto)
                _buildProdutoDeleteArea(context, ref),
              if (gestaoState.isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
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
      floatingActionButton: _StatefulFab(
        onPressed: gestaoState.categoriaSelecionadaId != null
            ? () {
          HapticFeedback.lightImpact();
          _mostrarDialogoNovoProduto(context, ref);
        }
            : null,
        icon: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  // NOVO: Adicione todo este método
  Widget _buildProdutoDeleteArea(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Positioned(
      top: 0, // A área de exclusão para produtos ficará no topo
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

class _StatefulFab extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;

  const _StatefulFab({this.onPressed, required this.icon});

  @override
  State<_StatefulFab> createState() => _StatefulFabState();
}

class _StatefulFabState extends State<_StatefulFab> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final bool showSquircle = isEnabled && (_isHovered || _isPressed);
    final ShapeBorder currentShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(showSquircle ? 16.0 : 28.0),
      side: BorderSide.none,
    );

    Color fabBackgroundColor;
    Color fabForegroundColor;

    if (isEnabled) {
      fabBackgroundColor = colorScheme.primaryContainer;
      fabForegroundColor = colorScheme.onPrimaryContainer;
    } else {
      fabBackgroundColor =
          colorScheme.onSurface.withAlpha(30);
      fabForegroundColor =
          colorScheme.onSurface.withAlpha(97);
    }

    const double currentElevation = 0.0;

    return MouseRegion(
      onEnter: (_) {
        if (mounted && isEnabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted && isEnabled) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (mounted && isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (mounted && isEnabled) {
            setState(() => _isPressed = false);
          }
        },
        onTapCancel: () {
          if (mounted && isEnabled) setState(() => _isPressed = false);
        },
        child: FloatingActionButton(
          onPressed: widget.onPressed,
          backgroundColor: fabBackgroundColor,
          foregroundColor: fabForegroundColor,
          shape: currentShape,
          elevation: currentElevation,
          hoverElevation: currentElevation,
          focusElevation: currentElevation,
          highlightElevation: currentElevation,
          child: widget.icon,
        ),
      ),
    );
  }
}