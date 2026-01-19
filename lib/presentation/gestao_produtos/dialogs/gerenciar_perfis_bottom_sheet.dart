import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:precifica/app/core/l10n/app_localizations.dart';

import '../gestao_controller.dart';
import '../../shared/showcase/tutorial_config.dart';
import '../../shared/showcase/tutorial_keys.dart';
import '../../shared/showcase/tutorial_widgets.dart';
import 'gestao_dialogs.dart';

/// Bottom sheet para gerenciar perfis/catálogos.
class GerenciarPerfisBottomSheet extends ConsumerStatefulWidget {
  final bool shouldShowProfileSelectionTutorial;
  final VoidCallback onProfileSelectionTutorialShown;

  const GerenciarPerfisBottomSheet({
    super.key,
    required this.shouldShowProfileSelectionTutorial,
    required this.onProfileSelectionTutorialShown,
  });

  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required bool shouldShowProfileSelectionTutorial,
    required VoidCallback onProfileSelectionTutorialShown,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => GerenciarPerfisBottomSheet(
        shouldShowProfileSelectionTutorial: shouldShowProfileSelectionTutorial,
        onProfileSelectionTutorialShown: onProfileSelectionTutorialShown,
      ),
    );
  }

  @override
  ConsumerState<GerenciarPerfisBottomSheet> createState() =>
      _GerenciarPerfisBottomSheetState();
}

