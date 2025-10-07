import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'template_list_page.dart';
import '../shared/providers/modo_compacto_provider.dart';

class ConfiguracoesPage extends ConsumerWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final modoCompacto = ref.watch(modoCompactoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Personalizar Relatório'),
            subtitle: const Text('Crie modelos personalizados de relatório'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TemplateListPage(),
                ),
              );
            },
          ),
          const Divider(),
          
          // Seção: Visualização
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'VISUALIZAÇÃO',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.compress),
            title: const Text('Modo Compacto'),
            subtitle: const Text('Reduz espaçamento para telas menores e muitos produtos'),
            value: modoCompacto,
            onChanged: (valor) async {
              await ref.read(modoCompactoProvider.notifier).toggle(valor);
              
              if (!context.mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    valor ? 'Modo compacto ativado' : 'Modo compacto desativado',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
