import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:precificador/domain/entities/categoria.dart';
import '../gestao_controller.dart';

class CategoriaNavBar extends ConsumerStatefulWidget {
  final Function(Categoria) onCategoriaDoubleTap;

  const CategoriaNavBar({required this.onCategoriaDoubleTap, super.key});

  @override
  ConsumerState<CategoriaNavBar> createState() => _CategoriaNavBarState();
}

class _CategoriaNavBarState extends ConsumerState<CategoriaNavBar> {
  final ScrollController _scrollController = ScrollController();

  OverlayEntry? _revertingOverlayEntry;
  Categoria? _revertingCategoria;

  final Map<String, GlobalKey> _itemKeys = {};
  Timer? _scrollDebounce;

  final Map<String, double> _scales = {};
  final Map<String, double> _opacities = {};
  final Map<String, double> _rotations = {};

  double _leftPadding = 0.0;
  double _rightPadding = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => _calculateVisuals());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _calculateVisuals();
        final initialSelectedId =
            ref.read(gestaoControllerProvider).categoriaSelecionadaId;
        if (initialSelectedId != null) {
          _ensureCategoryIsVisible(initialSelectedId, jump: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => _calculateVisuals());
    });
    _scrollController.dispose();
    _revertingOverlayEntry?.remove();
    _revertingOverlayEntry = null;
    _scrollDebounce?.cancel();
    super.dispose();
  }

  void _ensureCategoryIsVisible(String categoriaId, {bool jump = false}) {
    if (!_scrollController.hasClients || _itemKeys[categoriaId] == null) {
      return;
    }

    final GlobalKey? itemKey = _itemKeys[categoriaId];
    final BuildContext? itemContext = itemKey?.currentContext;

    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        alignment: 0.5,
        duration: jump ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateVisuals();
        }
      });
    }
  }

  void _revertDragAnimation(
      Categoria categoria, GlobalKey itemKey, Offset dragEndOffset) {
    final RenderBox? itemRenderBox =
        itemKey.currentContext?.findRenderObject() as RenderBox?;
    if (itemRenderBox == null || !itemRenderBox.attached) return;

    final Offset targetPosition = itemRenderBox.localToGlobal(Offset.zero);
    final size = itemRenderBox.size;

    final dragEndTop = dragEndOffset.dy;
    final dragEndLeft = dragEndOffset.dx;
    final targetTop = targetPosition.dy;
    final targetLeft = targetPosition.dx;

    bool isAnimationStarted = false;

    _revertingOverlayEntry?.remove();
    _revertingOverlayEntry = null;

    _revertingOverlayEntry = OverlayEntry(builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!isAnimationStarted) {
              setState(() => isAnimationStarted = true);
            }
          });

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            top: isAnimationStarted ? targetTop : dragEndTop,
            left: isAnimationStarted ? targetLeft : dragEndLeft,
            width: size.width,
            height: size.height,
            onEnd: () {
              if (mounted && _revertingCategoria?.id == categoria.id) {
                _revertingOverlayEntry?.remove();
                _revertingOverlayEntry = null;
                this.setState(() {
                  _revertingCategoria = null;
                });
                ref
                    .read(gestaoControllerProvider.notifier)
                    .setReordering(false);
              }
            },
            child: Material(
              color: Colors.transparent,
              elevation: 2.0,
              shadowColor: Colors.black.withAlpha((255 * 0.075).round()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28.0),
              ),
              child: _CategoriaItem(
                categoria: categoria,
                isSelected: true,
                // Feedback is always 'selected' looking
                onTap: () {},
                // No action on tap for feedback
                onDoubleTap: () {},
                // No action on double tap for feedback
                isDragFeedback: true,
              ),
            ),
          );
        },
      );
    });

    setState(() {
      _revertingCategoria = categoria;
    });
    Overlay.of(context).insert(_revertingOverlayEntry!);
  }

  void _calculateVisuals() {
    if (!mounted || !_scrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final viewportCenter = screenWidth / 2;
    final state = ref.read(gestaoControllerProvider);
    final categorias = state.categorias;

    Map<String, double> newScales = {};
    Map<String, double> newOpacities = {};
    Map<String, double> newRotations = {};

    for (var categoria in categorias) {
      final key = _itemKeys[categoria.id];
      final box = key?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        newScales[categoria.id] = 0.7;
        newOpacities[categoria.id] = 0.6;
        newRotations[categoria.id] = 0.0;
        continue;
      }

      final position = box.localToGlobal(Offset.zero);
      final itemCenter = position.dx + box.size.width / 2;
      final signedDistance = itemCenter - viewportCenter;
      final distance = signedDistance.abs();

      final maxDistance = screenWidth / 1.5; // Ajuste para o alcance do efeito
      final factor =
          (maxDistance - distance.clamp(0, maxDistance)) / maxDistance;

      final scale = 0.7 + 0.5 * factor; // min 0.7, max 1.2
      final opacity = 0.6 + 0.4 * factor; // min 0.6, max 1.0
      final rotation =
          signedDistance / screenWidth * 0.3; // Rotação máxima ~17 graus

      newScales[categoria.id] = scale;
      newOpacities[categoria.id] = opacity;
      newRotations[categoria.id] = rotation;
    }

    double newLeftPadding = (screenWidth / 2) - 48.0; // Fallback
    double newRightPadding = (screenWidth / 2) - 48.0; // Fallback

    if (categorias.isNotEmpty) {
      final firstCategoria = categorias.first;
      final lastCategoria = categorias.last;

      final firstKey = _itemKeys[firstCategoria.id];
      final lastKey = _itemKeys[lastCategoria.id];

      final firstBox =
          firstKey?.currentContext?.findRenderObject() as RenderBox?;
      final lastBox = lastKey?.currentContext?.findRenderObject() as RenderBox?;

      if (firstBox != null &&
          firstBox.hasSize &&
          lastBox != null &&
          lastBox.hasSize) {
        final halfFirstWidth = firstBox.size.width / 2;
        final halfLastWidth = lastBox.size.width / 2;

        newLeftPadding = (screenWidth / 2) - 8.0 - halfFirstWidth;
        newRightPadding = (screenWidth / 2) - 8.0 - halfLastWidth;
      }
    }

    _leftPadding = newLeftPadding;
    _rightPadding = newRightPadding;

    setState(() {
      _scales.clear();
      _scales.addAll(newScales);
      _opacities.clear();
      _opacities.addAll(newOpacities);
      _rotations.clear();
      _rotations.addAll(newRotations);
    });
  }

  void _selectClosest() {
    if (!mounted || !_scrollController.hasClients) return;

    final viewportWidth = MediaQuery.of(context).size.width;
    final viewportCenter = viewportWidth / 2;
    final state = ref.read(gestaoControllerProvider);
    final categorias = state.categorias;

    String? closestId;
    double minDistance = double.infinity;

    for (var categoria in categorias) {
      final key = _itemKeys[categoria.id];
      final box = key?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;

      final position = box.localToGlobal(Offset.zero);
      final itemCenter = position.dx + box.size.width / 2;
      final distance = (itemCenter - viewportCenter).abs();

      if (distance < minDistance) {
        minDistance = distance;
        closestId = categoria.id;
      }
    }

    if (closestId != null && closestId != state.categoriaSelecionadaId) {
      ref
          .read(gestaoControllerProvider.notifier)
          .selecionarCategoria(closestId);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      gestaoControllerProvider.select((state) => state.categoriaSelecionadaId),
      (previousSelectedId, newSelectedId) {
        if (newSelectedId != null && newSelectedId != previousSelectedId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _ensureCategoryIsVisible(newSelectedId, jump: false);
            }
          });
        }
      },
    );

    final state = ref.watch(gestaoControllerProvider);
    final categorias = state.categorias;

    if (categorias.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateVisuals();
        }
      });
    }

    for (var cat in categorias) {
      _itemKeys.putIfAbsent(cat.id, () => GlobalKey());
    }
    _itemKeys
        .removeWhere((key, value) => !categorias.any((cat) => cat.id == key));

    if (categorias.isEmpty) return const SizedBox(height: 28);

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      color: Colors.transparent,
      clipBehavior: Clip.none,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            _selectClosest();
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Padding(
            padding: EdgeInsets.only(
              left: _leftPadding,
              right: _rightPadding,
            ),
            child: Row(
              children: categorias.map((categoria) {
                final itemKey = _itemKeys[categoria.id]!;
                final scale = _scales[categoria.id] ?? 1.0;
                final opacity = _opacities[categoria.id] ?? 1.0;
                final rotation = _rotations[categoria.id] ?? 0.0;
                return DragTarget<String>(
                  builder: (context, candidateData, rejectedData) {
                    final isBeingDraggedOver = candidateData.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      transform: isBeingDraggedOver
                          ? Matrix4.translationValues(
                              0, -5, 0) // Efeito visual ao arrastar sobre
                          : Matrix4.identity(),
                      child: LongPressDraggable<String>(
                        key: ValueKey(categoria.id),
                        data: categoria.id,
                        onDragStarted: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(gestaoControllerProvider.notifier)
                              .setReordering(true);
                        },
                        onDragEnd: (details) {
                          if (!details.wasAccepted) {
                            ref
                                .read(gestaoControllerProvider.notifier)
                                .setReordering(false);
                          }
                        },
                        onDraggableCanceled: (velocity, dragOffset) {
                          _revertDragAnimation(categoria, itemKey, dragOffset);
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
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.002)
                              ..rotateY(rotation),
                            child: Transform.scale(
                              scale: scale,
                              alignment: Alignment.center,
                              child: Opacity(
                                opacity: opacity,
                                child: _CategoriaItem(
                                  key: itemKey,
                                  categoria: categoria,
                                  isSelected: state.categoriaSelecionadaId ==
                                      categoria.id,
                                  onTap: () {
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
                          ),
                        ),
                      ),
                    );
                  },
                  onWillAcceptWithDetails: (details) =>
                      details.data != categoria.id,
                  onAcceptWithDetails: (details) {
                    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
                    gestaoNotifier.reordenarCategoria(details.data, categoria.id);
                    gestaoNotifier.setReordering(false);
                  },
                );
              }).toList(),
            ),
          ),
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
    final double cornerRadius = _isActivated ? 16.0 : 28.0;
    if (widget.isDragFeedback) {
      final pillColor = colorScheme.secondaryContainer;
      final contentColor = colorScheme.onSecondaryContainer;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius:
              BorderRadius.circular(28.0),
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

    final Color pillColor =
        isSelected ? colorScheme.secondaryContainer : Colors.transparent;
    final Color contentColor = isSelected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;
    final double horizontalPadding = isSelected ? 24.0 : 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
  onTapDown: (_) => setState(() => _isActivated = true),
  onTapUp: (_) => setState(() => _isActivated = false),
  onTapCancel: () => setState(() => _isActivated = false),
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: 12.0),
          decoration: BoxDecoration(
            color: pillColor,
            border: Border.all(
              // Borda sutil para estado ativado não selecionado
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
