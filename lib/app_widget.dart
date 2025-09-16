import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/gestao_produtos/gestao_page.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // O ProviderScope é o widget do Riverpod que "guarda" o estado do nosso app.
    // Ele precisa estar no topo da árvore de widgets.
    return ProviderScope(
      child: MaterialApp(
        title: 'OrganizaAí',
        debugShowCheckedModeBanner: false, // Remove a faixa de "Debug"

        // Configuração do tema com base no Material 3
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),

        // A tela inicial do nosso aplicativo
        home: const GestaoPage(),
      ),
    );
  }
}
