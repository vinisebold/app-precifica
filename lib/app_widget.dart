import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/gestao_produtos/gestao_page.dart';
class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    );

    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    );

    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: lightColorScheme.surfaceContainerHighest,
      border: const OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );

    final darkInputTheme = inputTheme.copyWith(
      fillColor: darkColorScheme.surfaceContainerHighest,
    );

    return ProviderScope(
      child: MaterialApp(
        title: 'OrganizaAí',
        debugShowCheckedModeBanner: false,

        // Tema para o modo claro
        theme: ThemeData(
          colorScheme: lightColorScheme,
          useMaterial3: true,
          inputDecorationTheme: inputTheme,
        ),

        // Tema para o modo escuro
        darkTheme: ThemeData(
          colorScheme: darkColorScheme,
          useMaterial3: true,
          inputDecorationTheme: darkInputTheme,
        ),

        home: const GestaoPage(),
      ),
    );
  }
}
