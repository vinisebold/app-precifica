import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/report_template.dart';
import 'report_settings_page.dart';
import 'settings_controller.dart';
import '../../app/core/snackbar/app_snackbar.dart';

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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            if (naoPerguntarAtivo)
              _BannerCard(
                icon: Icons.info_outline,
                message: 'Usando sempre o Modelo Padrão ao compartilhar',
                actionLabel: 'Alterar',
                onActionPressed: () async {
                  await settingsNotifier.setNaoPerguntarTemplate(false);
                  ref.invalidate(settingsControllerProvider);
                },
              ),
            if (naoPerguntarAtivo) const SizedBox(height: 16),
            Expanded(
              child: settingsState.templates.isEmpty
                  ? _EmptyState(colorScheme: colorScheme)
                  : ListView.separated(
                      itemCount: settingsState.templates.length,
                      separatorBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                          thickness: 1,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final template = settingsState.templates[index];
                        return _TemplateCard(template: template);
                      },
                    ),
            ),
          ],
        ),
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
    final settingsState = ref.watch(settingsControllerProvider);
    final selectedId = settingsState.templateSelecionadoId ?? 'default';
    final isSelecionado = selectedId == template.id;

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _selecionarTemplate(context, ref),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(
                isSelecionado
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    isSelecionado ? colorScheme.primary : colorScheme.outline,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  template.nome,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!template.isPadrao) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportSettingsPage(
                          templateId: template.id,
                        ),
                      ),
                    );
                  },
                  tooltip: 'Editar',
                ),
              ] else ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.lock,
          color: colorScheme.onSurfaceVariant
            .withValues(alpha: 0.5),
                  ),
                  onPressed: null,
                  tooltip: 'Não editável',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selecionarTemplate(BuildContext context, WidgetRef ref) async {
    final settingsState = ref.read(settingsControllerProvider);
    final selectedId = settingsState.templateSelecionadoId ?? 'default';
    if (selectedId == template.id) return;

    await ref
        .read(settingsControllerProvider.notifier)
        .setTemplateSelecionado(template.id);

    if (!context.mounted) return;

    AppSnackbar.show(
      context,
      'Modelo "${template.nome}" selecionado',
    );
  }
}

class _BannerCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const _BannerCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onTertiaryContainer),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: onActionPressed,
              child: Text(actionLabel),
            )
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.description_outlined,
          size: 72,
          color: colorScheme.outline,
        ),
        const SizedBox(height: 20),
        Text(
          'Nenhum modelo encontrado',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Crie seu primeiro modelo para personalizar relatórios.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
