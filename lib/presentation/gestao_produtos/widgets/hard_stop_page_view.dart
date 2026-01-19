import 'package:flutter/material.dart';

/// Widget de paginação com "hard-stop" durante o drag.
///
/// Diferente do PageView padrão:
/// - Limita o deslocamento a ±1 página durante o drag
/// - Impede ver páginas além da adjacente (sem overshoot)
/// - Snap determinístico após soltar o gesto
/// - Comportamento igual ao Android nativo
///
/// Otimizações de performance:
/// - Usa Transform.translate em vez de Positioned (não causa layout)
/// - Cache de páginas adjacentes para evitar rebuilds
/// - AnimatedBuilder para evitar setState durante animação
/// - RepaintBoundary para isolar repaint de cada página
class HardStopPageView extends StatefulWidget {
  const HardStopPageView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
    this.initialPage = 0,
    this.swipeThreshold = 0.2,
    this.velocityThreshold = 300.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOut,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final void Function(int page)? onPageChanged;
  final int initialPage;
  final double swipeThreshold;
  final double velocityThreshold;
  final Duration animationDuration;
  final Curve animationCurve;

  @override
  State<HardStopPageView> createState() => HardStopPageViewState();
}

class HardStopPageViewState extends State<HardStopPageView>
    with SingleTickerProviderStateMixin {
  late int _currentPage;
  late AnimationController _animationController;
  late Animation<double> _offsetAnimation;

  // ValueNotifier para evitar setState durante drag
  final ValueNotifier<double> _dragOffset = ValueNotifier<double>(0.0);
  double _dragStartX = 0.0;
  bool _isDragging = false;

  // Cache das páginas para evitar rebuilds
  final Map<int, Widget> _pageCache = {};
  int _cacheVersion = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, widget.itemCount - 1);

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _offsetAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ),
    );

    _animationController.addListener(_onAnimationTick);
    _animationController.addStatusListener(_onAnimationStatus);
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationTick);
    _animationController.removeStatusListener(_onAnimationStatus);
    _animationController.dispose();
    _dragOffset.dispose();
    _pageCache.clear();
    super.dispose();
  }

  void _onAnimationTick() {
    _dragOffset.value = _offsetAnimation.value;
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _dragOffset.value = 0.0;
    }
  }

  /// Invalida o cache quando o widget pai muda
  @override
  void didUpdateWidget(HardStopPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _invalidateCache();
    }
  }

  void _invalidateCache() {
    _pageCache.clear();
    _cacheVersion++;
  }

  /// Obtém página do cache ou constrói
  Widget _getPage(BuildContext context, int index) {
    final cacheKey = index + (_cacheVersion * 10000);
    return _pageCache.putIfAbsent(
      cacheKey,
      () => RepaintBoundary(
        child: widget.itemBuilder(context, index),
      ),
    );
  }

  void jumpToPage(int page) {
    if (page < 0 || page >= widget.itemCount) return;
    if (page == _currentPage) return;

    setState(() {
      _currentPage = page;
      _dragOffset.value = 0.0;
      // Limpa cache de páginas distantes
      _trimCache();
    });

    widget.onPageChanged?.call(_currentPage);
  }

  Future<void> animateToPage(int page) async {
    if (page < 0 || page >= widget.itemCount) return;
    if (page == _currentPage) return;
    if (_animationController.isAnimating) return;

    final pageWidth = context.size?.width ?? 0;
    if (pageWidth == 0) {
      jumpToPage(page);
      return;
    }

    final direction = page > _currentPage ? -1.0 : 1.0;
    final targetOffset = direction * pageWidth;

    _offsetAnimation = Tween<double>(
      begin: _dragOffset.value,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    await _animationController.forward(from: 0);

    setState(() {
      _currentPage = page;
      _dragOffset.value = 0.0;
      _trimCache();
    });
    widget.onPageChanged?.call(_currentPage);
  }

  int get page => _currentPage;

  /// Remove páginas distantes do cache
  void _trimCache() {
    _pageCache.removeWhere((key, _) {
      final pageIndex = key % 10000;
      return (pageIndex - _currentPage).abs() > 2;
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _isDragging = true;
    _dragStartX = details.localPosition.dx;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final pageWidth = context.size?.width ?? 1;
    final delta = details.localPosition.dx - _dragStartX;

    double newOffset = delta;

    // Resistência nas bordas
    if (_currentPage == 0 && newOffset > 0) {
      newOffset = newOffset * 0.3;
    }
    if (_currentPage == widget.itemCount - 1 && newOffset < 0) {
      newOffset = newOffset * 0.3;
    }

    newOffset = newOffset.clamp(-pageWidth, pageWidth);
    _dragOffset.value = newOffset;
    _dragStartX = details.localPosition.dx - newOffset;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final pageWidth = context.size?.width ?? 1;
    final velocity = details.velocity.pixelsPerSecond.dx;

    int targetPage = _currentPage;

    if (velocity.abs() > widget.velocityThreshold) {
      if (velocity > 0 && _currentPage > 0) {
        targetPage = _currentPage - 1;
      } else if (velocity < 0 && _currentPage < widget.itemCount - 1) {
        targetPage = _currentPage + 1;
      }
    } else {
      final offsetFraction = _dragOffset.value / pageWidth;
      if (offsetFraction > widget.swipeThreshold && _currentPage > 0) {
        targetPage = _currentPage - 1;
      } else if (offsetFraction < -widget.swipeThreshold &&
          _currentPage < widget.itemCount - 1) {
        targetPage = _currentPage + 1;
      }
    }

    _animateToTarget(targetPage);
  }

  void _animateToTarget(int targetPage) {
    final pageWidth = context.size?.width ?? 1;
    double targetOffset;

    if (targetPage == _currentPage) {
      targetOffset = 0.0;
    } else if (targetPage > _currentPage) {
      targetOffset = -pageWidth;
    } else {
      targetOffset = pageWidth;
    }

    _offsetAnimation = Tween<double>(
      begin: _dragOffset.value,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    _animationController.forward(from: 0).then((_) {
      if (targetPage != _currentPage) {
        setState(() {
          _currentPage = targetPage;
          _dragOffset.value = 0.0;
          _trimCache();
        });
        widget.onPageChanged?.call(_currentPage);
      } else {
        _dragOffset.value = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pageWidth = constraints.maxWidth;
          final pageHeight = constraints.maxHeight;

          // Pré-constrói páginas adjacentes (fora do ValueListenableBuilder)
          final prevPage =
              _currentPage > 0 ? _getPage(context, _currentPage - 1) : null;
          final currentPageWidget = _getPage(context, _currentPage);
          final nextPage = _currentPage < widget.itemCount - 1
              ? _getPage(context, _currentPage + 1)
              : null;

          return ClipRect(
            child: ValueListenableBuilder<double>(
              valueListenable: _dragOffset,
              builder: (context, offset, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Página anterior
                    if (prevPage != null && offset > 0)
                      Transform.translate(
                        offset: Offset(offset - pageWidth, 0),
                        child: SizedBox(
                          width: pageWidth,
                          height: pageHeight,
                          child: prevPage,
                        ),
                      ),

                    // Página atual (sempre visível)
                    Transform.translate(
                      offset: Offset(offset, 0),
                      child: SizedBox(
                        width: pageWidth,
                        height: pageHeight,
                        child: currentPageWidget,
                      ),
                    ),

                    // Próxima página
                    if (nextPage != null && offset < 0)
                      Transform.translate(
                        offset: Offset(offset + pageWidth, 0),
                        child: SizedBox(
                          width: pageWidth,
                          height: pageHeight,
                          child: nextPage,
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
