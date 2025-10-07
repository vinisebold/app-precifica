import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'template_list_page.dart';
import 'settings_controller.dart';
import '../shared/providers/modo_compacto_provider.dart';

class ConfiguracoesPage extends ConsumerWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final modoCompacto = ref.watch(modoCompactoProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          // Seção: Relatório
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'RELATÓRIO',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Modelo Ativo'),
            subtitle: Text(
              _getNomeModeloSelecionado(settingsState, settingsNotifier),
              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _mostrarSeletorModelo(context, ref),
          ),
          
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Gerenciar Modelos'),
            subtitle: const Text('Criar e editar modelos personalizados'),
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

  String _getNomeModeloSelecionado(settingsState, settingsNotifier) {
    final template = settingsNotifier.getTemplateSelecionadoObjeto();
    return template?.nome ?? 'Modelo Padrão';
  }

  void _mostrarSeletorModelo(BuildContext context, WidgetRef ref) {
    final settingsState = ref.read(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final templates = settingsState.templates;
    final templateSelecionadoId = settingsState.templateSelecionadoId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecionar Modelo Ativo',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'O modelo selecionado será usado ao compartilhar relatórios',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: templates.isEmpty
                    ? const Center(
                        child: Text('Nenhum modelo disponível'),
                      )
                    : ListView.builder(
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          final isSelecionado = template.id == templateSelecionadoId;
                          
                          return ListTile(
                            title: Text(template.nome),
                            subtitle: template.isPadrao
                                ? const Text('Modelo Padrão (fixo)')
                                : null,
                            leading: Radio<String>(
                              value: template.id,
                              groupValue: templateSelecionadoId,
                              onChanged: (value) async {
                                await settingsNotifier.setTemplateSelecionado(value);
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Modelo "${template.nome}" selecionado'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            trailing: isSelecionado
                                ? Icon(
                                    Icons.check_circle,
                                    color: colorScheme.primary,
                                    size: 24,
                                  )
                                : (template.isPadrao
                                    ? Icon(
                                        Icons.lock_outline,
                                        color: colorScheme.outline,
                                        size: 20,
                                      )
                                    : null),
                            onTap: () async {
                              await settingsNotifier.setTemplateSelecionado(template.id);
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Modelo "${template.nome}" selecionado'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
