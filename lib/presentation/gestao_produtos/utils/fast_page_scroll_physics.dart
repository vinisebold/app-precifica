import 'package:flutter/material.dart';

/// Physics customizada para PageView com snap rápido estilo Android.
///
/// Baseado no Flutter GitHub Issue #38357:
/// - A animação padrão do PageView é muito lenta comparada ao Android
/// - A solução é usar ClampingScrollPhysics + simulação rápida
///
/// Referências:
/// - https://github.com/flutter/flutter/issues/38357
/// - https://github.com/flutter/flutter/pull/95423
class FastPageScrollPhysics extends ScrollPhysics {
  /// Velocidade mínima para considerar um "fling" que muda de página
  final double velocityThreshold;

  const FastPageScrollPhysics({
    super.parent,
    this.velocityThreshold = 365.0,
  });

  @override
  FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPageScrollPhysics(
      parent: buildParent(ancestor),
      velocityThreshold: velocityThreshold,
    );
  }

  // Clamping nas bordas - comportamento Android (sem bounce iOS)
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.minScrollExtent) {
      return value - position.minScrollExtent;
    }
    if (value > position.maxScrollExtent) {
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    final target = _getTargetPixels(position, velocity);
    final distance = target - position.pixels;

    // Se já está no target, não precisa animar
    if (distance.abs() < tolerance.distance) {
      return null;
    }

    // Simulação rápida estilo Android
    return _FastSnapSimulation(
      start: position.pixels,
      end: target,
      tolerance: tolerance,
    );
  }

  double _getTargetPixels(ScrollMetrics position, double velocity) {
    final pageWidth = position.viewportDimension;
    if (pageWidth == 0) return position.pixels;

    double page = position.pixels / pageWidth;

    // Lógica de snap baseada na velocidade
    if (velocity.abs() > velocityThreshold) {
      page = velocity > 0 ? page.ceilToDouble() : page.floorToDouble();
    } else {
      page = page.roundToDouble();
    }

    // Clamp para limites válidos
    final maxPage = (position.maxScrollExtent / pageWidth).floorToDouble();
    page = page.clamp(0.0, maxPage);

    return page * pageWidth;
  }
}

/// Simulação de snap rápida estilo Android.
///
/// Baseado na sugestão do milesegan no issue #38357:
/// - Duração curta (Durations.short4 = 200ms)
/// - Curva easeOut para desaceleração natural
/// - Sem overshoot
class _FastSnapSimulation extends Simulation {
  _FastSnapSimulation({
    required this.start,
    required this.end,
    required super.tolerance,
  }) {
    // Duração FIXA e CURTA como no Android nativo
    // Durations.short4 = 200ms - igual à sugestão do milesegan
    _duration = 0.20; // 200ms fixo - rápido como Android
  }

  final double start;
  final double end;
  late final double _duration;

  /// Curva easeOut como sugerido no issue #38357
  /// f(t) = 1 - (1-t)^2 - quadrática para ser mais rápida
  double _easeOut(double t) {
    final t1 = 1.0 - t;
    return 1.0 - (t1 * t1);
  }

  /// Derivada da easeOut quadrática: f'(t) = 2 * (1-t)
  double _easeOutDerivative(double t) {
    return 2.0 * (1.0 - t);
  }

  @override
  double x(double time) {
    if (time >= _duration) return end;
    final t = (time / _duration).clamp(0.0, 1.0);
    return start + (end - start) * _easeOut(t);
  }

  @override
  double dx(double time) {
    if (time >= _duration) return 0.0;
    final t = (time / _duration).clamp(0.0, 1.0);
    return ((end - start) / _duration) * _easeOutDerivative(t);
  }

  @override
  bool isDone(double time) => time >= _duration;
}

/// PageController customizado com animações rápidas estilo Android.
///
/// Baseado na solução do milesegan no issue #38357:
/// https://github.com/flutter/flutter/issues/38357#issuecomment-2384020193
///
/// Use este controller junto com FastPageScrollPhysics para
/// ter comportamento consistente tanto no swipe quanto no tap.
class FastPageController extends PageController {
  FastPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction,
  });

  @override
  Future<void> animateToPage(
    int page, {
    required Duration duration,
    required Curve curve,
  }) {
    // Ignora os parâmetros e usa valores rápidos estilo Android
    return super.animateToPage(
      page,
      duration: const Duration(milliseconds: 200), // Durations.short4
      curve: Curves.easeOut,
    );
  }

  @override
  Future<void> nextPage({required Duration duration, required Curve curve}) {
    return super.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Future<void> previousPage({
    required Duration duration,
    required Curve curve,
  }) {
    return super.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}
