import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:precifica/domain/entities/produto.dart';
import 'package:precifica/domain/entities/report_template.dart';
import 'package:precifica/app/core/snackbar/app_snackbar.dart';
import 'package:precifica/app/core/l10n/app_localizations.dart';

import 'gestao_controller.dart';
import 'gestao_state.dart';

import '../configuracoes/configuracoes_page.dart';
import '../configuracoes/settings_controller.dart';
import '../shared/widgets/share_options_drawer.dart';
import 'widgets/categoria_nav_bar.dart';
import 'widgets/product_list_view.dart';
import '../shared/showcase/tutorial_controller.dart';
import '../shared/showcase/tutorial_keys.dart';
import '../shared/showcase/tutorial_config.dart';
import '../shared/showcase/tutorial_overlay.dart';
import '../shared/showcase/tutorial_widgets.dart';
import '../shared/providers/auto_hide_category_bar_provider.dart';

class GestaoPage extends ConsumerStatefulWidget {
  const GestaoPage({super.key});

  @override
  ConsumerState<GestaoPage> createState() => _GestaoPageState();
}

class _GestaoPageState extends ConsumerState<GestaoPage> {
  static const double _sneakPeekVisibilityThreshold = 0.08;
  static const Duration _spotlightFadeDuration = Duration(milliseconds: 220);
  late PageController _pageController; // safely initialized in initState
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _lastSettledPageIndex;
  bool _hasShownDrawerShowcase = false;
  bool _hasShownProfileSelectionTutorial = false;
  Timer? _navigationShowcaseDismissTimer;
  Timer? _navigationShowcaseAutoAdvanceTimer;
  Timer? _swipeShowcaseDismissTimer;
  Timer? _swipeShowcaseAutoAdvanceTimer;
  Rect? _navigationSpotlightRect;
  bool _navigationSpotlightUpdateScheduled = false;
  Rect? _swipeSpotlightRect;
  bool _swipeSpotlightUpdateScheduled = false;
  Timer? _navigationSpotlightClearTimer;
  Timer? _swipeSpotlightClearTimer;
  bool _hasShownCompletionScreen = false;
  bool _isAddProductFabVisible = true;
  bool _isCategoryNavBarVisible = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Registra o ShowcaseView
    ShowcaseView.register();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedId =
          ref.read(gestaoControllerProvider).categoriaSelecionadaId;
      final categorias = ref.read(gestaoControllerProvider).categorias;
      final initialPage = selectedId != null
          ? categorias.indexWhere((c) => c.id == selectedId)
          : 0;
      if (initialPage >= 0) {
        _lastSettledPageIndex = initialPage;
        try {
          _pageController.jumpToPage(initialPage);
        } catch (_) {}
        _prefetchAdjacent(initialPage);
      }

