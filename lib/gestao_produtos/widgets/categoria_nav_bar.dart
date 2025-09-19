import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/data/models/categoria.dart';
import 'package:organiza_ae/gestao_produtos/gestao_controller.dart';

class CategoriaNavBar extends ConsumerStatefulWidget {
  final Function(Categoria) onCategoriaDoubleTap;

  const CategoriaNavBar({required this.onCategoriaDoubleTap, super.key});

  @override
  ConsumerState<CategoriaNavBar> createState() => _CategoriaNavBarState();
}

class _CategoriaNavBarState extends ConsumerState<CategoriaNavBar>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  OverlayEntry? _revertingOverlayEntry;
  AnimationController? _revertAnimationController;
  Animation<Offset>? _revertAnimation;
  Categoria? _revertingCategoria;

  final Map<String, GlobalKey> _itemKeys = {};
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrowVisibility);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateArrowVisibility());
    _revertAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completeRevertAnimation();
        }
      });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateArrowVisibility);
    _scrollController.dispose();
    _revertAnimationController?.dispose();
    _revertingOverlayEntry?.remove();
    _revertingOverlayEntry = null;
    _scrollDebounce?.cancel();
    super.dispose();
  }

  void _updateArrowVisibility() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
      if (!mounted ||
          !_scrollController.hasClients ||
          !_scrollController.position.hasContentDimensions) {
        return;
      }
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      const tolerance = 1.0;
      if (!mounted) return;
      setState(() {
        _showLeftArrow = currentScroll > tolerance;
        _showRightArrow = currentScroll < maxScroll - tolerance;
      });
    });
  }

  void _completeRevertAnimation() {
    _revertingOverlayEntry?.remove();
    _revertingOverlayEntry = null;
    if (mounted) {
      setState(() {
        _revertingCategoria = null;
      });
    }
    ref.read(gestaoControllerProvider.notifier).setReordering(false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gestaoControllerProvider);
    final categorias = state.categorias;
    final colorScheme = Theme.of(context).colorScheme;

    for (var cat in categorias) {
      _itemKeys.putIfAbsent(cat.id, () => GlobalKey());
    }
    _itemKeys
        .removeWhere((key, value) => !categorias.any((cat) => cat.id == key));

    if (categorias.isEmpty) {
      return const SizedBox(height: 48);
    }

    return Container(
      height: 48,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: categorias.map((categoria) {
                  final itemKey = _itemKeys[categoria.id]!;
                  return DragTarget<String>(
                    builder: (context, candidateData, rejectedData) {
                      final isBeingDraggedOver = candidateData.isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        transform: isBeingDraggedOver
                            ? Matrix4.translationValues(0, -5, 0)
                            : Matrix4.identity(),
                        child: LongPressDraggable<String>(
                          key: ValueKey(categoria.id),
                          data: categoria.id,
                          onDragStarted: () {
                            HapticFeedback.lightImpact();
                            _revertingOverlayEntry?.remove();
                            _revertingOverlayEntry = null;
                            _revertAnimationController?.stop();
                            ref
                                .read(gestaoControllerProvider.notifier)
                                .setReordering(true);
                            if (mounted) {
                              setState(() {
                                _revertingCategoria = null;
                              });
                            }
                          },
                          onDragEnd: (details) {
                            if (details.wasAccepted) {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(gestaoControllerProvider.notifier)
                                  .setReordering(false);
                            }
                          },
                          onDraggableCanceled: (velocity, dragOffset) {
                            final Categoria categoriaToRevert = categoria;
                            final GlobalKey keyOfRevertingItem = itemKey;

                            if (!mounted) {
                              _completeRevertAnimation();
                              return;
                            }

                            setState(() {
                              _revertingCategoria = categoriaToRevert;
                            });

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted ||
                                  _revertingCategoria != categoriaToRevert) {
                                if (_revertingCategoria == null ||
                                    _revertingCategoria == categoriaToRevert) {
                                  _completeRevertAnimation();
                                }
                                return;
                              }

                              final RenderBox? itemRenderBoxForTarget =
                                  keyOfRevertingItem.currentContext
                                      ?.findRenderObject() as RenderBox?;

                              if (itemRenderBoxForTarget == null ||
                                  !itemRenderBoxForTarget.attached) {
                                _completeRevertAnimation();
                                return;
                              }
                              final Offset targetPosition =
                                  itemRenderBoxForTarget
                                      .localToGlobal(Offset.zero);

                              final Widget animationFeedbackWidget = Material(
                                color: Colors.transparent,
                                shadowColor: Colors.black
                                    .withAlpha((255 * 0.075).round()),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28.0)),
                                child: Transform.scale(
                                  scale: 1.0,
                                  child: _CategoriaItem(
                                    categoria: categoriaToRevert,
                                    isSelected: true,
                                    onTap: () {},
                                    onDoubleTap: () {},
                                    isDragFeedback: true,
                                  ),
                                ),
                              );

                              _revertAnimationController?.stop();
                              _revertAnimation = Tween<Offset>(
                                      begin: dragOffset, end: targetPosition)
                                  .animate(CurvedAnimation(
                                parent: _revertAnimationController!,
                                curve: Curves.easeOutCubic,
                              ));

                              _revertingOverlayEntry?.remove();
                              _revertingOverlayEntry =
                                  OverlayEntry(builder: (context) {
                                return AnimatedBuilder(
                                  animation: _revertAnimation!,
                                  builder: (context, child) {
                                    return Positioned(
                                      left: _revertAnimation!.value.dx,
                                      top: _revertAnimation!.value.dy,
                                      child: child!,
                                    );
                                  },
                                  child: animationFeedbackWidget,
                                );
                              });

                              if (mounted) {
                                Overlay.of(context)
                                    .insert(_revertingOverlayEntry!);
                                _revertAnimationController!.forward(from: 0.0);
                              } else {
                                _completeRevertAnimation();
                              }
                            });
                          },
                          feedback: Material(
                            color: Colors.transparent,
                            elevation: 2.0,
                            shadowColor:
                                Colors.black.withAlpha((255 * 0.075).round()),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.0),
                            ),
                            child: _CategoriaItem(
                              categoria: categoria,
                              isSelected: true,
                              onTap: () {},
                              onDoubleTap: () {},
                              isDragFeedback: true,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.0,
                            child: _CategoriaItem(
                              key: itemKey,
                              categoria: categoria,
                              isSelected:
                                  state.categoriaSelecionadaId == categoria.id,
                              onTap: () {},
                              onDoubleTap: () {},
                            ),
                          ),
                          child: Opacity(
                            opacity: (_revertingCategoria?.id == categoria.id)
                                ? 0.0
                                : 1.0,
                            child: _CategoriaItem(
                              key: itemKey,
                              categoria: categoria,
                              isSelected:
                                  state.categoriaSelecionadaId == categoria.id,
                              onTap: () {
                                if (!ref
                                    .read(gestaoControllerProvider)
                                    .isReordering) {
                                  ref
                                      .read(gestaoControllerProvider.notifier)
                                      .selecionarCategoria(categoria.id);
                                }
                              },
                              onDoubleTap: () {
                                if (!ref
                                    .read(gestaoControllerProvider)
                                    .isReordering) {
                                  widget.onCategoriaDoubleTap(categoria);
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    onWillAcceptWithDetails: (details) =>
                        details.data != categoria.id,
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
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _showLeftArrow ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                child: Container(
                  width: 48.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        colorScheme.surfaceContainerLow,
                        colorScheme.surfaceContainerLow.withAlpha(0),
                      ],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _showRightArrow ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                child: Container(
                  width: 48.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        colorScheme.surfaceContainerLow,
                        colorScheme.surfaceContainerLow.withAlpha(0),
                      ],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildArrow(isLeft: true),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _buildArrow(isLeft: false),
          ),
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
      child: InkWell(
        onTap: !isVisible
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(isLeft ? Icons.chevron_left : Icons.chevron_right,
              color: colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _CategoriaItem extends StatefulWidget {
  final Categoria categoria;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final bool isDragFeedback;

  const _CategoriaItem({
    super.key,
    required this.categoria,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    this.isDragFeedback = false,
  });

  @override
  State<_CategoriaItem> createState() => _CategoriaItemState();
}

class _CategoriaItemState extends State<_CategoriaItem> {
  bool _isActivated = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = widget.isSelected;
    const duration = Duration(milliseconds: 200);

    // Raio do canto, muda com o toque do utilizador
    final double cornerRadius = _isActivated ? 28.0 : 50.0;

    // Este é o visual do item enquanto ele está a ser arrastado pela tela.
    if (widget.isDragFeedback) {
      final pillColor = colorScheme.secondaryContainer;
      final contentColor = colorScheme.onSecondaryContainer;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(50.0), // Aumenta o raio
        ),
        child: Center(
          child: Text(
            widget.categoria.nome,
            style: textTheme.labelLarge?.copyWith(color: contentColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      );
    }

    // Cor de fundo do item: selecionado ou transparente
    final Color pillColor =
        isSelected ? colorScheme.secondaryContainer : Colors.transparent;

    // Cor do texto do item: uma para selecionado, outra para o estado normal
    final Color contentColor = isSelected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    // O padding horizontal aumenta quando o item é selecionado
    final double horizontalPadding = isSelected ? 24.0 : 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onTapDown: (_) => setState(() => _isActivated = true),
        onTapUp: (_) => setState(() => _isActivated = false),
        onTapCancel: () => setState(() => _isActivated = false),
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOut,
          // Ajuste no padding vertical para compensar a ausência do ícone.
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: 12.0),
          decoration: BoxDecoration(
            color: pillColor,
            border: Border.all(
              color: _isActivated && !isSelected
                  ? colorScheme.onSurface.withValues(alpha: 0.12)
                  : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          child: Center(
            child: Text(
              widget.categoria.nome,
              style: textTheme.labelLarge?.copyWith(color: contentColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
