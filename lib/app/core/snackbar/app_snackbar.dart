import 'package:flutter/material.dart';

/// Classe utilitária para exibir SnackBars padronizadas no aplicativo.
class AppSnackbar {
  // Impede que esta classe seja instanciada.
  AppSnackbar._();

  /// Exibe uma SnackBar de sucesso.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      message,
      duration: duration,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      textColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  /// Exibe uma SnackBar de erro.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message,
      duration: duration,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      textColor: Theme.of(context).colorScheme.onErrorContainer,
    );
  }

  /// Exibe uma SnackBar de informação.
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      message,
      duration: duration,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      textColor: Theme.of(context).colorScheme.onSecondaryContainer,
    );
  }

  /// Exibe uma SnackBar de aviso/warning.
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message,
      duration: duration,
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      textColor: Theme.of(context).colorScheme.onTertiaryContainer,
      action: action,
    );
  }

  /// Exibe uma SnackBar padrão com mensagem simples.
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message,
      duration: duration,
      action: action,
    );
  }

  /// Método interno para exibir a SnackBar.
  static void _show(
    BuildContext context,
    String message, {
    required Duration duration,
    Color? backgroundColor,
    Color? textColor,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: textColor != null ? TextStyle(color: textColor) : null,
          ),
          duration: duration,
          backgroundColor: backgroundColor,
          action: action,
        ),
      );
  }
}