      Future.microtask(() async {
        await ref
            .read(tutorialControllerProvider.notifier)
            .checkAndStartTutorial();
        // A exibição do passo inicial será disparada pelo ref.listen
        // ao detectar a mudança de estado do tutorial.
      });
    });
  }

  void _showTutorialStep(TutorialStep step) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (step) {
        case TutorialStep.awaitingFirstCategory:
          _showCreateCategoryShowcase();
          break;
        case TutorialStep.awaitingFirstProduct:
          _showCreateProductShowcase();
          break;
        case TutorialStep.showSampleProfile:
          _showSampleProfileTutorial();
          break;
        case TutorialStep.showNavigation:
          _showNavigationShowcase();
          break;
        case TutorialStep.showSwipe:
          _showSwipeShowcase();
          break;
        default:
          break;
      }
    });
  }

  void _showCreateCategoryShowcase() {
    // Inicia o showcase diretamente sem o diálogo de boas-vindas
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([TutorialKeys.addCategoryButton]);
    });
  }

  void _showCreateProductShowcase() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([TutorialKeys.addProductFab]);
    });
  }

  void _showSampleProfileTutorial() {
    _hasShownDrawerShowcase = false;
    _hasShownProfileSelectionTutorial = false;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([TutorialKeys.menuButton]);
    });
  }

  void _showNavigationShowcase() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([TutorialKeys.categoryNavBar]);
      _navigationShowcaseAutoAdvanceTimer?.cancel();
      _navigationShowcaseAutoAdvanceTimer =
          Timer(TutorialConfig.autoAdvanceDelay, () {
        if (!mounted) return;
        final tutorialState = ref.read(tutorialControllerProvider);
        if (tutorialState.currentStep == TutorialStep.showNavigation) {
          _completeNavigationStep();
        }
      });
    });
  }

  void _showSwipeShowcase() {
    final categorias = ref.read(gestaoControllerProvider).categorias;
    if (categorias.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([TutorialKeys.categorySwipeArea]);
      _swipeShowcaseAutoAdvanceTimer?.cancel();
      _swipeShowcaseAutoAdvanceTimer =
          Timer(TutorialConfig.autoAdvanceDelay, () {
        if (!mounted) return;
        final tutorialState = ref.read(tutorialControllerProvider);
        if (tutorialState.currentStep == TutorialStep.showSwipe) {
          _completeSwipeStep();
        }
      });
    });
  }

  void _scheduleNavigationShowcaseDismiss() {
    if (_navigationShowcaseDismissTimer?.isActive ?? false) return;

    _navigationShowcaseDismissTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final tutorialState = ref.read(tutorialControllerProvider);
      if (tutorialState.currentStep == TutorialStep.showNavigation) {
        _completeNavigationStep();
      }
    });
  }

  void _cancelNavigationShowcaseTimers() {
    _navigationShowcaseDismissTimer?.cancel();
    _navigationShowcaseDismissTimer = null;
    _navigationShowcaseAutoAdvanceTimer?.cancel();
    _navigationShowcaseAutoAdvanceTimer = null;
  }

  void _cancelSwipeShowcaseTimers() {
    _swipeShowcaseDismissTimer?.cancel();
    _swipeShowcaseDismissTimer = null;
    _swipeShowcaseAutoAdvanceTimer?.cancel();
    _swipeShowcaseAutoAdvanceTimer = null;
  }

  void _scheduleNavigationSpotlightUpdate() {
    _navigationSpotlightClearTimer?.cancel();
    _navigationSpotlightClearTimer = null;
    if (_navigationSpotlightUpdateScheduled) return;
    _navigationSpotlightUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationSpotlightUpdateScheduled = false;
      if (!mounted) return;

      final navContext = TutorialKeys.categoryNavBar.currentContext;
      final overlayRenderBox = context.findRenderObject() as RenderBox?;
      final navRenderBox = navContext != null
          ? navContext.findRenderObject() as RenderBox?
          : null;

      if (overlayRenderBox == null ||
          navRenderBox == null ||
          !navRenderBox.attached) {
        return;
      }

      final offset =
          navRenderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
      final rect = offset & navRenderBox.size;

      if (_navigationSpotlightRect != rect) {
        setState(() => _navigationSpotlightRect = rect);
      }
    });
  }

  void _clearNavigationSpotlightRect() {
    if (_navigationSpotlightRect == null ||
        _navigationSpotlightClearTimer != null) {
      return;
    }

    _navigationSpotlightClearTimer = Timer(_spotlightFadeDuration, () {
      if (!mounted) return;
      _navigationSpotlightClearTimer = null;
      if (_navigationSpotlightRect != null) {
        setState(() => _navigationSpotlightRect = null);
      }
    });
  }

  void _scheduleSwipeSpotlightUpdate() {
    _swipeSpotlightClearTimer?.cancel();
    _swipeSpotlightClearTimer = null;
    if (_swipeSpotlightUpdateScheduled) return;
    _swipeSpotlightUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _swipeSpotlightUpdateScheduled = false;
      if (!mounted) return;

      final swipeContext = TutorialKeys.categorySwipeArea.currentContext;
      final overlayRenderBox = context.findRenderObject() as RenderBox?;
      final swipeRenderBox = swipeContext != null
          ? swipeContext.findRenderObject() as RenderBox?
          : null;

      if (overlayRenderBox == null ||
          swipeRenderBox == null ||
          !swipeRenderBox.attached) {
        return;
      }

      final offset =
          swipeRenderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
      final rect = offset & swipeRenderBox.size;

      if (_swipeSpotlightRect != rect) {
        setState(() => _swipeSpotlightRect = rect);
      }
    });
  }

  void _clearSwipeSpotlightRect() {
    if (_swipeSpotlightRect == null || _swipeSpotlightClearTimer != null) {
      return;
    }

    _swipeSpotlightClearTimer = Timer(_spotlightFadeDuration, () {
      if (!mounted) return;
      _swipeSpotlightClearTimer = null;
      if (_swipeSpotlightRect != null) {
        setState(() => _swipeSpotlightRect = null);
      }
    });
  }

  void _completeNavigationStep() {
    if (!mounted) {
      _cancelNavigationShowcaseTimers();
      return;
    }

    final tutorialState = ref.read(tutorialControllerProvider);
    if (tutorialState.currentStep != TutorialStep.showNavigation) {
      _cancelNavigationShowcaseTimers();
      return;
    }

    _cancelNavigationShowcaseTimers();
    ShowcaseView.get().dismiss();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentStep = ref.read(tutorialControllerProvider).currentStep;
      if (currentStep == TutorialStep.showNavigation) {
        ref.read(tutorialControllerProvider.notifier).nextStep();
      }
    });
  }

  void _scheduleSwipeShowcaseDismiss() {
    if (_swipeShowcaseDismissTimer?.isActive ?? false) return;

    _swipeShowcaseDismissTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final tutorialState = ref.read(tutorialControllerProvider);
      if (tutorialState.currentStep == TutorialStep.showSwipe) {
        _completeSwipeStep();
      }
    });
  }

  void _completeSwipeStep() {
    if (!mounted) {
      _cancelSwipeShowcaseTimers();
      return;
    }

    final tutorialState = ref.read(tutorialControllerProvider);
    if (tutorialState.currentStep != TutorialStep.showSwipe) {
      _cancelSwipeShowcaseTimers();
      return;
    }

    _cancelSwipeShowcaseTimers();
    ShowcaseView.get().dismiss();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final currentStep = ref.read(tutorialControllerProvider).currentStep;
      if (currentStep == TutorialStep.showSwipe) {
        ref.read(tutorialControllerProvider.notifier).nextStep();
      }
    });
  }

  List<Map<String, dynamic>> _buildTutorialUserSnapshot(GestaoState state) {
    final data = <Map<String, dynamic>>[];

    for (final categoria in state.categorias) {
      final produtos = state.produtosPorCategoria[categoria.id] ??
          (state.categoriaSelecionadaId == categoria.id
              ? state.produtos
              : const <Produto>[]);

      final produtosData = produtos
          .map((produto) => {
                'nome': produto.nome,
                'preco': produto.preco,
                'isAtivo': produto.isAtivo,
              })
          .toList();

      data.add({
        'nome': categoria.nome,
        'produtos': produtosData,
      });
    }

    return data;
  }

  void _showTutorialCompletionScreen() {
    if (_hasShownCompletionScreen || !mounted) return;
    _hasShownCompletionScreen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseView.get().dismiss();
      showTutorialInstruction(
        context: context,
        title: TutorialConfig.finalTitle(context),
        message: TutorialConfig.finalDescription(context),
        onDismiss: _handleTutorialCompletion,
        barrierDismissible: false,
      );
    });
  }

  void _handleTutorialCompletion() {
    final snapshot = ref.read(tutorialControllerProvider).userDataSnapshot;
    if (snapshot == null || snapshot.isEmpty) {
      ref.read(tutorialControllerProvider.notifier).clearUserDataSnapshot();
      return;
    }

    final l10n = AppLocalizations.of(context);
    Future.microtask(() async {
      try {
        await ref
            .read(gestaoControllerProvider.notifier)
            .resetAndSeedDatabase(snapshot);
      } catch (_) {
        if (mounted) {
          AppSnackbar.showError(
            context,
            l10n?.aiRestoreError ?? 'Não foi possível restaurar seus dados do tutorial.',
          );
        }
      } finally {
        ref.read(tutorialControllerProvider.notifier).clearUserDataSnapshot();
      }
    });
  }

  @override
  void dispose() {
    _cancelNavigationShowcaseTimers();
    _cancelSwipeShowcaseTimers();
    _navigationSpotlightClearTimer?.cancel();
    _swipeSpotlightClearTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _mostrarDialogoGerenciarPerfis(BuildContext context, WidgetRef ref) {
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
    final perfilInicial = ref.read(gestaoControllerProvider).perfilAtual;
    String? perfilSelecionado = perfilInicial;
    final tutorialState = ref.read(tutorialControllerProvider);
    final shouldShowProfileSelectionTutorial = tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.showSampleProfile &&
        !_hasShownProfileSelectionTutorial;

    if (shouldShowProfileSelectionTutorial) {
      _hasShownProfileSelectionTutorial = true;
    }

    bool profileSelectionShowcaseScheduled = false;
    bool hasShownApplyProfileShowcase = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final maxHeight = media.size.height * 0.86;
        return StatefulBuilder(
          builder: (context, setState) {
            final perfis = ref
                .watch(gestaoControllerProvider.select((s) => s.perfisSalvos));
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;

            if (shouldShowProfileSelectionTutorial &&
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

            void showApplyButtonShowcase() {
              if (!shouldShowProfileSelectionTutorial ||
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

            void selectProfile(String? value) {
              if (value == null) return;
              final hasChanged = perfilSelecionado != value;
              if (hasChanged) {
                setState(() => perfilSelecionado = value);
              }
              if (value == TutorialConfig.sampleProfileName) {
                showApplyButtonShowcase();
              }
            }

            void applySelectedProfile() {
              if (perfilSelecionado != null &&
                  perfilSelecionado != perfilInicial) {
                _mostrarDialogoConfirmarAcao(
                  context: sheetContext,
                  titulo: AppLocalizations.of(context)?.loadProfile ?? 'Carregar Perfil?',
                  mensagem: AppLocalizations.of(context)?.loadProfileMessage(perfilSelecionado!) ??
                      'Isto substituirá todos os seus dados atuais com o perfil "${perfilSelecionado!}".',
                  onConfirmar: () {
                    Navigator.of(sheetContext).pop();
                    gestaoNotifier.carregarPerfil(perfilSelecionado!);
                  },
                );
              } else {
                Navigator.of(sheetContext).pop();
              }
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
                                label: AppLocalizations.of(context)?.importProfile ?? 'Importar',
                                icon: Icons.file_download_outlined,
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  gestaoNotifier.importarPerfil();
                                },
                              ),
                              const SizedBox(width: 8),
                              _ActionCard(
                                label: AppLocalizations.of(context)?.saveProfile ?? 'Salvar',
                                icon: Icons.save_outlined,
                                onTap: () => _mostrarDialogoSalvarPerfil(
                                    sheetContext, ref),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ActionCard(
                                label: AppLocalizations.of(context)?.exportProfile ?? 'Exportar',
                                icon: Icons.file_upload_outlined,
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  gestaoNotifier.exportarPerfil(perfilInicial);
                                },
                              ),
                              const SizedBox(width: 8),
                              _ActionCard(
                                label: AppLocalizations.of(context)?.delete ?? 'Excluir',
                                icon: Icons.delete_outline,
                                isEnabled: perfilInicial != null,
                                onTap: () {
                                  if (perfilInicial == null) return;
                                  _mostrarDialogoConfirmarAcao(
                                    context: sheetContext,
                                    titulo: AppLocalizations.of(context)?.deleteProfileTitle ?? 'Excluir Perfil?',
                                    mensagem: AppLocalizations.of(context)?.deleteProfileMessage(perfilInicial) ??
                                        'O perfil "$perfilInicial" será excluído permanentemente.',
                                    onConfirmar: () {
                                      gestaoNotifier
                                          .excluirPerfil(perfilInicial);
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
                                child: Text(AppLocalizations.of(context)?.noProfilesSaved ?? 'Nenhum perfil salvo.'),
                              )
                            : RadioGroup<String>(
                                groupValue: perfilSelecionado,
                                onChanged: selectProfile,
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
                                        onTap: () => selectProfile(nomePerfil),
                                      );

                                      final isSampleProfile = nomePerfil ==
                                          TutorialConfig.sampleProfileName;

                                      if (shouldShowProfileSelectionTutorial &&
                                          isSampleProfile) {
                                        tile = buildTutorialShowcase(
                                          context: context,
                                          key: TutorialKeys.sampleProfileTile,
                                          title: TutorialConfig
                                              .profileSelectionTitle(context),
                                          description: TutorialConfig
                                              .profileSelectionDescription(context),
                                          targetShapeBorder:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          targetPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          onTargetClick: () =>
                                              selectProfile(nomePerfil),
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
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                Widget okButton = FilledButton(
                                  onPressed: applySelectedProfile,
                                  child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
                                );

                                if (shouldShowProfileSelectionTutorial) {
                                  final theme = Theme.of(context);
                                  final colorScheme = theme.colorScheme;
                                  final textTheme = theme.textTheme;
                                  final isDark =
                                      theme.brightness == Brightness.dark;

                                  okButton = Showcase(
                                    key: TutorialKeys.applyProfileButton,
                                    title: TutorialConfig.profileApplyTitle(context),
                                    description:
                                        TutorialConfig.profileApplyDescription(context),
                                    tooltipBackgroundColor:
                                        colorScheme.surfaceContainerHigh,
                                    titleTextStyle:
                                        textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface
                      .withValues(alpha: isDark ? 0.92 : 0.86),
                                    ),
                                    descTextStyle:
                                        textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant
                      .withValues(alpha: isDark ? 0.88 : 0.68),
                                      height: 1.35,
                                    ),
                                    tooltipPadding: const EdgeInsets.all(16),
                                    targetShapeBorder: const CircleBorder(),
                                    targetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    onTargetClick: applySelectedProfile,
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
          },
        );
      },
    );
  }

  void _mostrarDialogoConfirmarAcao({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    required VoidCallback onConfirmar,
  }) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.cancel ?? 'Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirmar();
            },
            child: Text(l10n?.confirm ?? 'Confirmar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoSalvarPerfil(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.saveCurrentProfile ?? 'Salvar Perfil Atual'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n?.profileName ?? 'Nome do Perfil'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.cancel ?? 'Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(gestaoControllerProvider.notifier)
                  .salvarPerfilAtual(controller.text);
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n?.save ?? 'Salvar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditarNome(
    BuildContext context,
    WidgetRef ref, {
    required String titulo,
    required String valorAtual,
    required Function(String) onSalvar,
  }) {
    final controller = TextEditingController(text: valorAtual);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo, style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n?.newName ?? "Novo nome"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.cancel ?? 'Cancelar', style: textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () {
              final novoNome = controller.text;
              if (novoNome.isNotEmpty) {
                onSalvar(novoNome);
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(l10n?.save ?? 'Salvar', style: textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  void _prefetchAdjacent(int centerIndex) {
    final notifier = ref.read(gestaoControllerProvider.notifier);
    notifier.prefetchCategoriaPorIndice(centerIndex - 1);
    notifier.prefetchCategoriaPorIndice(centerIndex + 1);
  }

  void _handleSneakPeekPrefetch(double pageValue) {
    final gestaoState = ref.read(gestaoControllerProvider);
    final categorias = gestaoState.categorias;
    if (categorias.isEmpty) return;

    final selectedId = gestaoState.categoriaSelecionadaId;
    final selectedIndex = selectedId != null
        ? categorias.indexWhere((c) => c.id == selectedId)
        : null;

    final total = categorias.length;
    final candidates = <int>{
      pageValue.floor().clamp(0, math.max(0, total - 1)),
      pageValue.ceil().clamp(0, math.max(0, total - 1)),
    };

    final notifier = ref.read(gestaoControllerProvider.notifier);

    for (final index in candidates) {
      if (selectedIndex != null && index == selectedIndex) continue;
      if (index < 0 || index >= total) continue;
      final visibility = 1 - (pageValue - index).abs();
      if (visibility >= _sneakPeekVisibilityThreshold) {
        notifier.prefetchCategoriaPorIndice(index);
      }
    }
  }

  void _settleToPage(int index) {
    final gestaoState = ref.read(gestaoControllerProvider);
    final categorias = gestaoState.categorias;
    if (index < 0 || index >= categorias.length) return;

    if (_lastSettledPageIndex != index) {
      _lastSettledPageIndex = index;
      ref
          .read(gestaoControllerProvider.notifier)
          .selecionarCategoriaPorIndice(index);
    }

    _prefetchAdjacent(index);
  }

  void _handleFabVisibilityRequest(bool shouldShowFab) {
    if (!mounted) return;
    final tutorialState = ref.read(tutorialControllerProvider);
    final forceVisible = tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.awaitingFirstProduct;
    final targetVisibility = forceVisible ? true : shouldShowFab;

    if (_isAddProductFabVisible == targetVisibility &&
        _isCategoryNavBarVisible == targetVisibility) return;
    setState(() {
      _isAddProductFabVisible = targetVisibility;
      _isCategoryNavBarVisible = targetVisibility;
    });
  }

  bool _handlePageViewScrollNotification(ScrollNotification notification) {
    if (notification.metrics is PageMetrics) {
      final metrics = notification.metrics as PageMetrics;
      final pageValue = metrics.page;

      if (notification is ScrollUpdateNotification) {
        if (notification.dragDetails != null && pageValue != null) {
          _handleSneakPeekPrefetch(pageValue);

          // Durante o gesto de swipe horizontal, mostra a barra de categorias
          if (!_isCategoryNavBarVisible || !_isAddProductFabVisible) {
            setState(() {
              _isCategoryNavBarVisible = true;
              _isAddProductFabVisible = true;
            });
          }
        }
      } else if (notification is ScrollEndNotification && pageValue != null) {
        final settledPage = pageValue.round();
        _settleToPage(settledPage);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final tutorialStateSnapshot = ref.watch(tutorialControllerProvider);
    final isNavigationShowcaseActive = tutorialStateSnapshot.isActive &&
        tutorialStateSnapshot.currentStep == TutorialStep.showNavigation;
    final isSwipeShowcaseActive = tutorialStateSnapshot.isActive &&
        tutorialStateSnapshot.currentStep == TutorialStep.showSwipe;

    if (isNavigationShowcaseActive) {
      _scheduleNavigationSpotlightUpdate();
    } else {
      _clearNavigationSpotlightRect();
    }

    if (isSwipeShowcaseActive) {
      _scheduleSwipeSpotlightUpdate();
    } else {
      _clearSwipeSpotlightRect();
    }

    ref.listen<GestaoState>(
      gestaoControllerProvider,
      (previousState, newState) {
        if (newState.errorMessage != null &&
            newState.errorMessage != previousState?.errorMessage) {
          AppSnackbar.showError(context, newState.errorMessage!);
          ref.read(gestaoControllerProvider.notifier).clearError();
        }

        if (newState.ultimoProdutoDeletado != null &&
            newState.ultimoProdutoDeletado !=
                previousState?.ultimoProdutoDeletado) {
          final produtoDeletado = newState.ultimoProdutoDeletado!;
          final l10n = AppLocalizations.of(context);
          AppSnackbar.showWarning(
            context,
            l10n?.deleted(produtoDeletado.nome) ?? '${produtoDeletado.nome} deletado',
            action: SnackBarAction(
              label: l10n?.undo ?? 'Desfazer',
              onPressed: () {
                ref
                    .read(gestaoControllerProvider.notifier)
                    .desfazerDeletarProduto();
              },
            ),
          );
        }

        if (previousState?.categoriaSelecionadaId !=
            newState.categoriaSelecionadaId) {
          final newIndex = newState.categorias
              .indexWhere((c) => c.id == newState.categoriaSelecionadaId);
          if (newIndex != -1) {
            _lastSettledPageIndex = newIndex;
            _prefetchAdjacent(newIndex);
            if (_pageController.hasClients &&
                _pageController.page?.round() != newIndex) {
              _pageController.jumpToPage(newIndex);
            }
          }

          // Tutorial: detecta navegação entre categorias
          final tutorialState = ref.read(tutorialControllerProvider);
          if (tutorialState.isActive) {
            if (tutorialState.currentStep == TutorialStep.showNavigation) {
              _scheduleNavigationShowcaseDismiss();
            } else if (tutorialState.currentStep == TutorialStep.showSwipe) {
              _scheduleSwipeShowcaseDismiss();
            }
          }
        }

        // Tutorial: detecta criação de categorias e produtos
        final tutorialNotifier = ref.read(tutorialControllerProvider.notifier);
        final tutorialState = ref.read(tutorialControllerProvider);

        if (tutorialState.isActive) {
          // Detecta criação de categoria
          if (newState.categorias.length >
              (previousState?.categorias.length ?? 0)) {
            tutorialNotifier.onCategoryCreated();
            // Mostra o próximo passo após um delay
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _showTutorialStep(
                    ref.read(tutorialControllerProvider).currentStep);
              }
            });
          }

          // Detecta criação de produto
          if (newState.produtos.length >
              (previousState?.produtos.length ?? 0)) {
            final existingSnapshot = tutorialState.userDataSnapshot;
            final shouldCaptureSnapshot =
                (existingSnapshot == null || existingSnapshot.isEmpty) &&
                    newState.perfilAtual == null &&
                    newState.categorias.isNotEmpty;

            if (shouldCaptureSnapshot) {
              final snapshot = _buildTutorialUserSnapshot(newState);
              if (snapshot.isNotEmpty) {
                tutorialNotifier.setUserDataSnapshot(snapshot);
              }
            }

            tutorialNotifier.onProductCreated();
            // Mostra o próximo passo após um delay
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _showTutorialStep(
                    ref.read(tutorialControllerProvider).currentStep);
              }
            });
          }

          // Detecta carregamento de perfil pronto
          final previousProfile = previousState?.perfilAtual;
          final newProfile = newState.perfilAtual;
          if (tutorialState.currentStep == TutorialStep.showSampleProfile &&
              newProfile != null &&
              newProfile != previousProfile) {
            ShowcaseView.get().dismiss();
            tutorialNotifier.onSampleProfileLoaded();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _showTutorialStep(
                    ref.read(tutorialControllerProvider).currentStep);
              }
            });
          }
        }
      },
    );

    // Listener para mudanças no estado do tutorial
    ref.listen<TutorialState>(
      tutorialControllerProvider,
      (previousState, newState) {
        if (previousState?.currentStep == TutorialStep.showNavigation &&
            newState.currentStep != TutorialStep.showNavigation) {
          _cancelNavigationShowcaseTimers();
        }

        if (previousState?.currentStep == TutorialStep.showSwipe &&
            newState.currentStep != TutorialStep.showSwipe) {
          _cancelSwipeShowcaseTimers();
        }

        if (newState.isActive &&
            previousState?.currentStep != newState.currentStep) {
          _showTutorialStep(newState.currentStep);
        }

        if (newState.isActive &&
            newState.currentStep == TutorialStep.awaitingFirstCategory &&
            previousState?.currentStep != TutorialStep.awaitingFirstCategory) {
          _hasShownCompletionScreen = false;
        }

        if (newState.currentStep == TutorialStep.completed &&
            previousState?.currentStep != TutorialStep.completed) {
          _showTutorialCompletionScreen();
        }
      },
    );

    final gestaoState = ref.watch(gestaoControllerProvider);
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final autoHideCategoryBar = ref.watch(autoHideCategoryBarProvider);

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: colorScheme.surfaceContainerLow,
          drawer: Builder(
            builder: (context) {
              return _buildSidebarMenu(
                  context, gestaoState, ref, gestaoNotifier);
            },
          ),
          onDrawerChanged: (isOpened) {
            if (!mounted) return;
            final tutorialState = ref.read(tutorialControllerProvider);

            if (isOpened &&
                tutorialState.isActive &&
                tutorialState.currentStep == TutorialStep.showSampleProfile &&
                !_hasShownDrawerShowcase) {
              _hasShownDrawerShowcase = true;

              // Aguardar 2 frames + delay para garantir render completo
              WidgetsBinding.instance.addPostFrameCallback((_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Future.delayed(const Duration(milliseconds: 350), () {
                    if (!mounted) return;
                    if (!(_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
                      return;
                    }
                    ShowcaseView.get().startShowCase(
                      [TutorialKeys.manageProfilesDestination],
                    );
                  });
                });
              });
            }
          },
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leadingWidth: 58,
            titleSpacing: 0,
            leading: Center(
              child: buildTutorialShowcase(
                context: context,
                key: TutorialKeys.menuButton,
                title: TutorialConfig.menuButtonTitle(context),
                description: TutorialConfig.menuButtonDescription(context),
                targetShapeBorder: const CircleBorder(),
                onTargetClick: () {
                  ShowcaseView.get().dismiss();
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: l10n.menuButtonLabel,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  splashRadius: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ),
            ),
            title: Text('Precifica', style: textTheme.titleLarge),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: l10n.shareButtonLabel,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _mostrarOpcoesCompartilhamento(context, ref);
                },
                splashRadius: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
              buildTutorialShowcase(
                context: context,
                key: TutorialKeys.addCategoryButton,
                title: TutorialConfig.step1Title(context),
                description: TutorialConfig.step1Description(context),
                targetShapeBorder: const CircleBorder(),
                onTargetClick: () {
                  ShowcaseView.get().dismiss();
                  _mostrarDialogoNovaCategoria(context, ref);
                },
                child: IconButton(
                  icon: const Icon(Icons.add_box_outlined),
                  tooltip: l10n.addCategoryButtonLabel,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _mostrarDialogoNovaCategoria(context, ref);
                  },
                  splashRadius: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Stack(
                children: [
                  if (gestaoState.categorias.isNotEmpty)
                    Showcase.withWidget(
                      key: TutorialKeys.categorySwipeArea,
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      targetBorderRadius: BorderRadius.circular(18.0),
                      targetPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      overlayColor: Colors.transparent,
                      disableBarrierInteraction:
                          TutorialConfig.disableBarrierInteraction,
                      disableDefaultTargetGestures: true,
                      disposeOnTap: false,
                      onTargetClick: () {},
                      container: const SizedBox.shrink(),
                      child: Stack(
                        children: [
                          RepaintBoundary(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: _handlePageViewScrollNotification,
                              child: PageView.builder(
                                controller: _pageController,
                                physics: const FastPageScrollPhysics(),
                                itemCount: gestaoState.categorias.length,
                                itemBuilder: (context, index) =>
                                    ProductListView(
                                  onFabVisibilityRequest:
                                      _handleFabVisibilityRequest,
                                  categoriaId: gestaoState.categorias[index].id,
                                  onProdutoDoubleTap: (produto) =>
                                      _mostrarDialogoEditarNome(
                                    context,
                                    ref,
                                    titulo: AppLocalizations.of(context)?.editProduct ?? 'Editar Produto',
                                    valorAtual: produto.nome,
                                    onSalvar: (novoNome) =>
                                        gestaoNotifier.atualizarNomeProduto(
                                            produto.id, novoNome),
                                  ),
                                  onProdutoTap: (produto) =>
                                      gestaoNotifier.atualizarStatusProduto(
                                          produto.id, !produto.isAtivo),
                                ),
                              ),
                            ),
                          ),
                          if (isSwipeShowcaseActive)
                            const Positioned.fill(
                              child: IgnorePointer(
                                child: Center(
                                  child: _SwipeGestureGuide(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (gestaoState.isReordering) _buildDeleteArea(context, ref),
                  if (gestaoState.isDraggingProduto)
                    Positioned(
                      top: -60,
                      left: 0,
                      right: 0,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -0.3),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: gestaoState.isDraggingProduto
                            ? _buildProdutoDeleteArea(context, ref)
                            : const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: (!autoHideCategoryBar || _isCategoryNavBarVisible) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: buildTutorialShowcase(
                    context: context,
                    key: TutorialKeys.categoryNavBar,
                    title: TutorialConfig.step4Title(context),
                    description: TutorialConfig.step4Description(context),
                    targetShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    overlayColor: Colors.transparent,
                    disableDefaultTargetGestures: true,
                    disposeOnTap: false,
                    child: CategoriaNavBar(
                      onCategoriaDoubleTap: (categoria) {
                        _mostrarDialogoEditarNome(
                          context,
                          ref,
                          titulo: AppLocalizations.of(context)?.editCategory ?? 'Editar Categoria',
                          valorAtual: categoria.nome,
                          onSalvar: (novoNome) => gestaoNotifier
                              .atualizarNomeCategoria(categoria.id, novoNome),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: Builder(
            builder: (context) {
              // Verifica se o teclado está aberto
              final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
              final shouldShowFab = _isAddProductFabVisible && !isKeyboardOpen;
              
              return buildTutorialShowcase(
                context: context,
                key: TutorialKeys.addProductFab,
                title: TutorialConfig.step2Title(context),
                description: TutorialConfig.step2Description(context),
                targetShapeBorder: const CircleBorder(),
                targetPadding: const EdgeInsets.all(14),
                onTargetClick: () {
                  if (gestaoState.categoriaSelecionadaId != null) {
                    ShowcaseView.get().dismiss();
                    HapticFeedback.lightImpact();
                    _mostrarDialogoNovoProduto(context, ref);
                  }
                },
                child: Semantics(
                  button: true,
                  enabled: gestaoState.categoriaSelecionadaId != null,
                  label: l10n.addProductButtonLabel,
                  // Usa AnimatedScale e AnimatedSlide para show/hide nativo do Material 3
                  // Combinação recomendada para FABs conforme Material Design 3 guidelines
                  child: AnimatedScale(
                    scale: shouldShowFab ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: AnimatedSlide(
                      offset: shouldShowFab ? Offset.zero : const Offset(0, 2),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: FloatingActionButton(
                        heroTag: 'add-product-fab',
                        tooltip: l10n.addProductButtonLabel,
                        onPressed: gestaoState.categoriaSelecionadaId != null
                            ? () {
                                HapticFeedback.lightImpact();
                                _mostrarDialogoNovoProduto(context, ref);
                              }
                            : null,
                        elevation:
                            gestaoState.categoriaSelecionadaId != null ? 3.0 : 0.0,
                        backgroundColor: gestaoState.categoriaSelecionadaId != null
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainer,
                        child: Icon(
                          Icons.add_shopping_cart,
                          color: gestaoState.categoriaSelecionadaId != null
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: _SpotlightFadeOverlay(
              rect: _navigationSpotlightRect,
              visible: isNavigationShowcaseActive,
              borderRadius: 28.0,
              overlayColor:
                colorScheme.scrim.withValues(alpha: isDark ? 0.65 : 0.32),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: _SpotlightFadeOverlay(
              rect: _swipeSpotlightRect,
              visible: isSwipeShowcaseActive,
              borderRadius: 18.0,
              overlayColor:
                colorScheme.scrim.withValues(alpha: isDark ? 0.65 : 0.32),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            ),
          ),
        ),
        _GlobalProcessingOverlay(active: gestaoState.isLoading),
      ],
    );
  }

  void _confirmarOrganizarComIA(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    _mostrarDialogoConfirmacaoIA(context, ref);
  }

  void _mostrarDialogoConfirmacaoIA(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => _ConfirmacaoIAOverlay(
        onConfirmar: () {
          Navigator.of(dialogContext).pop();
          ref.read(gestaoControllerProvider.notifier).organizarComIA();
        },
        onCancelar: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Widget _buildSidebarMenu(BuildContext context, GestaoState gestaoState,
      WidgetRef ref, GestaoController gestaoNotifier) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final drawerContext = context;

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
                _confirmarOrganizarComIA(context, ref);
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
            label: Text(AppLocalizations.of(context)?.organizeWithAI ?? 'Organizar com IA'),
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
                    ShowcaseView.get().dismiss();
                    Navigator.of(drawerContext).pop();
                    _mostrarDialogoGerenciarPerfis(drawerContext, ref);
                  },
                  child: Text(AppLocalizations.of(context)?.catalogs ?? 'Catálogos'),
                );
              },
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: Text(AppLocalizations.of(context)?.settings ?? 'Configurações'),
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
      return normalized.startsWith('v') ? normalized : 'v${normalized.substring(1)}';
    }
    return 'v$normalized';
  }

  void _abrirConfiguracoes(BuildContext context) {
    final navigatorContext = _scaffoldKey.currentContext ?? context;
    Navigator.of(navigatorContext).push(
      MaterialPageRoute(
        builder: (_) => const ConfiguracoesPage(),
      ),
    );
  }

  Widget _buildProdutoDeleteArea(BuildContext context, WidgetRef ref) {
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

  Widget _buildDeleteArea(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      top: -60,
      left: 0,
      right: 0,
      child: DragTarget<String>(
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
        onAcceptWithDetails: (details) async {
          HapticFeedback.lightImpact();
          final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
          final stateBefore = ref.read(gestaoControllerProvider);
          final categoriaIndex =
              stateBefore.categorias.indexWhere((c) => c.id == details.data);
          final categoriaNome = categoriaIndex != -1
              ? stateBefore.categorias[categoriaIndex].nome
              : null;
          final l10n = AppLocalizations.of(context);

          await gestaoNotifier.deletarCategoria(details.data);
          gestaoNotifier.setReordering(false);

          if (!context.mounted) return;
          AppSnackbar.showSuccess(
            context,
            categoriaNome != null
                ? (l10n?.deleted(categoriaNome) ?? 'Categoria "$categoriaNome" deletada')
                : (l10n?.deleted('Categoria') ?? 'Categoria deletada'),
          );
        },
      ),
    );
  }

  void _mostrarDialogoNovoProduto(BuildContext pageContext, WidgetRef ref) {
    final controller = TextEditingController();
    final textTheme = Theme.of(pageContext).textTheme;
    final colorScheme = Theme.of(pageContext).colorScheme;
    final l10n = AppLocalizations.of(pageContext);

    final tutorialState = ref.read(tutorialControllerProvider);
    final isAwaitingFirstProductTutorial = tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.awaitingFirstProduct;

    Timer? savePromptTimer;
    bool hasShownSavePrompt = false;
    bool listenerAttached = false;
    bool isDisposed = false;
    bool isClosing = false;

    void cancelSavePromptTimer() {
      savePromptTimer?.cancel();
      savePromptTimer = null;
    }

    void triggerSaveShowcase() {
      if (!mounted ||
          !isAwaitingFirstProductTutorial ||
          hasShownSavePrompt ||
          isDisposed) {
        return;
      }
      hasShownSavePrompt = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || isDisposed) return;
        ShowcaseView.get()
            .startShowCase([TutorialKeys.productDialogSaveButton]);
      });
    }

    void textListener() {
      if (!mounted || isDisposed) return;
      cancelSavePromptTimer();
      if (hasShownSavePrompt) return;
      if (controller.text.trim().isEmpty) return;
      savePromptTimer =
          Timer(const Duration(milliseconds: 2600), triggerSaveShowcase);
    }

    if (isAwaitingFirstProductTutorial) {
      controller.addListener(textListener);
      listenerAttached = true;
    }

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        void handleCancel() {
          if (isDisposed || isClosing) return;
          isClosing = true;
          cancelSavePromptTimer();
          Navigator.of(dialogContext).pop();
        }

        void handleSave() {
          if (isDisposed || isClosing) return;
          isClosing = true;
          cancelSavePromptTimer();
          _salvarNovoProduto(dialogContext, controller, ref);
        }

        return AlertDialog(
          title: Text(l10n?.newProduct ?? 'Novo Produto', style: textTheme.headlineSmall),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n?.productName ?? "Nome do produto",
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            autofocus: true,
            onSubmitted: (_) => handleSave(),
          ),
          actions: [
            TextButton(
              onPressed: handleCancel,
              child: Text(l10n?.cancel ?? 'Cancelar', style: textTheme.labelLarge),
            ),
            Builder(
              builder: (context) {
                Widget saveButton = TextButton(
                  onPressed: handleSave,
                  child: Text(l10n?.save ?? 'Salvar', style: textTheme.labelLarge),
                );

                if (isAwaitingFirstProductTutorial) {
                  saveButton = buildTutorialShowcase(
                    context: context,
                    key: TutorialKeys.productDialogSaveButton,
                    title: TutorialConfig.productSaveTitle(context),
                    description: TutorialConfig.productSaveDescription(context),
                    targetShapeBorder: const CircleBorder(),
                    targetPadding: const EdgeInsets.all(4),
                    onTargetClick: () {
                      ShowcaseView.get().dismiss();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!isDisposed && !isClosing) {
                          handleSave();
                        }
                      });
                    },
                    child: saveButton,
                  );
                }

                return saveButton;
              },
            ),
          ],
        );
      },
    ).then((_) {
      if (isDisposed) return;
      isDisposed = true;
      cancelSavePromptTimer();
      if (listenerAttached) {
        controller.removeListener(textListener);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    });
  }

  void _salvarNovoProduto(BuildContext dialogContext,
      TextEditingController controller, WidgetRef ref) {
    HapticFeedback.lightImpact();
    final nomeProduto = controller.text.trim();
    if (nomeProduto.isNotEmpty) {
      ref.read(gestaoControllerProvider.notifier).criarProduto(nomeProduto);
      Navigator.of(dialogContext).pop();
      
      // Exibe feedback de sucesso
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          AppSnackbar.showSuccess(
            context,
            l10n?.productAdded(nomeProduto) ?? 'Produto "$nomeProduto" adicionado com sucesso!',
          );
        }
      });
    }
  }

  void _mostrarDialogoNovaCategoria(BuildContext pageContext, WidgetRef ref) {
    final controller = TextEditingController();
    final textTheme = Theme.of(pageContext).textTheme;
    final colorScheme = Theme.of(pageContext).colorScheme;
    final l10n = AppLocalizations.of(pageContext);

    final tutorialState = ref.read(tutorialControllerProvider);
    final isAwaitingFirstCategoryTutorial = tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.awaitingFirstCategory;

    Timer? savePromptTimer;
    bool hasShownSavePrompt = false;
    bool listenerAttached = false;
    bool isDisposed = false;
    bool isClosing = false;

    void cancelSavePromptTimer() {
      savePromptTimer?.cancel();
      savePromptTimer = null;
    }

    void triggerSaveShowcase() {
      if (!mounted ||
          !isAwaitingFirstCategoryTutorial ||
          hasShownSavePrompt ||
          isDisposed) {
        return;
      }
      hasShownSavePrompt = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || isDisposed) return;
        ShowcaseView.get()
            .startShowCase([TutorialKeys.categoryDialogSaveButton]);
      });
    }

    void textListener() {
      if (!mounted || isDisposed) return;
      cancelSavePromptTimer();
      if (hasShownSavePrompt) return;
      if (controller.text.trim().isEmpty) return;
      savePromptTimer =
          Timer(const Duration(milliseconds: 2200), triggerSaveShowcase);
    }

    if (isAwaitingFirstCategoryTutorial) {
      controller.addListener(textListener);
      listenerAttached = true;
    }

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        void handleCancel() {
          if (isDisposed || isClosing) return;
          isClosing = true;
          cancelSavePromptTimer();
          Navigator.of(dialogContext).pop();
        }

        void handleSave() {
          if (isDisposed || isClosing) return;
          isClosing = true;
          cancelSavePromptTimer();
          _salvarNovaCategoria(dialogContext, controller, ref);
        }

        return AlertDialog(
          title: Text(l10n?.newCategory ?? 'Nova Categoria', style: textTheme.headlineSmall),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n?.categoryName ?? "Nome da categoria",
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            autofocus: true,
            onSubmitted: (_) => handleSave(),
          ),
          actions: [
            TextButton(
              onPressed: handleCancel,
              child: Text(l10n?.cancel ?? 'Cancelar', style: textTheme.labelLarge),
            ),
            Builder(
              builder: (context) {
                Widget saveButton = TextButton(
                  onPressed: handleSave,
                  child: Text(l10n?.save ?? 'Salvar', style: textTheme.labelLarge),
                );

                if (isAwaitingFirstCategoryTutorial) {
                  saveButton = buildTutorialShowcase(
                    context: context,
                    key: TutorialKeys.categoryDialogSaveButton,
                    title: TutorialConfig.categorySaveTitle(context),
                    description: TutorialConfig.categorySaveDescription(context),
                    targetShapeBorder: const CircleBorder(),
                    targetPadding: const EdgeInsets.all(4),
                    onTargetClick: () {
                      ShowcaseView.get().dismiss();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!isDisposed && !isClosing) {
                          handleSave();
                        }
                      });
                    },
                    child: saveButton,
                  );
                }

                return saveButton;
              },
            ),
          ],
        );
      },
    ).then((_) {
      if (isDisposed) return;
      isDisposed = true;
      cancelSavePromptTimer();
      if (listenerAttached) {
        controller.removeListener(textListener);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    });
  }

  void _salvarNovaCategoria(BuildContext dialogContext,
      TextEditingController controller, WidgetRef ref) {
    HapticFeedback.lightImpact();
    final nomeCategoria = controller.text.trim();
    if (nomeCategoria.isNotEmpty) {
      ref.read(gestaoControllerProvider.notifier).criarCategoria(nomeCategoria);
      Navigator.of(dialogContext).pop();
      
      // Exibe feedback de sucesso
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          AppSnackbar.showSuccess(
            context,
            l10n?.categoryAdded(nomeCategoria) ?? 'Categoria "$nomeCategoria" adicionada com sucesso!',
          );
        }
      });
    }
  }
}