class _GerenciarPerfisBottomSheetState
    extends ConsumerState<GerenciarPerfisBottomSheet> {
  late String? perfilSelecionado;
  late String? perfilInicial;
  bool profileSelectionShowcaseScheduled = false;
  bool hasShownApplyProfileShowcase = false;

  @override
  void initState() {
    super.initState();
    perfilInicial = ref.read(gestaoControllerProvider).perfilAtual;
    perfilSelecionado = perfilInicial;

    if (widget.shouldShowProfileSelectionTutorial) {
      widget.onProfileSelectionTutorialShown();
    }
  }

  void _showApplyButtonShowcase() {
    if (!widget.shouldShowProfileSelectionTutorial ||
        hasShownApplyProfileShowcase ||
        !(perfilSelecionado == TutorialConfig.sampleProfileName)) {
      return;
    }
    hasShownApplyProfileShowcase = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 160), () {
        if (!mounted) return;
        ShowcaseView.get().startShowCase([
          TutorialKeys.applyProfileButton,
        ]);
      });
    });
  }

  void _selectProfile(String? value) {
    if (value == null) return;
    final hasChanged = perfilSelecionado != value;
    if (hasChanged) {
      setState(() => perfilSelecionado = value);
    }
    if (value == TutorialConfig.sampleProfileName) {
      _showApplyButtonShowcase();
    }
  }

  void _applySelectedProfile() {
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
    if (perfilSelecionado != null && perfilSelecionado != perfilInicial) {
      GestaoDialogs.mostrarDialogoConfirmarAcao(
        context: context,
        titulo:
            AppLocalizations.of(context)?.loadProfile ?? 'Carregar Perfil?',
        mensagem: AppLocalizations.of(context)
                ?.loadProfileMessage(perfilSelecionado!) ??
            'Isto substituirá todos os seus dados atuais com o perfil "${perfilSelecionado!}".',
        onConfirmar: () {
          Navigator.of(context).pop();
          gestaoNotifier.carregarPerfil(perfilSelecionado!);
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.86;
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
    final perfis =
        ref.watch(gestaoControllerProvider.select((s) => s.perfisSalvos));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.shouldShowProfileSelectionTutorial &&
        !profileSelectionShowcaseScheduled &&
        perfis.contains(TutorialConfig.sampleProfileName)) {
      profileSelectionShowcaseScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 180), () {
          if (!mounted) return;
          ShowcaseView.get().startShowCase([
            TutorialKeys.sampleProfileTile,
          ]);
        });
      });
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.catalogs ?? 'Catálogos',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _ActionCard(
                        label: AppLocalizations.of(context)?.importProfile ??
                            'Importar',
                        icon: Icons.file_download_outlined,
                        onTap: () {
                          Navigator.of(context).pop();
                          gestaoNotifier.importarPerfil();
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionCard(
                        label: AppLocalizations.of(context)?.saveProfile ??
                            'Salvar',
                        icon: Icons.save_outlined,
                        onTap: () =>
                            GestaoDialogs.mostrarDialogoSalvarPerfil(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ActionCard(
                        label: AppLocalizations.of(context)?.exportProfile ??
                            'Exportar',
                        icon: Icons.file_upload_outlined,
                        onTap: () {
                          Navigator.of(context).pop();
                          gestaoNotifier.exportarPerfil(perfilInicial);
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionCard(
                        label:
                            AppLocalizations.of(context)?.delete ?? 'Excluir',
                        icon: Icons.delete_outline,
                        isEnabled: perfilInicial != null,
                        onTap: () {
                          if (perfilInicial == null) return;
                          GestaoDialogs.mostrarDialogoConfirmarAcao(
                            context: context,
                            titulo: AppLocalizations.of(context)
                                    ?.deleteProfileTitle ??
                                'Excluir Perfil?',
                            mensagem: AppLocalizations.of(context)
                                    ?.deleteProfileMessage(perfilInicial!) ??
                                'O perfil "$perfilInicial" será excluído permanentemente.',
                            onConfirmar: () {
                              gestaoNotifier.excluirPerfil(perfilInicial!);
                              setState(() {
                                perfilSelecionado = null;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: perfis.isEmpty
                    ? Center(
                        child: Text(
                            AppLocalizations.of(context)?.noProfilesSaved ??
                                'Nenhum perfil salvo.'),
                      )
                    : RadioGroup<String>(
                        groupValue: perfilSelecionado,
                        onChanged: _selectProfile,
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.builder(
                            itemCount: perfis.length,
                            itemBuilder: (context, index) {
                              final nomePerfil = perfis[index];
                              Widget tile = ListTile(
                                title: Text(nomePerfil),
                                leading: Radio<String>(
                                  value: nomePerfil,
                                ),
                                onTap: () => _selectProfile(nomePerfil),
                              );

                              final isSampleProfile =
                                  nomePerfil == TutorialConfig.sampleProfileName;

                              if (widget.shouldShowProfileSelectionTutorial &&
                                  isSampleProfile) {
                                tile = buildTutorialShowcase(
                                  context: context,
                                  key: TutorialKeys.sampleProfileTile,
                                  title: TutorialConfig.profileSelectionTitle(
                                      context),
                                  description:
                                      TutorialConfig.profileSelectionDescription(
                                          context),
                                  targetShapeBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  targetPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  onTargetClick: () =>
                                      _selectProfile(nomePerfil),
                                  child: tile,
                                );
                              }

                              return tile;
                            },
                          ),
                        ),
                      ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                          AppLocalizations.of(context)?.cancel ?? 'Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        Widget okButton = FilledButton(
                          onPressed: _applySelectedProfile,
                          child:
                              Text(AppLocalizations.of(context)?.ok ?? 'OK'),
                        );

                        if (widget.shouldShowProfileSelectionTutorial) {
                          final theme = Theme.of(context);
                          final colorScheme = theme.colorScheme;
                          final textTheme = theme.textTheme;
                          final isDark = theme.brightness == Brightness.dark;

                          okButton = Showcase(
                            key: TutorialKeys.applyProfileButton,
                            title: TutorialConfig.profileApplyTitle(context),
                            description:
                                TutorialConfig.profileApplyDescription(context),
                            tooltipBackgroundColor:
                                colorScheme.surfaceContainerHigh,
                            titleTextStyle: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface
                                  .withValues(alpha: isDark ? 0.92 : 0.86),
                            ),
                            descTextStyle: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: isDark ? 0.88 : 0.68),
                              height: 1.35,
                            ),
                            tooltipPadding: const EdgeInsets.all(16),
                            targetShapeBorder: const CircleBorder(),
                            targetPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            onTargetClick: _applySelectedProfile,
                            disposeOnTap: true,
                            disableDefaultTargetGestures: false,
                            overlayColor: colorScheme.scrim
                                .withValues(alpha: isDark ? 0.65 : 0.32),
                            disableBarrierInteraction: false,
                            disableMovingAnimation: false,
                            scaleAnimationDuration:
                                const Duration(milliseconds: 300),
                            scaleAnimationCurve: Curves.easeOutCubic,
                            child: okButton,
                          );
                        }

                        return okButton;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de ação usado no bottom sheet de perfis.
class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEnabled
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : Theme.of(context).colorScheme.outline;

    return Expanded(
      child: Card(
        elevation: isEnabled ? 1 : 0,
        color: isEnabled
            ? null
            : Theme.of(context)
                .colorScheme
                .surface
                .withAlpha((255 * 0.5).round()),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// RadioGroup widget para seleção de perfis.
class RadioGroup<T> extends InheritedWidget {
  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  const RadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  static RadioGroup<T>? of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RadioGroup<T>>();
  }

  @override
  bool updateShouldNotify(RadioGroup<T> oldWidget) {
    return groupValue != oldWidget.groupValue ||
        onChanged != oldWidget.onChanged;
  }
}

/// Extensão para Radio que obtém valores do RadioGroup.
extension RadioExtension<T> on Radio<T> {
  Widget build(BuildContext context) {
    final group = RadioGroup.of<T>(context);
    return Radio<T>(
      value: value,
      groupValue: group?.groupValue,
      onChanged: group?.onChanged,
    );
  }
}
