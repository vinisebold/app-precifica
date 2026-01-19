import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/showcase/tutorial_keys.dart';

/// Mixin que encapsula a lógica de spotlight/highlight para o tutorial.
mixin SpotlightMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  static const Duration spotlightFadeDuration = Duration(milliseconds: 220);

  Rect? _navigationSpotlightRect;
  bool _navigationSpotlightUpdateScheduled = false;
  Timer? _navigationSpotlightClearTimer;

  Rect? _swipeSpotlightRect;
  bool _swipeSpotlightUpdateScheduled = false;
  Timer? _swipeSpotlightClearTimer;

  Rect? get navigationSpotlightRect => _navigationSpotlightRect;
  Rect? get swipeSpotlightRect => _swipeSpotlightRect;

  void disposeSpotlight() {
    _navigationSpotlightClearTimer?.cancel();
    _swipeSpotlightClearTimer?.cancel();
  }

  void scheduleNavigationSpotlightUpdate() {
    _navigationSpotlightClearTimer?.cancel();
    _navigationSpotlightClearTimer = null;
    if (_navigationSpotlightUpdateScheduled) return;
    _navigationSpotlightUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationSpotlightUpdateScheduled = false;
      if (!mounted) return;

      final navContext = TutorialKeys.categoryNavBar.currentContext;
      final overlayRenderBox = context.findRenderObject() as RenderBox?;
      final navRenderBox = navContext != null
          ? navContext.findRenderObject() as RenderBox?
          : null;

      if (overlayRenderBox == null ||
          navRenderBox == null ||
          !navRenderBox.attached) {
        return;
      }

      final offset =
          navRenderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
      final rect = offset & navRenderBox.size;

      if (_navigationSpotlightRect != rect) {
        setState(() => _navigationSpotlightRect = rect);
      }
    });
  }

  void clearNavigationSpotlightRect() {
    if (_navigationSpotlightRect == null ||
        _navigationSpotlightClearTimer != null) {
      return;
    }

    _navigationSpotlightClearTimer = Timer(spotlightFadeDuration, () {
      if (!mounted) return;
      _navigationSpotlightClearTimer = null;
      if (_navigationSpotlightRect != null) {
        setState(() => _navigationSpotlightRect = null);
      }
    });
  }

  void scheduleSwipeSpotlightUpdate() {
    _swipeSpotlightClearTimer?.cancel();
    _swipeSpotlightClearTimer = null;
    if (_swipeSpotlightUpdateScheduled) return;
    _swipeSpotlightUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _swipeSpotlightUpdateScheduled = false;
      if (!mounted) return;

      final swipeContext = TutorialKeys.categorySwipeArea.currentContext;
      final overlayRenderBox = context.findRenderObject() as RenderBox?;
      final swipeRenderBox = swipeContext != null
          ? swipeContext.findRenderObject() as RenderBox?
          : null;

      if (overlayRenderBox == null ||
          swipeRenderBox == null ||
          !swipeRenderBox.attached) {
        return;
      }

      final offset =
          swipeRenderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
      final rect = offset & swipeRenderBox.size;

      if (_swipeSpotlightRect != rect) {
        setState(() => _swipeSpotlightRect = rect);
      }
    });
  }

  void clearSwipeSpotlightRect() {
    if (_swipeSpotlightRect == null || _swipeSpotlightClearTimer != null) {
      return;
    }

    _swipeSpotlightClearTimer = Timer(spotlightFadeDuration, () {
      if (!mounted) return;
      _swipeSpotlightClearTimer = null;
      if (_swipeSpotlightRect != null) {
        setState(() => _swipeSpotlightRect = null);
      }
    });
  }
}