class FastPageScrollPhysics extends PageScrollPhysics {
  const FastPageScrollPhysics({super.parent});

  @override
  FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring {
    final parentSpring = super.spring;
    return SpringDescription(
      mass: parentSpring.mass,
      stiffness: parentSpring.stiffness * 2,
      damping: parentSpring.damping * 1.2,
    );
  }
}

class _SwipeGestureGuide extends StatefulWidget {
  const _SwipeGestureGuide();

  @override
  State<_SwipeGestureGuide> createState() => _SwipeGestureGuideState();
}

class _SwipeGestureGuideState extends State<_SwipeGestureGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _offsetAnimation = Tween<double>(begin: -28, end: 28).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IgnorePointer(
      child: SizedBox(
        width: 160,
        height: 120,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_offsetAnimation.value, 0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Icon(
              Icons.swipe,
              size: 56,
              color: colorScheme.primary,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightFadeOverlay extends StatelessWidget {
  const _SpotlightFadeOverlay({
    required this.rect,
    required this.visible,
    required this.borderRadius,
    required this.overlayColor,
    this.padding = EdgeInsets.zero,
  });

  final Rect? rect;
  final bool visible;
  final double borderRadius;
  final Color overlayColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final targetRect = rect;
    if (targetRect == null) {
      return const SizedBox.shrink();
    }

    final paddedRect = Rect.fromLTRB(
      targetRect.left - padding.left,
      targetRect.top - padding.top,
      targetRect.right + padding.right,
      targetRect.bottom + padding.bottom,
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey<Rect>(paddedRect),
      tween: Tween<double>(begin: 0, end: visible ? 1 : 0),
      duration: _GestaoPageState._spotlightFadeDuration,
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        if (opacity <= 0.001) {
          return const SizedBox.shrink();
        }

        return SizedBox.expand(
          child: CustomPaint(
            painter: _SpotlightPainter(
              rect: paddedRect,
              radius: borderRadius,
              color: overlayColor,
              opacity: opacity,
            ),
          ),
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.rect,
    required this.radius,
    required this.color,
    required this.opacity,
  });

  final Rect rect;
  final double radius;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveOpacity =
        (color.a * opacity).clamp(0.0, 1.0).toDouble();
    if (effectiveOpacity <= 0.0) return;

    final overlayPaint = Paint()
      ..color = color.withValues(alpha: effectiveOpacity)
      ..style = PaintingStyle.fill;

    final screenPath = Path()..addRect(Offset.zero & size);
    final spotlightPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final overlayPath = Path.combine(
      PathOperation.difference,
      screenPath,
      spotlightPath,
    );

    canvas.drawPath(overlayPath, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return rect != oldDelegate.rect ||
        radius != oldDelegate.radius ||
        color != oldDelegate.color ||
        opacity != oldDelegate.opacity;
  }
}

class _GlobalProcessingOverlay extends StatefulWidget {
  final bool active;

  const _GlobalProcessingOverlay({required this.active});

  @override
  State<_GlobalProcessingOverlay> createState() =>
      _GlobalProcessingOverlayState();
}

class _GlobalProcessingOverlayState extends State<_GlobalProcessingOverlay>
    with TickerProviderStateMixin {
  List<String> _getMessages(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      l10n?.aiProcessing1 ?? 'Organizando os itens para você...',
      l10n?.aiProcessing2 ?? 'Analisando categorias e agrupamentos...',
      l10n?.aiProcessing3 ?? 'Separando os itens com carinho...',
      l10n?.aiProcessing4 ?? 'Quase pronto! Ajustando os últimos detalhes...',
    ];
  }

  late Timer _timer;
  int _currentMessageIndex = 0;
  late AnimationController _glowController;
  late AnimationController _visibilityController; // 0..1 para entrada/saída

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % 4;
      });
    });
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 260),
    );
    if (widget.active) {
      _visibilityController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _glowController.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GlobalProcessingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final overlayOpacity = Theme.of(context).brightness == Brightness.light
        ? 0.1
        : 0.02;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _visibilityController,
        builder: (context, _) {
          final v = Curves.easeInOut.transform(_visibilityController.value);
          if (v == 0) return const SizedBox.shrink();
          return IgnorePointer(
            ignoring: v < 0.05,
            child: Opacity(
              opacity: v,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 12,
                          sigmaY: 12,
                        ),
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _GlowBackdropPainter(
                                progress: _glowController.value,
                                colorScheme: colorScheme,
                              ),
                              child: Container(
                                color: Colors.black
                                    .withValues(alpha: overlayOpacity * v),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: _visibilityController,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                    opacity: animation, child: child),
                            child: Opacity(
                              key: ValueKey('${_currentMessageIndex}_$v'),
                              opacity: v.clamp(0, 1),
                              child: Text(
                                _getMessages(context)[_currentMessageIndex],
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.15,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.25 * v),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Opacity(
                            opacity: (v * 0.95).clamp(0, 1),
                            child: Text(
                              AppLocalizations.of(context)?.aiProcessingSubtitle ?? 'Nossa IA está cuidando de tudo, só um instante.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.9 * v),
                                shadows: [
                                  Shadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.2 * v),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlowBackdropPainter extends CustomPainter {
  final double progress; // 0..1 loop
  final ColorScheme colorScheme;

  _GlowBackdropPainter({required this.progress, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final paints = <_GlowSpec>[
      _GlowSpec(
        baseOffset: const Offset(0.18, 0.22),
        radiusFactor: 0.65,
        hueShift: 0.0,
        speed: 0.9,
        intensity: 0.38,
      ),
      _GlowSpec(
        baseOffset: const Offset(0.88, 0.78),
        radiusFactor: 0.80,
        hueShift: 0.07,
        speed: 0.55,
        intensity: 0.30,
      ),
      _GlowSpec(
        baseOffset: const Offset(0.78, 0.20),
        radiusFactor: 0.55,
        hueShift: -0.05,
        speed: 1.25,
        intensity: 0.25,
      ),
    ];

    for (final spec in paints) {
      final localT = (progress * spec.speed) % 1.0;
      final wobbleX = math.sin(localT * math.pi * 2) * 0.04;
      final wobbleY = math.cos(localT * math.pi * 2) * 0.04;
      final center = Offset(
        (spec.baseOffset.dx + wobbleX) * size.width,
        (spec.baseOffset.dy + wobbleY) * size.height,
      );
      final radius = spec.radiusFactor * size.shortestSide;
      final gradient = RadialGradient(
        colors: [
          _tint(colorScheme.primary, spec.hueShift)
              .withValues(alpha: spec.intensity * 0.50),
          _tint(colorScheme.primaryContainer, spec.hueShift)
              .withValues(alpha: spec.intensity * 0.22),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      );
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }
  }

  Color _tint(Color base, double shift) {
    if (shift == 0) return base;
    final hsl = HSLColor.fromColor(base);
    final shifted = hsl.withHue((hsl.hue + shift * 360) % 360);
    return shifted.toColor();
  }

  @override
  bool shouldRepaint(covariant _GlowBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colorScheme != colorScheme;
}

class _GlowSpec {
  final Offset baseOffset;
  final double radiusFactor;
  final double hueShift;
  final double speed;
  final double intensity;
  _GlowSpec({
    required this.baseOffset,
    required this.radiusFactor,
    required this.hueShift,
    required this.speed,
    required this.intensity,
  });
}

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

class _ConfirmacaoIAOverlay extends StatelessWidget {
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  const _ConfirmacaoIAOverlay({
    required this.onConfirmar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);
    final overlayColor = theme.brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.82)
        : Colors.black.withValues(alpha: 0.02);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Overlay de blur cobrindo toda a tela sem restrições
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: overlayColor,
              ),
            ),
          ),
          // Conteúdo do diálogo respeitando SafeArea
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: colorScheme.primary,
                        size: 56,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n?.organizeWithAIQuestion ?? 'Organizar com IA?',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n?.organizeWithAIConfirmation ?? 'Tem certeza que deseja reorganizar seus produtos automaticamente?',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onCancelar,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(l10n?.cancel ?? 'Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: onConfirmar,
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(l10n?.confirm ?? 'Confirmar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          )],
      ),
    );
  }
}

void _mostrarOpcoesCompartilhamento(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ShareOptionsDrawer(
      onShareText: () => _compartilharRelatorioTexto(context, ref),
      onShareImage: () => _compartilharRelatorioImagem(context, ref),
    ),
  );
}

void _compartilharRelatorioTexto(BuildContext context, WidgetRef ref) {
  final settingsNotifier = ref.read(settingsControllerProvider.notifier);
  final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

  final template = settingsNotifier.getTemplateSelecionadoObjeto();

  if (template == null) {
    final textoRelatorio = gestaoNotifier.gerarTextoRelatorio();
    Share.share(textoRelatorio);
  } else {
    final textoRelatorio =
        gestaoNotifier.gerarTextoRelatorioComTemplate(template);
    Share.share(textoRelatorio);
  }
}

Future<void> _compartilharRelatorioImagem(BuildContext context, WidgetRef ref) async {
  final settingsNotifier = ref.read(settingsControllerProvider.notifier);
  final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

  // Obtém o template selecionado ou usa o padrão
  final template = settingsNotifier.getTemplateSelecionadoObjeto() ?? 
      ReportTemplate.padrao();

  // Guarda uma referência ao navigator antes de operações assíncronas
  final navigator = Navigator.of(context);
  bool dialogShown = false;
  
  try {
    // Mostra indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
    dialogShown = true;

    await gestaoNotifier.compartilharRelatorioComoImagem(template);
    
  } catch (e) {
    // Mostra mensagem de erro após fechar o loading
    // Aguarda um pouco para garantir que a UI está pronta
    await Future.delayed(const Duration(milliseconds: 100));
    if (context.mounted) {
      AppSnackbar.show(
        context,
        'Erro ao gerar imagem: ${e.toString()}',
      );
    }
  } finally {
    // Sempre fecha o indicador de carregamento no finally
    if (dialogShown) {
      try {
        navigator.pop();
      } catch (_) {
        // Ignora erro se o diálogo já foi fechado
      }
    }
  }
}
