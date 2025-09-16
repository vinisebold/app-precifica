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

class _CategoriaNavBarState extends ConsumerState<CategoriaNavBar>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  OverlayEntry? _revertingOverlayEntry;
  AnimationController? _revertAnimationController;
  Animation<Offset>? _revertAnimation;
  Categoria? _revertingCategoria; // The category currently in the revert animation

  final Map<String, GlobalKey> _itemKeys = {};

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
    super.dispose();
  }

  void _updateArrowVisibility() {
    if (!_scrollController.hasClients ||
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
  }

  void _completeRevertAnimation() {
    _revertingOverlayEntry?.remove();
    _revertingOverlayEntry = null;
    if (mounted) {
      setState(() {
        _revertingCategoria = null;
      });
    }
    // Unconditionally set reordering to false on animation completion
    ref.read(gestaoControllerProvider.notifier).setReordering(false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gestaoControllerProvider);
    final categorias = state.categorias;
    final colorScheme = Theme.of(context).colorScheme;
    // textTheme removed as it was unused here

    for (var cat in categorias) {
      _itemKeys.putIfAbsent(cat.id, () => GlobalKey());
    }

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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                              _revertingOverlayEntry?.remove();
                              _revertingOverlayEntry = null;
                              _revertAnimationController?.stop();
                              ref.read(gestaoControllerProvider.notifier).setReordering(true);
                              if (mounted) {
                                setState(() {
                                  _revertingCategoria = null;
                                });
                              }
                            },
                            onDragEnd: (details) {
                              if (details.wasAccepted) {
                                ref.read(gestaoControllerProvider.notifier).setReordering(false);
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
                                if (!mounted || _revertingCategoria != categoriaToRevert) {
                                  if (_revertingCategoria == null || _revertingCategoria == categoriaToRevert) {
                                     _completeRevertAnimation();
                                  }
                                  return;
                                }

                                final RenderBox? itemRenderBoxForTarget =
                                    keyOfRevertingItem.currentContext?.findRenderObject() as RenderBox?;

                                if (itemRenderBoxForTarget == null || !itemRenderBoxForTarget.attached) {
                                   _completeRevertAnimation();
                                  return;
                                }
                                final Offset targetPosition = itemRenderBoxForTarget.localToGlobal(Offset.zero);

                                final Widget animationFeedbackWidget = Material(
                                  color: Colors.transparent,
                                  shadowColor: Colors.black.withAlpha((255 * 0.075).round()), // Consistent shadow for animation
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
                                  child: Transform.scale(
                                    scale: 1.0,
                                    child: _CategoriaItem(
                                      categoria: categoriaToRevert,
                                      isSelected: true, 
                                      onTap: () {},
                                      isDragFeedback: true,
                                    ),
                                  ),
                                );

                                _revertAnimationController?.stop();
                                _revertAnimation = Tween<Offset>(begin: dragOffset, end: targetPosition)
                                    .animate(CurvedAnimation(
                                      parent: _revertAnimationController!,
                                      curve: Curves.easeOutCubic,
                                    ));

                                _revertingOverlayEntry?.remove();
                                _revertingOverlayEntry = OverlayEntry(builder: (context) {
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
                                
                                // Removed 'Overlay.of(context) != null' check as per lint
                                if(mounted){
                                   Overlay.of(context).insert(_revertingOverlayEntry!);
                                   _revertAnimationController!.forward(from: 0.0);
                                } else {
                                  _completeRevertAnimation();
                                }
                              });
                            },
                            feedback: Material(
                              color: Colors.transparent,
                              elevation: 2.0, 
                              shadowColor: Colors.black.withAlpha((255 * 0.075).round()), // Reduced shadow opacity
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28.0), 
                              ),
                              child: _CategoriaItem(
                                categoria: categoria,
                                isSelected: true, 
                                onTap: () {},
                                isDragFeedback: true,
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.0,
                              child: _CategoriaItem(
                                key: itemKey,
                                categoria: categoria,
                                isSelected: state.categoriaSelecionadaId == categoria.id,
                                onTap: () {},
                              ),
                            ),
                            child: Opacity(
                              opacity: (_revertingCategoria?.id == categoria.id) ? 0.0 : 1.0,
                              child: _CategoriaItem(
                                key: itemKey,
                                categoria: categoria,
                                isSelected: state.categoriaSelecionadaId == categoria.id,
                                onTap: () {
                                  // Check !state.isReordering before selecting to prevent selection during animation
                                  if (!ref.read(gestaoControllerProvider).isReordering) {
                                    ref.read(gestaoControllerProvider.notifier).selecionarCategoria(categoria.id);
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onWillAcceptWithDetails: (details) => details.data != categoria.id,
                      onAcceptWithDetails: (details) {
                        ref.read(gestaoControllerProvider.notifier).reordenarCategoria(details.data, categoria.id);
                      },
                    );
                  }).toList(),
                ),
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
      child: InkWell(
        onTap: !isVisible
            ? null
            : () {
                final screenWidth = MediaQuery.of(context).size.width;
                final scrollAmount = screenWidth * 0.7;
                final newOffset = (isLeft
                        ? max(0.0, _scrollController.offset - scrollAmount)
                        : min(_scrollController.position.maxScrollExtent, _scrollController.offset + scrollAmount))
                    .toDouble();
                _scrollController.animateTo(newOffset, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
              },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(isLeft ? Icons.chevron_left : Icons.chevron_right, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _CategoriaItem extends StatefulWidget {
  final Categoria categoria;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDragFeedback; 

  const _CategoriaItem({
    super.key,
    required this.categoria,
    required this.isSelected,
    required this.onTap,
    this.isDragFeedback = false,
  });

  @override
  State<_CategoriaItem> createState() => _CategoriaItemState();
}

class _CategoriaItemState extends State<_CategoriaItem> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme; // textTheme is used here

    if (widget.isDragFeedback) {
      final pillColor = colorScheme.secondaryContainer;
      final contentColor = colorScheme.onSecondaryContainer;
      final borderRadius = BorderRadius.circular(28.0); 

      return Padding( 
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Container( 
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: pillColor,
            borderRadius: borderRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.label, color: contentColor, size: 20),
              const SizedBox(height: 4),
              Text(
                widget.categoria.nome,
                style: textTheme.labelLarge?.copyWith(color: contentColor),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      );
    } else {
      Color pillColor;
      if (widget.isSelected) {
        pillColor = colorScheme.secondaryContainer;
      } else if (_isHovering) {
        pillColor = colorScheme.onSurface.withAlpha((255 * 0.08).round());
      } else {
        pillColor = Colors.transparent;
      }

      Color contentColor;
      if (widget.isSelected) {
        contentColor = colorScheme.onSecondaryContainer;
      } else {
        contentColor = colorScheme.onSurfaceVariant;
      }

      final BorderRadius borderRadius = BorderRadius.circular(
        (widget.isSelected && _isPressed) ? 28.0 : 20.0,
      );

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (isHighlighted) {
              if (mounted) {
                setState(() {
                  _isPressed = isHighlighted;
                });
              }
            },
            borderRadius: borderRadius,
            hoverColor: Colors.transparent,
            splashColor: colorScheme.onSurface.withAlpha((255 * 0.12).round()),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: borderRadius,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.isSelected ? Icons.label : Icons.label_outline, color: contentColor, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    widget.categoria.nome,
                    style: textTheme.labelLarge?.copyWith(color: contentColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
