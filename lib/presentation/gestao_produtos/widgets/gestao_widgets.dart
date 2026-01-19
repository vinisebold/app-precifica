import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:precifica/app/core/l10n/app_localizations.dart';
import 'package:precifica/domain/entities/produto.dart';

import '../gestao_controller.dart';
import '../gestao_state.dart';
import '../dialogs/gestao_dialogs.dart';
import '../dialogs/gerenciar_perfis_bottom_sheet.dart';
import '../../configuracoes/configuracoes_page.dart';
import '../../shared/showcase/tutorial_config.dart';
import '../../shared/showcase/tutorial_keys.dart';
import '../../shared/showcase/tutorial_widgets.dart';

/// Widget que constrói o menu lateral (Drawer) da página de gestão.
class GestaoSidebarMenu extends ConsumerWidget {
  final GestaoState gestaoState;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool Function() hasShownDrawerShowcase;
  final void Function(bool) setHasShownDrawerShowcase;
  final bool Function() hasShownProfileSelectionTutorial;
  final void Function(bool) setHasShownProfileSelectionTutorial;

  const GestaoSidebarMenu({
    super.key,
    required this.gestaoState,
    required this.scaffoldKey,
    required this.hasShownDrawerShowcase,
    required this.setHasShownDrawerShowcase,
    required this.hasShownProfileSelectionTutorial,
    required this.setHasShownProfileSelectionTutorial,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: NavigationDrawer(
        elevation: 0,
        backgroundColor: cs.surface,
        selectedIndex: null,
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          switch (index) {
            case 0:
              if (!gestaoState.isLoading) {
                GestaoDialogs.mostrarDialogoConfirmacaoIA(context, ref);
              }
              break;
            case 1:
              _mostrarDialogoGerenciarPerfis(context, ref);
              break;
            case 2:
              _abrirConfiguracoes(context);
              break;
          }
        },
        children: [
          // App header - mais clean
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
            child: Text(
              'Precifica',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: cs.onSurface,
              ),
            ),
          ),
          // Navigation items
          NavigationDrawerDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: Text(AppLocalizations.of(context)?.organizeWithAI ??
                'Organizar com IA'),
            enabled: !gestaoState.isLoading,
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: Builder(
              builder: (context) {
                return buildTutorialShowcase(
                  context: context,
                  key: TutorialKeys.manageProfilesDestination,
                  title: TutorialConfig.profileDrawerTitle(context),
                  description: TutorialConfig.profileDrawerDescription(context),
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(56),
                  ),
                  targetPadding: const EdgeInsets.fromLTRB(52, 18, 148, 18),
                  onTargetClick: () {
                    Navigator.of(context).pop();
                    _mostrarDialogoGerenciarPerfis(context, ref);
                  },
                  child: Text(AppLocalizations.of(context)?.catalogs ??
                      'Catálogos'),
                );
              },
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: Text(AppLocalizations.of(context)?.settings ??
                'Configurações'),
          ),
          const SizedBox(height: 12),
          // Version footer - minimalista
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Text(
                  _formatVersion(snapshot.data!.version),
                  style: tt.labelSmall?.copyWith(
                    color: cs.outline,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatVersion(String? version) {
    if (version == null || version.isEmpty) return '';
    final normalized = version.trim();
    if (normalized.startsWith(RegExp(r'[vV]'))) {
      return normalized.startsWith('v')
          ? normalized
          : 'v${normalized.substring(1)}';
    }
    return 'v$normalized';
  }

  void _abrirConfiguracoes(BuildContext context) {
    final navigatorContext = scaffoldKey.currentContext ?? context;
    Navigator.of(navigatorContext).push(
      MaterialPageRoute(
        builder: (_) => const ConfiguracoesPage(),
      ),
    );
  }

  void _mostrarDialogoGerenciarPerfis(BuildContext context, WidgetRef ref) {
    GerenciarPerfisBottomSheet.show(
      context: context,
      ref: ref,
      shouldShowProfileSelectionTutorial: !hasShownProfileSelectionTutorial(),
      onProfileSelectionTutorialShown: () =>
          setHasShownProfileSelectionTutorial(true),
    );
  }
}

/// Área de exclusão para arrastar categorias.
class CategoryDeleteArea extends StatelessWidget {
  final WidgetRef ref;

  const CategoryDeleteArea({super.key, required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      top: -60,
      left: 0,
      right: 0,
      child: DragTarget<String>(
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return _buildDeleteAreaContainer(
            context: context,
            colorScheme: colorScheme,
            isHovering: isHovering,
          );
        },
        onAcceptWithDetails: (details) async {
          HapticFeedback.lightImpact();
          final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

          await gestaoNotifier.deletarCategoria(details.data);
          gestaoNotifier.setReordering(false);
        },
      ),
    );
  }

  Widget _buildDeleteAreaContainer({
    required BuildContext context,
    required ColorScheme colorScheme,
    required bool isHovering,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: isHovering ? 140 : 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHovering
              ? [
                  colorScheme.error.withValues(alpha: 0.75),
                  colorScheme.errorContainer.withValues(alpha: 0.60),
                  colorScheme.errorContainer.withValues(alpha: 0.30),
                  colorScheme.errorContainer.withValues(alpha: 0.08),
                  Colors.transparent,
                ]
              : [
                  colorScheme.error.withValues(alpha: 0.50),
                  colorScheme.errorContainer.withValues(alpha: 0.40),
                  colorScheme.errorContainer.withValues(alpha: 0.20),
                  colorScheme.errorContainer.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
          stops: const [0.0, 0.35, 0.65, 0.88, 1.0],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: isHovering ? 1.15 : 1.0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHovering
                    ? colorScheme.error.withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: colorScheme.onErrorContainer,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Área de exclusão para arrastar produtos.
class ProductDeleteArea extends StatelessWidget {
  final WidgetRef ref;

  const ProductDeleteArea({super.key, required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DragTarget<Produto>(
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: isHovering ? 140 : 130,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isHovering
                  ? [
                      colorScheme.error.withValues(alpha: 0.75),
                      colorScheme.errorContainer.withValues(alpha: 0.60),
                      colorScheme.errorContainer.withValues(alpha: 0.30),
                      colorScheme.errorContainer.withValues(alpha: 0.08),
                      Colors.transparent,
                    ]
                  : [
                      colorScheme.error.withValues(alpha: 0.50),
                      colorScheme.errorContainer.withValues(alpha: 0.40),
                      colorScheme.errorContainer.withValues(alpha: 0.20),
                      colorScheme.errorContainer.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
              stops: const [0.0, 0.35, 0.65, 0.88, 1.0],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 250),
                scale: isHovering ? 1.15 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHovering
                        ? colorScheme.error.withValues(alpha: 0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: colorScheme.onErrorContainer,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      onAcceptWithDetails: (details) {
        HapticFeedback.lightImpact();
        ref
            .read(gestaoControllerProvider.notifier)
            .deletarProduto(details.data.id);
        ref.read(gestaoControllerProvider.notifier).setDraggingProduto(false);
      },
    );
  }
}
