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
import 'package:precifica/app/core/toast/global_toast_controller.dart';

import 'gestao_controller.dart';
import 'gestao_state.dart';

import '../configuracoes/configuracoes_page.dart';
import '../configuracoes/settings_controller.dart';
import 'widgets/categoria_nav_bar.dart';
import 'widgets/product_list_view.dart';
import '../shared/showcase/tutorial_controller.dart';
import '../shared/showcase/tutorial_keys.dart';
import '../shared/showcase/tutorial_config.dart';
import '../shared/showcase/tutorial_overlay.dart';
import '../shared/showcase/tutorial_widgets.dart';

class GestaoPage extends ConsumerStatefulWidget {
  const GestaoPage({super.key});

  @override
  ConsumerState<GestaoPage> createState() => _GestaoPageState();
}

class _GestaoPageState extends ConsumerState<GestaoPage> {
  static const double _sneakPeekVisibilityThreshold = 0.08;
  static const Duration _spotlightFadeDuration =
      Duration(milliseconds: 220);
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

      // Inicia o tutorial se necessário
      _checkAndShowTutorial();
    });
  }

  void _checkAndShowTutorial() {
    final tutorialState = ref.read(tutorialControllerProvider);

    // Mostra os showcases baseado no estado atual do tutorial
    if (tutorialState.isActive) {
      _showTutorialStep(tutorialState.currentStep);
    }
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
    showTutorialInstruction(
      context: context,
      title: TutorialConfig.tutorialTitle,
      message: TutorialConfig.step1Description,
      onDismiss: () {
        ShowcaseView.get().startShowCase([TutorialKeys.addCategoryButton]);
      },
    );
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
    _navigationShowcaseDismissTimer?.cancel();
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
      final navRenderBox =
          navContext != null ? navContext.findRenderObject() as RenderBox? : null;

      if (overlayRenderBox == null || navRenderBox == null || !navRenderBox.attached) {
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
    if (_navigationSpotlightRect == null || _navigationSpotlightClearTimer != null) {
      return;
    }

    _navigationSpotlightClearTimer =
        Timer(_spotlightFadeDuration, () {
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

      if (overlayRenderBox == null || swipeRenderBox == null || !swipeRenderBox.attached) {
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
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final currentStep = ref.read(tutorialControllerProvider).currentStep;
      if (currentStep == TutorialStep.showNavigation) {
        ref.read(tutorialControllerProvider.notifier).nextStep();
      }
    });
  }

  void _scheduleSwipeShowcaseDismiss() {
    _swipeShowcaseDismissTimer?.cancel();
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

            void applySelectedProfile() {
              if (perfilSelecionado != null &&
                  perfilSelecionado != perfilInicial) {
                _mostrarDialogoConfirmarAcao(
                  context: sheetContext,
                  titulo: 'Carregar Perfil?',
                  mensagem:
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
                      'Gerir Perfis',
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
                                label: 'Importar',
                                icon: Icons.file_download_outlined,
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  gestaoNotifier.importarPerfil();
                                },
                              ),
                              const SizedBox(width: 8),
                              _ActionCard(
                                label: 'Salvar',
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
                                label: 'Exportar',
                                icon: Icons.file_upload_outlined,
                                isEnabled: perfilInicial != null,
                                onTap: () {
                                  if (perfilInicial == null) return;
                                  Navigator.of(sheetContext).pop();
                                  gestaoNotifier.exportarPerfil(perfilInicial);
                                },
                              ),
                              const SizedBox(width: 8),
                              _ActionCard(
                                label: 'Excluir',
                                icon: Icons.delete_outline,
                                isEnabled: perfilInicial != null,
                                onTap: () {
                                  if (perfilInicial == null) return;
                                  _mostrarDialogoConfirmarAcao(
                                    context: sheetContext,
                                    titulo: 'Excluir Perfil?',
                                    mensagem:
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
                            ? const Center(
                                child: Text('Nenhum perfil salvo.'),
                              )
                            : Scrollbar(
                                thumbVisibility: true,
                                child: ListView.builder(
                                  itemCount: perfis.length,
                                  itemBuilder: (context, index) {
                                    final nomePerfil = perfis[index];
                                    Widget tile = ListTile(
                                      title: Text(nomePerfil),
                                      leading: Radio<String>(
                                        value: nomePerfil,
                                        groupValue: perfilSelecionado,
                                        onChanged: (value) {
                                          setState(
                                              () => perfilSelecionado = value);
                                          if (value ==
                                              TutorialConfig
                                                  .sampleProfileName) {
                                            showApplyButtonShowcase();
                                          }
                                        },
                                      ),
                                      onTap: () {
                                        setState(() =>
                                            perfilSelecionado = nomePerfil);
                                        if (nomePerfil ==
                                            TutorialConfig.sampleProfileName) {
                                          showApplyButtonShowcase();
                                        }
                                      },
                                    );

                                    final isSampleProfile = nomePerfil ==
                                        TutorialConfig.sampleProfileName;

                                    if (shouldShowProfileSelectionTutorial &&
                                        isSampleProfile) {
                                      tile = buildTutorialShowcase(
                                        context: context,
                                        key: TutorialKeys.sampleProfileTile,
                                        title: TutorialConfig
                                            .profileSelectionTitle,
                                        description: TutorialConfig
                                            .profileSelectionDescription,
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
                                        onTargetClick: () {
                                          if (perfilSelecionado != nomePerfil) {
                                            setState(() =>
                                                perfilSelecionado = nomePerfil);
                                            showApplyButtonShowcase();
                                          } else {
                                            showApplyButtonShowcase();
                                          }
                                        },
                                        child: tile,
                                      );
                                    }

                                    return tile;
                                  },
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
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                Widget okButton = FilledButton(
                                  onPressed: applySelectedProfile,
                                  child: const Text('OK'),
                                );

                                if (shouldShowProfileSelectionTutorial) {
                                  final theme = Theme.of(context);
                                  final colorScheme = theme.colorScheme;
                                  final textTheme = theme.textTheme;
                                  final isDark =
                                      theme.brightness == Brightness.dark;

                                  okButton = Showcase(
                                    key: TutorialKeys.applyProfileButton,
                                    title: TutorialConfig.profileApplyTitle,
                                    description:
                                        TutorialConfig.profileApplyDescription,
                                    tooltipBackgroundColor:
                                        colorScheme.surfaceContainerHigh,
                                    titleTextStyle:
                                        textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface
                                          .withOpacity(isDark ? 0.92 : 0.86),
                                    ),
                                    descTextStyle:
                                        textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(isDark ? 0.88 : 0.68),
                                      height: 1.35,
                                    ),
                                    tooltipPadding: const EdgeInsets.all(16),
                                    targetShapeBorder: const CircleBorder(),
                                    targetPadding: const EdgeInsets.all(10),
                                    onTargetClick: applySelectedProfile,
                                    disposeOnTap: true,
                                    disableDefaultTargetGestures: false,
                                    overlayColor: colorScheme.scrim
                                        .withOpacity(isDark ? 0.65 : 0.32),
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirmar();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoSalvarPerfil(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salvar Perfil Atual'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nome do Perfil'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(gestaoControllerProvider.notifier)
                  .salvarPerfilAtual(controller.text);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Salvar'),
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

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo, style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Novo nome"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar', style: textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () {
              final novoNome = controller.text;
              if (novoNome.isNotEmpty) {
                onSalvar(novoNome);
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text('Salvar', style: textTheme.labelLarge),
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

  bool _handlePageViewScrollNotification(ScrollNotification notification) {
    if (notification.metrics is PageMetrics) {
      final metrics = notification.metrics as PageMetrics;
      final pageValue = metrics.page;

      if (notification is ScrollUpdateNotification) {
        if (notification.dragDetails != null && pageValue != null) {
          _handleSneakPeekPrefetch(pageValue);
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
        final toastController =
            ref.read(globalToastControllerProvider.notifier);

        if (newState.errorMessage != null &&
            newState.errorMessage != previousState?.errorMessage) {
          toastController.showError(newState.errorMessage!);
          ref.read(gestaoControllerProvider.notifier).clearError();
        }

        if (newState.ultimoProdutoDeletado != null &&
            newState.ultimoProdutoDeletado !=
                previousState?.ultimoProdutoDeletado) {
          final produtoDeletado = newState.ultimoProdutoDeletado!;
          toastController.show(
            '${produtoDeletado.nome} deletado',
            variant: ToastVariant.warning,
            action: ToastAction(
              label: 'Desfazer',
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
      },
    );

    final gestaoState = ref.watch(gestaoControllerProvider);
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

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
            leading: buildTutorialShowcase(
              context: context,
              key: TutorialKeys.menuButton,
              title: TutorialConfig.menuButtonTitle,
              description: TutorialConfig.menuButtonDescription,
              targetShapeBorder: const CircleBorder(),
              onTargetClick: () {
                ShowcaseView.get().dismiss();
                _scaffoldKey.currentState?.openDrawer();
              },
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _scaffoldKey.currentState?.openDrawer();
                },
                splashRadius: 26,
              ),
            ),
            title: Text('Precifica', style: textTheme.titleLarge),
            actions: [
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _compartilharRelatorio(context, ref);
                  },
                  splashRadius: 26,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 2),
                child: buildTutorialShowcase(
                  context: context,
                  key: TutorialKeys.addCategoryButton,
                  title: TutorialConfig.step1Title,
                  description: TutorialConfig.step1Description,
                  targetShapeBorder: const CircleBorder(),
                  onTargetClick: () {
                    ShowcaseView.get().dismiss();
                    _mostrarDialogoNovaCategoria(context, ref);
                  },
                  child: IconButton(
                    icon: const Icon(Icons.add_box_outlined),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _mostrarDialogoNovaCategoria(context, ref);
                    },
                    splashRadius: 26,
                  ),
                ),
              ),
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
                              onNotification:
                                  _handlePageViewScrollNotification,
                              child: PageView.builder(
                                controller: _pageController,
                                physics: const FastPageScrollPhysics(),
                                itemCount: gestaoState.categorias.length,
                                itemBuilder: (context, index) =>
                                    ProductListView(
                                  categoriaId:
                                      gestaoState.categorias[index].id,
                                  onProdutoDoubleTap: (produto) =>
                                      _mostrarDialogoEditarNome(
                                    context,
                                    ref,
                                    titulo: 'Editar Produto',
                                    valorAtual: produto.nome,
                                    onSalvar: (novoNome) => gestaoNotifier
                                        .atualizarNomeProduto(
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
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: buildTutorialShowcase(
                context: context,
                key: TutorialKeys.categoryNavBar,
                title: TutorialConfig.step4Title,
                description: TutorialConfig.step4Description,
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
                      titulo: 'Editar Categoria',
                      valorAtual: categoria.nome,
                      onSalvar: (novoNome) => gestaoNotifier
                          .atualizarNomeCategoria(categoria.id, novoNome),
                    );
                  },
                ),
              ),
            ),
          ),
          floatingActionButton: buildTutorialShowcase(
            context: context,
            key: TutorialKeys.addProductFab,
            title: TutorialConfig.step2Title,
            description: TutorialConfig.step2Description,
            targetShapeBorder: const CircleBorder(),
            targetPadding: const EdgeInsets.all(14),
            onTargetClick: () {
              if (gestaoState.categoriaSelecionadaId != null) {
                ShowcaseView.get().dismiss();
                HapticFeedback.lightImpact();
                _mostrarDialogoNovoProduto(context, ref);
              }
            },
            child: FloatingActionButton(
              heroTag: 'add-product-fab',
              onPressed: gestaoState.categoriaSelecionadaId != null
                  ? () {
                      HapticFeedback.lightImpact();
                      _mostrarDialogoNovoProduto(context, ref);
                    }
                  : null,
              elevation: gestaoState.categoriaSelecionadaId != null ? 3.0 : 0.0,
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
        Positioned.fill(
          child: IgnorePointer(
            child: _SpotlightFadeOverlay(
              rect: _navigationSpotlightRect,
              visible: isNavigationShowcaseActive,
              borderRadius: 28.0,
              overlayColor:
                  colorScheme.scrim.withOpacity(isDark ? 0.65 : 0.32),
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
                  colorScheme.scrim.withOpacity(isDark ? 0.65 : 0.32),
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
            label: const Text('Organizar com IA'),
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
                  title: TutorialConfig.profileDrawerTitle,
                  description: TutorialConfig.profileDrawerDescription,
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(56),
                  ),
                  targetPadding: const EdgeInsets.fromLTRB(52, 18, 148, 18),
                  onTargetClick: () {
                    ShowcaseView.get().dismiss();
                    Navigator.of(drawerContext).pop();
                    _mostrarDialogoGerenciarPerfis(drawerContext, ref);
                  },
                  child: const Text('Gerir Perfis'),
                );
              },
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Configurações'),
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
                  'v${snapshot.data!.version}',
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
        onAcceptWithDetails: (details) {
          HapticFeedback.lightImpact();
          final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
          gestaoNotifier.deletarCategoria(details.data);
          gestaoNotifier.setReordering(false);
        },
      ),
    );
  }

  void _mostrarDialogoNovoProduto(BuildContext pageContext, WidgetRef ref) {
    final controller = TextEditingController();
    final textTheme = Theme.of(pageContext).textTheme;
    final colorScheme = Theme.of(pageContext).colorScheme;

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
          title: Text('Novo Produto', style: textTheme.headlineSmall),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: "Nome do produto",
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
              child: Text('Cancelar', style: textTheme.labelLarge),
            ),
            Builder(
              builder: (context) {
                Widget saveButton = TextButton(
                  onPressed: handleSave,
                  child: Text('Salvar', style: textTheme.labelLarge),
                );

                if (isAwaitingFirstProductTutorial) {
                  saveButton = buildTutorialShowcase(
                    context: context,
                    key: TutorialKeys.productDialogSaveButton,
                    title: TutorialConfig.productSaveTitle,
                    description: TutorialConfig.productSaveDescription,
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
    final nomeProduto = controller.text;
    if (nomeProduto.isNotEmpty) {
      ref.read(gestaoControllerProvider.notifier).criarProduto(nomeProduto);
      Navigator.of(dialogContext).pop();
    }
  }

  void _mostrarDialogoNovaCategoria(BuildContext pageContext, WidgetRef ref) {
    final controller = TextEditingController();
    final textTheme = Theme.of(pageContext).textTheme;
    final colorScheme = Theme.of(pageContext).colorScheme;

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
          title: Text('Nova Categoria', style: textTheme.headlineSmall),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: "Nome da categoria",
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
              child: Text('Cancelar', style: textTheme.labelLarge),
            ),
            Builder(
              builder: (context) {
                Widget saveButton = TextButton(
                  onPressed: handleSave,
                  child: Text('Salvar', style: textTheme.labelLarge),
                );

                if (isAwaitingFirstCategoryTutorial) {
                  saveButton = buildTutorialShowcase(
                    context: context,
                    key: TutorialKeys.categoryDialogSaveButton,
                    title: TutorialConfig.categorySaveTitle,
                    description: TutorialConfig.categorySaveDescription,
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
    final nomeCategoria = controller.text;
    if (nomeCategoria.isNotEmpty) {
      ref.read(gestaoControllerProvider.notifier).criarCategoria(nomeCategoria);
      Navigator.of(dialogContext).pop();
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
                  color: Colors.black.withOpacity(0.3),
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
    this.duration = _GestaoPageState._spotlightFadeDuration,
  });

  final Rect? rect;
  final bool visible;
  final double borderRadius;
  final Color overlayColor;
  final EdgeInsets padding;
  final Duration duration;

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
      duration: duration,
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
        (color.opacity * opacity).clamp(0.0, 1.0).toDouble();
    if (effectiveOpacity <= 0.0) return;

    final overlayPaint = Paint()
      ..color = color.withOpacity(effectiveOpacity)
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
  static const _messages = [
    'Organizando os itens para você...',
    'Analisando categorias e agrupamentos...',
    'Separando os itens com carinho...',
    'Quase pronto! Ajustando os últimos detalhes...'
  ];

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
        _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
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
                          sigmaX: 18 * v,
                          sigmaY: 18 * v,
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
                                color: Colors.black.withValues(alpha: 0.02 * v),
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
                                _messages[_currentMessageIndex],
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
                              'Nossa IA está cuidando de tudo, só um instante.',
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.02),
                ),
              ),
            ),
          ),
          Center(
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
                        'Organizar com IA?',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tem certeza que deseja reorganizar seus produtos automaticamente?',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
                              child: const Text('Cancelar'),
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
                              child: const Text('Confirmar'),
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
        ],
      ),
    );
  }
}

void _compartilharRelatorio(BuildContext context, WidgetRef ref) {
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
