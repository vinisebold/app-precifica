import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/gestao_produtos/gestao_page.dart';
import 'package:dynamic_color/dynamic_color.dart'; // Importe o novo pacote

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Define um esquema de cores padrão caso as cores dinâmicas não estejam disponíveis
    final ColorScheme fallbackColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
    );

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Usa as cores dinâmicas do celular se disponíveis
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Usa o esquema de cores padrão como fallback
          lightColorScheme = fallbackColorScheme;
          darkColorScheme = fallbackColorScheme.copyWith(brightness: Brightness.dark);
        }

        // Este é o tema global para os campos de texto que resolverá o problema da cor cinza
        final inputTheme = InputDecorationTheme(
          filled: true,
          // A cor do campo de texto agora vem do tema dinâmico
          fillColor: lightColorScheme.surfaceContainerHighest,
          border: const OutlineInputBorder( // Usando OutlineInputBorder para mais consistência
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
      },
    );
  }
}