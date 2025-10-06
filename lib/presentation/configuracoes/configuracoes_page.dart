import 'package:flutter/material.dart';
import 'template_list_page.dart';

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        ],
      ),
    );
  }
}
