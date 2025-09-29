import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'global_toast_controller.dart';

class GlobalToastHost extends ConsumerWidget {
  final Widget child;

  const GlobalToastHost({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toastState = ref.watch(globalToastControllerProvider);
    final toast = toastState.toast;
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width * 0.75;
    const fabHeight = 112.0;
    const toastHeight = _ToastCardState.toastHeight;
    final baseBottomPadding = math.max(16.0, mediaQuery.padding.bottom + 16.0);
    final toastBottom =
        baseBottomPadding + math.max(0.0, fabHeight - toastHeight);

    return Stack(
      children: [
        child,
        if (toast != null)
          Positioned(
            left: 16,
            bottom: toastBottom,
            child: IgnorePointer(
              ignoring: !toastState.isVisible,
              child: _ToastCard(
                toast: toast,
                isVisible: toastState.isVisible,
                width: width,
              ),
            ),
          ),
      ],
    );
  }
}

class _ToastCard extends ConsumerStatefulWidget {
  final ToastData toast;
  final bool isVisible;
  final double width;

  const _ToastCard({
    required this.toast,
    required this.isVisible,
    required this.width,
  });

  @override
  ConsumerState<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends ConsumerState<_ToastCard>
    with SingleTickerProviderStateMixin {
  static const double toastHeight = 56.0;
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _slideAnimation =
        Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _ToastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reverse();
    } else if (widget.toast.timestamp != oldWidget.toast.timestamp) {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visuals =
        _ToastVisuals.fromVariant(widget.toast.variant, colorScheme);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(position: _slideAnimation, child: child),
        );
      },
      child: Material(
        elevation: visuals.elevation,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        color: visuals.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.width,
            maxHeight: toastHeight,
          ),
          child: SizedBox(
            height: toastHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DefaultTextStyle(
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: visuals.foreground, height: 1.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.toast.message,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.toast.action != null) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: visuals.actionForeground,
                          textStyle:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    letterSpacing: 0.6,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        onPressed: () {
                          ref
                              .read(globalToastControllerProvider.notifier)
                              .triggerAction();
                        },
                        child: Text(
                          widget.toast.action!.label.toUpperCase(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastVisuals {
  final Color background;
  final Color foreground;
  final double elevation;
  final Color actionForeground;

  const _ToastVisuals({
    required this.background,
    required this.foreground,
    required this.elevation,
    required this.actionForeground,
  });

  factory _ToastVisuals.fromVariant(
    ToastVariant variant,
    ColorScheme scheme,
  ) {
    const baseElevation = 3.0;

    switch (variant) {
      case ToastVariant.success:
        return _ToastVisuals(
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          elevation: baseElevation,
          actionForeground: scheme.primary,
        );
      case ToastVariant.warning:
        return _ToastVisuals(
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
          elevation: baseElevation,
          actionForeground: scheme.tertiary,
        );
      case ToastVariant.error:
        return _ToastVisuals(
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
          elevation: baseElevation,
          actionForeground: scheme.error,
        );
      case ToastVariant.info:
        return _ToastVisuals(
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
          elevation: baseElevation,
          actionForeground: scheme.primary,
        );
    }
  }
}
