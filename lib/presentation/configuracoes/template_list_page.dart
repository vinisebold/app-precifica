import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/report_template.dart';
import 'report_settings_page.dart';
import 'settings_controller.dart';

class TemplateListPage extends ConsumerWidget {
  const TemplateListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final naoPerguntarAtivo = settingsNotifier.getNaoPerguntarTemplate();

    if (settingsState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modelos de Relatório')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modelos de Relatório'),
      ),
      body: Column(
        children: [
          // Banner informativo se "não perguntar" estiver ativo
          if (naoPerguntarAtivo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onTertiaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Usando sempre o Modelo Padrão ao compartilhar',
                      style: TextStyle(
                        color: colorScheme.onTertiaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await settingsNotifier.setNaoPerguntarTemplate(false);
                      // Força rebuild para atualizar o banner
                      ref.invalidate(settingsControllerProvider);
                    },
                    child: const Text('Alterar'),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: settingsState.templates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum modelo encontrado',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: settingsState.templates.length,
                    itemBuilder: (context, index) {
                      final template = settingsState.templates[index];
                      return _TemplateCard(template: template);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReportSettingsPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Modelo'),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final ReportTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: template.isPadrao
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer,
          child: Icon(
            template.isPadrao ? Icons.star : Icons.description,
            color: template.isPadrao
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          template.nome,
          style: TextStyle(
            fontWeight: template.isPadrao ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(_buildSubtitle(template)),
        trailing: template.isPadrao
            ? Tooltip(
                message: 'Modelo padrão (não editável)',
                child: Icon(
                  Icons.lock_outline,
                  color: colorScheme.outline,
                ),
              )
            : PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportSettingsPage(
                          templateId: template.id,
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, ref);
                  }
                },
              ),
        onTap: template.isPadrao
            ? null
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportSettingsPage(
                templateId: template.id,
              ),
            ),
          );
        },
      ),
    );
  }

  String _buildSubtitle(ReportTemplate template) {
    final parts = <String>[];
    
    if (!template.agruparPorCategoria) {
      parts.add('Lista única');
    }
    
    if (template.ocultarPrecos) {
      parts.add('Sem preços');
    }
    
    switch (template.filtroProdutos) {
      case ProductFilter.activeWithPrice:
        parts.add('Apenas com preço');
        break;
      case ProductFilter.allActive:
        parts.add('Todos ativos');
        break;
      case ProductFilter.all:
        parts.add('Incluindo inativos');
        break;
    }

    return parts.isEmpty ? 'Toque para editar' : parts.join(' • ');
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Modelo'),
        content: Text('Deseja realmente excluir o modelo "${template.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsControllerProvider.notifier)
                  .deletarTemplate(template.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
