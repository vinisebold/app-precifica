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
    // Removed diagnostic print from here

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
      floatingActionButton: _StatefulFab(
        onPressed: gestaoState.categoriaSelecionadaId != null
            ? () => _mostrarDialogoNovoProduto(context, ref)
            : null,
        icon: const Icon(Icons.add_shopping_cart),
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
                  ? colorScheme.errorContainer.withAlpha((255 * 0.9).round())
                  : colorScheme.errorContainer.withAlpha((255 * 0.7).round()),
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

  void _mostrarDialogoNovoProduto(BuildContext pageContext, WidgetRef ref) {
    print("Attempting to show Novo Produto dialog"); // KEEPING THIS FOR NOW
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

// Stateful FAB for hover and press effects
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
      fabBackgroundColor = colorScheme.onSurface.withAlpha((255 * 0.12).round());
      fabForegroundColor = colorScheme.onSurface.withAlpha((255 * 0.38).round());
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
          // The main action is now directly on FloatingActionButton's onPressed
          // This GestureDetector's onTapUp only handles the visual press state change
          if (mounted && isEnabled) {
            setState(() => _isPressed = false);
            // widget.onPressed?.call(); // No longer called here
          }
        },
        onTapCancel: () {
          if (mounted && isEnabled) setState(() => _isPressed = false);
        },
        child: FloatingActionButton(
          onPressed: widget.onPressed, // Directly use the passed onPressed callback
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
