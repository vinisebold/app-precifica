import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'template_list_page.dart';
import 'settings_controller.dart';
import '../shared/providers/modo_compacto_provider.dart';
import '../shared/showcase/tutorial_controller.dart';
import '../../app/core/snackbar/app_snackbar.dart';
import '../../app/core/services/app_reset_service.dart';
import '../gestao_produtos/gestao_controller.dart';
import '../shared/introduction/app_introduction_wrapper.dart';

class ConfiguracoesPage extends ConsumerWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final modoCompacto = ref.watch(modoCompactoProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _SectionHeader(label: 'Relatório'),
          _SurfaceCard(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              leading: const Icon(Icons.description_outlined),
              title: Text(
                'Modelos de Relatório',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _getNomeModeloSelecionado(settingsState, settingsNotifier),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              enableFeedback: true,
              splashColor: Colors.transparent,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplateListPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(label: 'Visualização'),
          _SurfaceCard(
            child: _SwitchSettingTile(
              icon: Icons.compress,
              title: 'Modo Compacto',
              subtitle:
                  'Reduz espaçamentos para telas menores e muitos produtos',
              value: modoCompacto,
              onChanged: (valor) async {
                await ref.read(modoCompactoProvider.notifier).toggle(valor);

                if (!context.mounted) return;

                AppSnackbar.show(
                  context,
                  valor ? 'Modo compacto ativado' : 'Modo compacto desativado',
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(label: 'Aplicativo'),
          _SurfaceCard(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              leading: Icon(
                Icons.restart_alt_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              title: Text(
                'Reset',
                style: textTheme.titleMedium?.copyWith(
                  // Aparência mais discreta
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Remove dados, perfis e configurações, voltando ao estado inicial',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              // Sem ícone de navegação para reduzir destaque
              enableFeedback: true,
              splashColor: Colors.transparent,
              onTap: () async {
                final confirmed = await _confirmarResetAplicativo(context);
                if (confirmed != true) return;

                if (!context.mounted) return;

                showDialog<void>(
                  context: context,
                  useRootNavigator: true,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final resetService = ref.read(appResetServiceProvider);
                  await resetService.reset();

                  // Invalida estados
                  ref.invalidate(gestaoControllerProvider);
                  ref.invalidate(settingsControllerProvider);
                  ref.invalidate(modoCompactoProvider);
                  ref.invalidate(tutorialControllerProvider);

                  if (!context.mounted) return;

                  // Fecha o diálogo de loading
                  Navigator.of(context, rootNavigator: true).pop();

                  // Navega para o fluxo inicial (introdução), limpando toda a pilha
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const AppIntroductionWrapper(),
                    ),
                    (route) => false,
                  );
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    AppSnackbar.showError(
                      context,
                      'Não foi possível resetar o aplicativo.',
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmarResetAplicativo(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset do Aplicativo'),
        content: const Text(
          'Todos os dados, perfis salvos e preferências serão removidos. '
          'O aplicativo ficará como se estivesse sendo aberto pela primeira vez.\n\n'
          'Esta ação não pode ser desfeita. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
  }

  String _getNomeModeloSelecionado(settingsState, settingsNotifier) {
    final template = settingsNotifier.getTemplateSelecionadoObjeto();
    return template?.nome ?? 'Modelo Padrão';
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Divider(
              height: 0,
              thickness: 0.6,
              color: colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: child,
    );
  }
}

class _SwitchSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
