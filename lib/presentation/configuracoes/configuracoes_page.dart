import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/core/l10n/app_localizations.dart';
import 'template_list_page.dart';
import 'settings_controller.dart';
import '../shared/providers/modo_compacto_provider.dart';
import '../shared/providers/locale_provider.dart';
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
    final localeNotifier = ref.read(localeProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionHeader(label: l10n.report),
          _SurfaceCard(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              leading: const Icon(Icons.description_outlined),
              title: Text(
                l10n.reportTemplates,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _getNomeModeloSelecionado(settingsState, settingsNotifier, l10n),
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
          _SectionHeader(label: l10n.visualization),
          _SurfaceCard(
            child: _SwitchSettingTile(
              icon: Icons.compress,
              title: l10n.compactMode,
              subtitle: l10n.compactModeDescription,
              value: modoCompacto,
              onChanged: (valor) async {
                await ref.read(modoCompactoProvider.notifier).toggle(valor);

                if (!context.mounted) return;

                AppSnackbar.show(
                  context,
                  valor ? l10n.compactModeEnabled : l10n.compactModeDisabled,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(label: l10n.language),
          _SurfaceCard(
            child: _LanguageSettingTile(
              icon: Icons.language,
              title: l10n.appLanguage,
              subtitle: l10n.appLanguageDescription,
              currentLanguage: localeNotifier.currentLanguage,
              onLanguageChanged: (language) async {
                await localeNotifier.setLocale(language);
                if (!context.mounted) return;
                AppSnackbar.show(
                  context,
                  l10n.languageChanged(language.displayName),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () async {
                final confirmed = await _confirmarResetAplicativo(context, l10n);
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
                  ref.invalidate(localeProvider);

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
                      l10n.resetError,
                    );
                  }
                }
              },
              child: Text(
                l10n.resetApp,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<bool?> _confirmarResetAplicativo(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetAppTitle),
        content: Text(l10n.resetAppMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }

  String _getNomeModeloSelecionado(settingsState, settingsNotifier, AppLocalizations l10n) {
    final template = settingsNotifier.getTemplateSelecionadoObjeto();
    return template?.nome ?? l10n.defaultTemplate;
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

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: Padding(
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
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const _LanguageSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showLanguageDialog(context),
      child: Padding(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                currentLanguage.displayName,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog<AppLanguage>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((language) {
            final isSelected = language == currentLanguage;
            return ListTile(
              leading: isSelected
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : const Icon(Icons.circle_outlined),
              title: Text(language.displayName),
              selected: isSelected,
              onTap: () {
                Navigator.of(dialogContext).pop(language);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    ).then((selectedLanguage) {
      if (selectedLanguage != null && selectedLanguage != currentLanguage) {
        HapticFeedback.lightImpact();
        onLanguageChanged(selectedLanguage);
      }
    });
  }
}
