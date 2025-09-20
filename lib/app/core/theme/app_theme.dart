import 'package:flutter/material.dart';

/// Uma classe para centralizar as configurações de tema do aplicativo.
class AppTheme {
  // Impede que esta classe seja instanciada.
  AppTheme._();

  // Define a cor principal que será usada para gerar os esquemas de cores.
  static const _seedColor = Colors.green;

  /// Retorna o ThemeData para o modo claro.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: const OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      inputDecorationTheme: inputTheme,
    );
  }

  /// Retorna o ThemeData para o modo escuro.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: const OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      inputDecorationTheme: inputTheme,
    );
  }
}
