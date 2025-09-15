import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/data/models/categoria.dart';
import 'package:organiza_ae/gestao_produtos/gestao_controller.dart';

class CategoriaNavBar extends ConsumerStatefulWidget {
  const CategoriaNavBar({super.key});

  @override
  ConsumerState<CategoriaNavBar> createState() => _CategoriaNavBarState();
}

class _CategoriaNavBarState extends ConsumerState<CategoriaNavBar> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrowVisibility);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateArrowVisibility());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateArrowVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateArrowVisibility() {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Usamos uma pequena tolerância para evitar que a seta "pisque" no final do scroll
    const tolerance = 1.0;
    setState(() {
      _showLeftArrow = currentScroll > tolerance;
      _showRightArrow = currentScroll < maxScroll - tolerance;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gestaoControllerProvider);
    final categorias = state.categorias;
    final colorScheme = Theme.of(context).colorScheme;

    if (categorias.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 80,
      color: colorScheme.surfaceContainer,
      child: Row(
        children: [
          _buildArrow(isLeft: true),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              // Efeito "esticar" nas bordas
              child: Row(
                children: categorias.map((categoria) {
                  final isSelected =
                      state.categoriaSelecionadaId == categoria.id;
                  return _CategoriaItem(
                    categoria: categoria,
                    isSelected: isSelected,
                    onTap: () => ref
                        .read(gestaoControllerProvider.notifier)
                        .selecionarCategoria(categoria.id),
                    onLongPress: () => _mostrarDialogoDeletar(
                        context, ref, categoria.id, categoria.nome),
                  );
                }).toList(),
              ),
            ),
          ),
          _buildArrow(isLeft: false),
        ],
      ),
    );
  }

  // A "CÁPSULA" DA SETA, TOTALMENTE REFATORADA
  Widget _buildArrow({required bool isLeft}) {
    final bool isVisible = isLeft ? _showLeftArrow : _showRightArrow;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      // Anima a largura para a seta deslizar suavemente para dentro e fora da tela
      width: isVisible ? 56 : 0,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            // O DEGRADÊ SUTIL E TRANSLÚCIDO
            gradient: LinearGradient(
              colors: [
                colorScheme.surfaceContainer.withAlpha(200),
                colorScheme.surfaceContainer.withAlpha(100),
              ],
              begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            ),
            borderRadius:
                BorderRadius.circular(100), // Bordas totalmente arredondadas
          ),
          child: IconButton(
            icon: Icon(isLeft ? Icons.chevron_left : Icons.chevron_right),
            onPressed: () {
              final screenWidth = MediaQuery.of(context).size.width;
              final scrollAmount = screenWidth * 0.7;
              final newOffset = (isLeft
                      ? max(0.0, _scrollController.offset - scrollAmount)
                      : min(_scrollController.position.maxScrollExtent,
                          _scrollController.offset + scrollAmount))
                  .toDouble();
              _scrollController.animateTo(newOffset,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut);
            },
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoDeletar(BuildContext context, WidgetRef ref,
      String categoriaId, String nomeCategoria) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(/*...*/)); // Sem alterações aqui
  }
}

class _CategoriaItem extends StatelessWidget {
  // CORREÇÃO BÔNUS: Troquei 'dynamic' por 'Categoria' para mais segurança de tipo
  final Categoria categoria;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CategoriaItem({
    required this.categoria,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? Icons.label : Icons.label_outline,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              categoria.nome,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
