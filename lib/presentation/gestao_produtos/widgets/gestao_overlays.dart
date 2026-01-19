import 'dart:async' show Timer;
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:precifica/app/core/l10n/app_localizations.dart';

import '../mixins/spotlight_mixin.dart';

/// Guia visual de gesto de swipe para o tutorial.
class SwipeGestureGuide extends StatefulWidget {
  const SwipeGestureGuide({super.key});

  @override
  State<SwipeGestureGuide> createState() => _SwipeGestureGuideState();
}

class _SwipeGestureGuideState extends State<SwipeGestureGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _offsetAnimation = Tween<double>(begin: -28, end: 28).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IgnorePointer(
      child: SizedBox(
        width: 160,
        height: 120,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_offsetAnimation.value, 0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Icon(
              Icons.swipe,
              size: 56,
              color: colorScheme.primary,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay com spotlight (buraco) que destaca uma área específica.
class SpotlightFadeOverlay extends StatelessWidget {
  const SpotlightFadeOverlay({
    super.key,
    required this.rect,
    required this.visible,
    required this.borderRadius,
    required this.overlayColor,
    this.padding = EdgeInsets.zero,
  });

  final Rect? rect;
  final bool visible;
  final double borderRadius;
  final Color overlayColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final targetRect = rect;
    if (targetRect == null) {
      return const SizedBox.shrink();
    }

    final paddedRect = Rect.fromLTRB(
      targetRect.left - padding.left,
      targetRect.top - padding.top,
      targetRect.right + padding.right,
      targetRect.bottom + padding.bottom,
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey<Rect>(paddedRect),
      tween: Tween<double>(begin: 0, end: visible ? 1 : 0),
      duration: SpotlightMixin.spotlightFadeDuration,
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        if (opacity <= 0.001) {
          return const SizedBox.shrink();
        }

        return SizedBox.expand(
          child: CustomPaint(
            painter: _SpotlightPainter(
              rect: paddedRect,
              radius: borderRadius,
              color: overlayColor,
              opacity: opacity,
            ),
          ),
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.rect,
    required this.radius,
    required this.color,
    required this.opacity,
  });

  final Rect rect;
  final double radius;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveOpacity = (color.a * opacity).clamp(0.0, 1.0).toDouble();
    if (effectiveOpacity <= 0.0) return;

    final overlayPaint = Paint()
      ..color = color.withValues(alpha: effectiveOpacity)
      ..style = PaintingStyle.fill;

    final screenPath = Path()..addRect(Offset.zero & size);
    final spotlightPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final overlayPath = Path.combine(
      PathOperation.difference,
      screenPath,
      spotlightPath,
    );

    canvas.drawPath(overlayPath, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return rect != oldDelegate.rect ||
        radius != oldDelegate.radius ||
        color != oldDelegate.color ||
        opacity != oldDelegate.opacity;
  }
}

/// Overlay global de processamento com animação de glow.
class GlobalProcessingOverlay extends StatefulWidget {
  final bool active;

  const GlobalProcessingOverlay({super.key, required this.active});

  @override
  State<GlobalProcessingOverlay> createState() =>
      _GlobalProcessingOverlayState();
}

class _GlobalProcessingOverlayState extends State<GlobalProcessingOverlay>
    with TickerProviderStateMixin {
  List<String> _getMessages(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      l10n?.aiProcessing1 ?? 'Organizando os itens para você...',
      l10n?.aiProcessing2 ?? 'Analisando categorias e agrupamentos...',
      l10n?.aiProcessing3 ?? 'Separando os itens com carinho...',
      l10n?.aiProcessing4 ?? 'Quase pronto! Ajustando os últimos detalhes...',
    ];
  }

  late Timer _timer;
  int _currentMessageIndex = 0;
  late AnimationController _glowController;
  late AnimationController _visibilityController;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % 4;
      });
    });
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 260),
    );
    if (widget.active) {
      _visibilityController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _glowController.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GlobalProcessingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final overlayOpacity =
        Theme.of(context).brightness == Brightness.light ? 0.1 : 0.02;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _visibilityController,
        builder: (context, _) {
          final v = Curves.easeInOut.transform(_visibilityController.value);
          if (v == 0) return const SizedBox.shrink();
          return IgnorePointer(
            ignoring: v < 0.05,
            child: Opacity(
              opacity: v,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 12,
                          sigmaY: 12,
                        ),
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _GlowBackdropPainter(
                                progress: _glowController.value,
                                colorScheme: colorScheme,
                              ),
                              child: Container(
                                color: Colors.black
                                    .withValues(alpha: overlayOpacity * v),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: _visibilityController,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: Opacity(
                              key: ValueKey('${_currentMessageIndex}_$v'),
                              opacity: v.clamp(0, 1),
                              child: Text(
                                _getMessages(context)[_currentMessageIndex],
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.15,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.25 * v),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Opacity(
                            opacity: (v * 0.95).clamp(0, 1),
                            child: Text(
                              AppLocalizations.of(context)
                                      ?.aiProcessingSubtitle ??
                                  'Nossa IA está cuidando de tudo, só um instante.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.9 * v),
                                shadows: [
                                  Shadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.2 * v),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlowBackdropPainter extends CustomPainter {
  final double progress;
  final ColorScheme colorScheme;

  _GlowBackdropPainter({required this.progress, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final paints = <_GlowSpec>[
      _GlowSpec(
        baseOffset: const Offset(0.18, 0.22),
        radiusFactor: 0.65,
        hueShift: 0.0,
        speed: 0.9,
        intensity: 0.38,
      ),
      _GlowSpec(
        baseOffset: const Offset(0.88, 0.78),
        radiusFactor: 0.80,
        hueShift: 0.07,
        speed: 0.55,
        intensity: 0.30,
      ),
      _GlowSpec(
        baseOffset: const Offset(0.78, 0.20),
        radiusFactor: 0.55,
        hueShift: -0.05,
        speed: 1.25,
        intensity: 0.25,
      ),
    ];

    for (final spec in paints) {
      final localT = (progress * spec.speed) % 1.0;
      final wobbleX = math.sin(localT * math.pi * 2) * 0.04;
      final wobbleY = math.cos(localT * math.pi * 2) * 0.04;
      final center = Offset(
        (spec.baseOffset.dx + wobbleX) * size.width,
        (spec.baseOffset.dy + wobbleY) * size.height,
      );
      final radius = spec.radiusFactor * size.shortestSide;
      final gradient = RadialGradient(
        colors: [
          _tint(colorScheme.primary, spec.hueShift)
              .withValues(alpha: spec.intensity * 0.50),
          _tint(colorScheme.primaryContainer, spec.hueShift)
              .withValues(alpha: spec.intensity * 0.22),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      );
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }
  }

  Color _tint(Color base, double shift) {
    if (shift == 0) return base;
    final hsl = HSLColor.fromColor(base);
    final shifted = hsl.withHue((hsl.hue + shift * 360) % 360);
    return shifted.toColor();
  }

  @override
  bool shouldRepaint(covariant _GlowBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colorScheme != colorScheme;
}

class _GlowSpec {
  final Offset baseOffset;
  final double radiusFactor;
  final double hueShift;
  final double speed;
  final double intensity;
  _GlowSpec({
    required this.baseOffset,
    required this.radiusFactor,
    required this.hueShift,
    required this.speed,
    required this.intensity,
  });
}
