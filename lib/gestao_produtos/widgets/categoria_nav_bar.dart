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
  // Offset? _revertDragEndOffset; // No longer storing this directly in state, passed to callback

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

  void _completeRevertAnimation() {
    _revertingOverlayEntry?.remove();
    _revertingOverlayEntry = null;
    if (mounted) {
      setState(() {
        // Only set _revertingCategoria to null, other state is managed by the drag lifecycle
        _revertingCategoria = null;
      });
    }
    final notifier = ref.read(gestaoControllerProvider.notifier);
    if (notifier.state.isReordering) {
      notifier.setReordering(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gestaoControllerProvider);
    final categorias = state.categorias;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme; // For use in feedback widget

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
                          transform: isBeingDraggedOver
                              ? Matrix4.translationValues(0, -5, 0)
                              : Matrix4.identity(),
                          child: LongPressDraggable<String>(
                            key: ValueKey(categoria.id), // Use ValueKey for Draggable itself
                            data: categoria.id,
                            onDragStarted: () {
                              _revertingOverlayEntry?.remove();
                              _revertingOverlayEntry = null;
                              _revertAnimationController?.stop();
                              ref.read(gestaoControllerProvider.notifier).setReordering(true);
                              if (mounted) {
                                setState(() {
                                  _revertingCategoria = null; // Clear any previous revert op
                                });
                              }
                            },
                            onDragEnd: (details) {
                              if (details.wasAccepted) {
                                ref.read(gestaoControllerProvider.notifier).setReordering(false);
                              }
                              // If not accepted (cancelled), onDraggableCanceled handles it.
                            },
                            onDraggableCanceled: (velocity, dragOffset) {
                              // Capture necessary data before any async operations or setState
                              final RenderBox? itemRenderBoxAtDragEnd =
                                  itemKey.currentContext?.findRenderObject() as RenderBox?;
                              final Categoria categoriaToRevert = categoria;
                              final GlobalKey keyOfRevertingItem = itemKey;

                              if (itemRenderBoxAtDragEnd == null || !itemRenderBoxAtDragEnd.attached || !mounted) {
                                // Failsafe, complete revert immediately if context is lost
                                _completeRevertAnimation();
                                return;
                              }
                              
                              // Set state to mark this item as reverting (e.g., to hide it in the list)
                              setState(() {
                                _revertingCategoria = categoriaToRevert;
                              });

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted || _revertingCategoria != categoriaToRevert) {
                                  // State changed, or widget disposed, abort animation
                                  // If it was meant for this item, ensure it's fully cleaned up.
                                  if (_revertingCategoria == null || _revertingCategoria == categoriaToRevert) {
                                     _completeRevertAnimation();
                                  }
                                  return;
                                }

                                final RenderBox? itemRenderBoxForTarget =
                                    keyOfRevertingItem.currentContext?.findRenderObject() as RenderBox?;

                                if (itemRenderBoxForTarget == null || !itemRenderBoxForTarget.attached) {
                                   _completeRevertAnimation(); // Target disappeared
                                  return;
                                }
                                final Offset targetPosition = itemRenderBoxForTarget.localToGlobal(Offset.zero);

                                final Widget animationFeedbackWidget = Material(
                                  color: Colors.transparent,
                                  child: Transform.scale(
                                    scale: 1.0, // Start at normal scale for animation
                                    child: Container(
                                      width: itemRenderBoxForTarget.size.width,
                                      height: itemRenderBoxForTarget.size.height,
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer.withOpacity(0.85), // Visually distinct
                                        borderRadius: BorderRadius.circular(20.0),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.label, color: colorScheme.onSecondaryContainer, size: 20),
                                          const SizedBox(height: 4),
                                          Text(
                                            categoriaToRevert.nome,
                                            style: textTheme.labelLarge?.copyWith(color: colorScheme.onSecondaryContainer),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
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
                                
                                if(mounted && Overlay.of(context) != null){
                                   Overlay.of(context).insert(_revertingOverlayEntry!);
                                   _revertAnimationController!.forward(from: 0.0);
                                } else {
                                  // If overlay context is lost, cleanup
                                  _completeRevertAnimation();
                                }
                              });
                            },
                            feedback: Material(
                              color: Colors.transparent,
                              elevation: 4.0,
                              shape: const CircleBorder(),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primaryContainer.withOpacity(0.85),
                                ),
                                child: Center(
                                  child: Icon(Icons.label, color: colorScheme.onPrimaryContainer, size: 32),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.0,
                              child: _CategoriaItem(
                                key: itemKey, // Original item uses its key
                                categoria: categoria,
                                isSelected: state.categoriaSelecionadaId == categoria.id,
                                onTap: () {},
                              ),
                            ),
                            child: Opacity(
                              opacity: (_revertingCategoria?.id == categoria.id) ? 0.0 : 1.0,
                              child: _CategoriaItem(
                                key: itemKey, // Original item uses its key
                                categoria: categoria,
                                isSelected: state.categoriaSelecionadaId == categoria.id,
                                onTap: () {
                                  if (!state.isReordering) {
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

  const _CategoriaItem({
    super.key, // Pass the key to the super constructor
    required this.categoria,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoriaItem> createState() => _CategoriaItemState();
}

class _CategoriaItemState extends State<_CategoriaItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color pillColor;
    if (widget.isSelected) {
      pillColor = colorScheme.secondaryContainer;
    } else if (_isHovering) {
      pillColor = colorScheme.onSurface.withOpacity(0.08);
    } else {
      pillColor = Colors.transparent;
    }

    Color contentColor;
    if (widget.isSelected) {
      contentColor = colorScheme.onSecondaryContainer;
    } else {
      contentColor = colorScheme.onSurfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20.0),
          hoverColor: Colors.transparent,
          splashColor: colorScheme.onSurface.withOpacity(0.12),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(20.0),
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
