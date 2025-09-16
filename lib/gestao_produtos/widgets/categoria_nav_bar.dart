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
    const tolerance = 1.0;
    if (!mounted) return;
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
              child: Row(
                children: categorias.map((categoria) {
                  return DragTarget<String>(
                    builder: (context, candidateData, rejectedData) {
                      return LongPressDraggable<String>(
                        data: categoria.id,
                        onDragStarted: () => ref
                            .read(gestaoControllerProvider.notifier)
                            .setReordering(true),
                        onDragEnd: (_) => ref
                            .read(gestaoControllerProvider.notifier)
                            .setReordering(false),
                        feedback: Material(
                          color: Colors.transparent,
                          child: _CategoriaItem(
                            categoria: categoria,
                            isSelected: false,
                            onTap: () {},
                          ),
                        ),
                        child: _CategoriaItem(
                          categoria: categoria,
                          isSelected:
                          state.categoriaSelecionadaId == categoria.id,
                          onTap: () {
                            if (!state.isReordering) {
                              ref
                                  .read(gestaoControllerProvider.notifier)
                                  .selecionarCategoria(categoria.id);
                            }
                          },
                        ),
                      );
                    },
                    onWillAcceptWithDetails: (details) {
                      return details.data != categoria.id;
                    },
                    onAcceptWithDetails: (details) {
                      ref
                          .read(gestaoControllerProvider.notifier)
                          .reordenarCategoria(details.data, categoria.id);
                    },
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

  Widget _buildArrow({required bool isLeft}) {
    final bool isVisible = isLeft ? _showLeftArrow : _showRightArrow;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IconButton(
        icon: Icon(isLeft ? Icons.chevron_left : Icons.chevron_right),
        onPressed: !isVisible
            ? null
            : () {
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
    );
  }
}

class _CategoriaItem extends StatelessWidget {
  final Categoria categoria;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoriaItem({
    required this.categoria,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
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