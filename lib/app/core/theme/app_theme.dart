import 'package:flutter/material.dart';

/// Uma classe para centralizar as configurações de tema do aplicativo.
class AppTheme {
  // Impede que esta classe seja instanciada.
  AppTheme._();

  // Define a cor principal que será usada para gerar os esquemas de cores.
  static const _seedColor = Colors.green;

  // Cores de alto contraste para acessibilidade (WCAG AAA - ratio 7:1)
  static const _highContrastPrimaryLight = Color(0xFF006400); // Dark green
  static const _highContrastPrimaryDark = Color(0xFF90EE90); // Light green

  /// Helper para criar InputDecorationTheme consistente
  static InputDecorationTheme _createInputTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: const OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  /// Retorna o ThemeData para o modo claro.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      inputDecorationTheme: _createInputTheme(colorScheme),
    );
  }

  /// Retorna o ThemeData para o modo escuro.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      inputDecorationTheme: _createInputTheme(colorScheme),
    );
  }

  /// Retorna o ThemeData para modo alto contraste claro.
  /// Usa cores com ratio de contraste mínimo de 7:1 (WCAG AAA).
  static ThemeData get highContrastLightTheme {
    const colorScheme = ColorScheme.highContrastLight(
      primary: _highContrastPrimaryLight,
      secondary: Color(0xFF004D40), // Teal escuro
      error: Color(0xFFB00020), // Vermelho alto contraste
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline, width: 2),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 3),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
      ),
      // Aumenta espessura de bordas e indicadores visuais
      dividerTheme: DividerThemeData(
        thickness: 2,
        color: colorScheme.outline,
      ),
      focusColor: colorScheme.primary.withValues(alpha: 0.3),
      // Garante que textos tenham contraste adequado
      textTheme: const TextTheme().apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
    );
  }

  /// Retorna o ThemeData para modo alto contraste escuro.
  /// Usa cores com ratio de contraste mínimo de 7:1 (WCAG AAA).
  static ThemeData get highContrastDarkTheme {
    const colorScheme = ColorScheme.highContrastDark(
      primary: _highContrastPrimaryDark,
      secondary: Color(0xFF80CBC4), // Teal claro
      error: Color(0xFFFF6B6B), // Vermelho claro alto contraste
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline, width: 2),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 3),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
      ),
      // Aumenta espessura de bordas e indicadores visuais
      dividerTheme: DividerThemeData(
        thickness: 2,
        color: colorScheme.outline,
      ),
      focusColor: colorScheme.primary.withValues(alpha: 0.3),
      // Garante que textos tenham contraste adequado
      textTheme: const TextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
