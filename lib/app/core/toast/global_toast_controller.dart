import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'toast_models.dart';

final globalToastControllerProvider =
    NotifierProvider<GlobalToastController, GlobalToastState>(
  GlobalToastController.new,
);

class GlobalToastController extends Notifier<GlobalToastState> {
  GlobalToastController();

  @override
  GlobalToastState build() {
    ref.onDispose(() {
      _dismissTimer?.cancel();
      _cleanupTimer?.cancel();
    });
    return const GlobalToastState.hidden();
  }

  Timer? _dismissTimer;
  Timer? _cleanupTimer;

  void show(
    String message, {
    ToastVariant variant = ToastVariant.info,
    Duration duration = const Duration(seconds: 4),
    ToastAction? action,
  }) {
    _dismissTimer?.cancel();
    _cleanupTimer?.cancel();

    final toast = ToastData(
      message: message.trim(),
      variant: variant,
      action: action,
      duration: duration,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(toast: toast, isVisible: true);

    if (duration > Duration.zero) {
      _dismissTimer = Timer(duration, hide);
    }
  }

  void showInfo(String message,
      {Duration duration = const Duration(seconds: 4)}) {
    show(message, variant: ToastVariant.info, duration: duration);
  }

  void showSuccess(String message,
      {Duration duration = const Duration(seconds: 4)}) {
    show(message, variant: ToastVariant.success, duration: duration);
  }

  void showWarning(String message,
      {Duration duration = const Duration(seconds: 5), ToastAction? action}) {
    show(message,
        variant: ToastVariant.warning, duration: duration, action: action);
  }

  void showError(String message,
      {Duration duration = const Duration(seconds: 6), ToastAction? action}) {
    show(message,
        variant: ToastVariant.error, duration: duration, action: action);
  }

  void hide() {
    if (!state.isVisible) {
      return;
    }

    _dismissTimer?.cancel();
    state = state.copyWith(isVisible: false);

    _cleanupTimer = Timer(const Duration(milliseconds: 280), () {
      state = state.copyWith(toast: null);
    });
  }

  void clearQueue() {
    _dismissTimer?.cancel();
    _cleanupTimer?.cancel();
    state = state.copyWith(toast: null, isVisible: false);
  }

  void triggerAction() {
    final action = state.toast?.action;
    if (action == null) {
      return;
    }

    action.onPressed();
    hide();
  }
}
