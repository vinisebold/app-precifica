part of 'global_toast_controller.dart';

enum ToastVariant { info, success, warning, error }

class ToastAction {
  final String label;
  final VoidCallback onPressed;

  const ToastAction({required this.label, required this.onPressed});
}

class ToastData {
  final String message;
  final ToastVariant variant;
  final ToastAction? action;
  final Duration duration;
  final int timestamp;

  const ToastData({
    required this.message,
    required this.variant,
    required this.duration,
    required this.timestamp,
    this.action,
  });
}

class GlobalToastState {
  final ToastData? toast;
  final bool isVisible;

  const GlobalToastState({required this.toast, required this.isVisible});

  const GlobalToastState.hidden()
      : toast = null,
        isVisible = false;

  GlobalToastState copyWith({ToastData? toast, bool? isVisible}) {
    return GlobalToastState(
      toast: toast ?? this.toast,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
