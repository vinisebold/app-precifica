import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:precifica/app/core/snackbar/app_snackbar.dart';
import 'package:precifica/app/core/l10n/app_localizations.dart';

import 'gestao_controller.dart';
import 'gestao_state.dart';

// Mixins
import 'mixins/tutorial_mixin.dart';
import 'mixins/spotlight_mixin.dart';

// Dialogs
import 'dialogs/gestao_dialogs.dart';

// Widgets
import 'widgets/categoria_nav_bar.dart';
import 'widgets/product_list_view.dart';
import 'widgets/gestao_overlays.dart';
import 'widgets/gestao_widgets.dart';
import 'widgets/hard_stop_page_view.dart';

// Utils
import 'utils/share_utils.dart';

// Shared
import '../shared/showcase/tutorial_controller.dart';
import '../shared/showcase/tutorial_keys.dart';
import '../shared/showcase/tutorial_config.dart';
import '../shared/showcase/tutorial_widgets.dart';
import '../shared/providers/auto_hide_category_bar_provider.dart';

class GestaoPage extends ConsumerStatefulWidget {
  const GestaoPage({super.key});

  @override
  ConsumerState<GestaoPage> createState() => _GestaoPageState();
}

class _GestaoPageState extends ConsumerState<GestaoPage>
    with TutorialMixin, SpotlightMixin {
  final GlobalKey<HardStopPageViewState> _pageViewKey =
      GlobalKey<HardStopPageViewState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _lastSettledPageIndex;

  bool _isAddProductFabVisible = true;
  bool _isCategoryNavBarVisible = true;

  @override
  void initState() {
    super.initState();

    // Registra o ShowcaseView com floating action widget para o botão skip
    ShowcaseView.register(
      globalFloatingActionWidget: (showcaseContext) {
        final tutorialState = ref.read(tutorialControllerProvider);
        
        if (tutorialState.isActive &&
            tutorialState.currentStep == TutorialStep.awaitingFirstCategory) {
          return FloatingActionWidget(
            bottom: 24,
            left: 16,
            child: SkipTutorialButton(
              onSkip: () async {
                await ref.read(tutorialControllerProvider.notifier).skipTutorial();
              },
            ),
          );
        }
        
        // Retornar um widget vazio quando não deve mostrar
        return const FloatingActionWidget(
          bottom: 24,
          left: 16,
          child: SizedBox.shrink(),
        );
      },
    );

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
        _pageViewKey.currentState?.jumpToPage(initialPage);
        _prefetchAdjacent(initialPage);
      }

      initTutorial();
    });
  }

  @override
  void dispose() {
    disposeTutorial();
    disposeSpotlight();
    super.dispose();
  }

  void _prefetchAdjacent(int centerIndex) {
    final notifier = ref.read(gestaoControllerProvider.notifier);
    notifier.prefetchCategoriaPorIndice(centerIndex - 1);
    notifier.prefetchCategoriaPorIndice(centerIndex + 1);
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

    // Garante que ambos (FAB e barra) sigam juntos
    if (_isAddProductFabVisible == targetVisibility &&
        _isCategoryNavBarVisible == targetVisibility) {
      return;
    }
    setState(() {
      _isAddProductFabVisible = targetVisibility;
      _isCategoryNavBarVisible = targetVisibility;
    });
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

    // Gerenciamento de spotlight
    if (isNavigationShowcaseActive) {
      scheduleNavigationSpotlightUpdate();
    } else {
      clearNavigationSpotlightRect();
    }

    if (isSwipeShowcaseActive) {
      scheduleSwipeSpotlightUpdate();
    } else {
      clearSwipeSpotlightRect();
    }

    // Listeners
    _setupGestaoStateListener();
    _setupTutorialStateListener();

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
              return GestaoSidebarMenu(
                gestaoState: gestaoState,
                scaffoldKey: _scaffoldKey,
                hasShownDrawerShowcase: () => hasShownDrawerShowcase,
                setHasShownDrawerShowcase: (v) => hasShownDrawerShowcase = v,
                hasShownProfileSelectionTutorial: () =>
                    hasShownProfileSelectionTutorial,
                setHasShownProfileSelectionTutorial: (v) =>
                    hasShownProfileSelectionTutorial = v,
              );
            },
          ),
          onDrawerChanged: (isOpened) => _handleDrawerChanged(isOpened),
            appBar:
              _buildAppBar(context, gestaoState, gestaoNotifier, l10n, textTheme),
          body: _buildBody(
              context, gestaoState, gestaoNotifier, isSwipeShowcaseActive),
          bottomNavigationBar: _buildBottomNavigationBar(
              context, gestaoNotifier, autoHideCategoryBar),
          floatingActionButton:
              _buildFloatingActionButton(context, gestaoState, l10n, colorScheme),
        ),
        // Spotlights
        Positioned.fill(
          child: IgnorePointer(
            child: SpotlightFadeOverlay(
              rect: navigationSpotlightRect,
              visible: isNavigationShowcaseActive,
              borderRadius: 28.0,
              overlayColor:
                  colorScheme.scrim.withValues(alpha: isDark ? 0.65 : 0.32),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: SpotlightFadeOverlay(
              rect: swipeSpotlightRect,
              visible: isSwipeShowcaseActive,
              borderRadius: 18.0,
              overlayColor:
                  colorScheme.scrim.withValues(alpha: isDark ? 0.65 : 0.32),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            ),
          ),
        ),
        GlobalProcessingOverlay(active: gestaoState.isLoading),
      ],
    );
  }

  void _handleDrawerChanged(bool isOpened) {
    if (!mounted) return;
    final tutorialState = ref.read(tutorialControllerProvider);

    if (isOpened &&
        tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.showSampleProfile &&
        !hasShownDrawerShowcase) {
      hasShownDrawerShowcase = true;

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
  }

  void _setupGestaoStateListener() {
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
            l10n?.deleted(produtoDeletado.nome) ??
                '${produtoDeletado.nome} deletado',
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
            final currentPageState = _pageViewKey.currentState;
            if (currentPageState != null &&
                currentPageState.page != newIndex) {
              currentPageState.jumpToPage(newIndex);
            }
          }

          final tutorialState = ref.read(tutorialControllerProvider);
          if (tutorialState.isActive) {
            if (tutorialState.currentStep == TutorialStep.showNavigation) {
              scheduleNavigationShowcaseDismiss();
            } else if (tutorialState.currentStep == TutorialStep.showSwipe) {
              scheduleSwipeShowcaseDismiss();
            }
          }
        }

        // Tutorial: detecta criação de categorias e produtos
        final tutorialNotifier = ref.read(tutorialControllerProvider.notifier);
        final tutorialState = ref.read(tutorialControllerProvider);

        if (tutorialState.isActive) {
          if (newState.categorias.length >
              (previousState?.categorias.length ?? 0)) {
            tutorialNotifier.onCategoryCreated();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                showTutorialStep(
                    ref.read(tutorialControllerProvider).currentStep);
              }
            });
          }

          if (newState.produtos.length >
              (previousState?.produtos.length ?? 0)) {
            final existingSnapshot = tutorialState.userDataSnapshot;
            final shouldCaptureSnapshot =
                (existingSnapshot == null || existingSnapshot.isEmpty) &&
                    newState.perfilAtual == null &&
                    newState.categorias.isNotEmpty;

            if (shouldCaptureSnapshot) {
              final snapshot = buildTutorialUserSnapshot(newState);
              if (snapshot.isNotEmpty) {
                tutorialNotifier.setUserDataSnapshot(snapshot);
              }
            }

            tutorialNotifier.onProductCreated();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                showTutorialStep(
                    ref.read(tutorialControllerProvider).currentStep);
              }
            });
          }

          final previousProfile = previousState?.perfilAtual;
          final newProfile = newState.perfilAtual;
          if (tutorialState.currentStep == TutorialStep.showSampleProfile &&
              newProfile != null &&
              newProfile != previousProfile) {
            ShowcaseView.get().dismiss();
            tutorialNotifier.onSampleProfileLoaded();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                showTutorialStep(
                    ref.read(tutorialControllerProvider).currentStep);
              }
            });
          }
        }
      },
    );
  }

  void _setupTutorialStateListener() {
    ref.listen<TutorialState>(
      tutorialControllerProvider,
      (previousState, newState) {
        if (previousState?.currentStep == TutorialStep.showNavigation &&
            newState.currentStep != TutorialStep.showNavigation) {
          cancelNavigationShowcaseTimers();
        }

        if (previousState?.currentStep == TutorialStep.showSwipe &&
            newState.currentStep != TutorialStep.showSwipe) {
          cancelSwipeShowcaseTimers();
        }

        if (newState.isActive &&
            previousState?.currentStep != newState.currentStep) {
          showTutorialStep(newState.currentStep);
          
          // Reinserir o botão skip sempre que o tutorial muda de passo
          // para garantir que fica acima do showcase
          if (newState.currentStep == TutorialStep.awaitingFirstCategory) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }
        }

        if (newState.isActive &&
            newState.currentStep == TutorialStep.awaitingFirstCategory &&
            previousState?.currentStep != TutorialStep.awaitingFirstCategory) {
          hasShownCompletionScreen = false;
        }

        if (newState.currentStep == TutorialStep.completed &&
            previousState?.currentStep != TutorialStep.completed) {
          showTutorialCompletionScreen();
        }
      },
    );
  }

  AppBar _buildAppBar(
      BuildContext context,
      GestaoState gestaoState,
      GestaoController gestaoNotifier,
      AppLocalizations l10n,
      TextTheme textTheme) {
    final colorScheme = Theme.of(context).colorScheme;

    if (gestaoState.produtosSelecionados.isNotEmpty) {
      return _buildSelectionAppBar(
        context,
        gestaoState,
        gestaoNotifier,
        colorScheme,
        textTheme,
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
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
            ShareUtils.mostrarOpcoesCompartilhamento(context, ref);
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
            GestaoDialogs.mostrarDialogoNovaCategoria(
              pageContext: context,
              ref: ref,
              isMounted: () => mounted,
              onCategorySaved: () {},
            );
          },
          child: IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: l10n.addCategoryButtonLabel,
            onPressed: () {
              HapticFeedback.lightImpact();
              GestaoDialogs.mostrarDialogoNovaCategoria(
                pageContext: context,
                ref: ref,
                isMounted: () => mounted,
                onCategorySaved: () {},
              );
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
    );
  }

  AppBar _buildSelectionAppBar(
    BuildContext context,
    GestaoState gestaoState,
    GestaoController gestaoNotifier,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final selectedCount = gestaoState.produtosSelecionados.length;
    final selectionLabel =
        '$selectedCount selecionado${selectedCount == 1 ? '' : 's'}';

    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Cancelar seleção',
        onPressed: () {
          HapticFeedback.lightImpact();
          gestaoNotifier.limparSelecaoProdutos();
        },
        splashRadius: 24,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
      ),
      title: Text(
        selectionLabel,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Deletar selecionados',
          onPressed: selectedCount == 0
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  gestaoNotifier.deletarProdutosSelecionados();
                },
          splashRadius: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Mais opções',
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'select_all') {
              HapticFeedback.selectionClick();
              gestaoNotifier.selecionarTodosProdutosDaCategoriaAtual();
            } else if (value == 'clear') {
              HapticFeedback.selectionClick();
              gestaoNotifier.limparSelecaoProdutos();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'select_all',
              child: Text('Selecionar todos'),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Text('Limpar seleção'),
            ),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildBody(BuildContext context, GestaoState gestaoState,
      GestaoController gestaoNotifier, bool isSwipeShowcaseActive) {
    final colorScheme = Theme.of(context).colorScheme;

    // O padding horizontal da lista deve ser refletido no borderRadius do container,
    // para que o inner radius dos itens acompanhe o padding.
    const double horizontalListPadding = 8.0; // mesmo valor do padding/margin horizontal da lista
    const double containerRadius = 16.0; // valor maior para harmonizar com o padding
    return Container(
      margin: const EdgeInsets.fromLTRB(horizontalListPadding, 0, horizontalListPadding, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(containerRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(containerRadius),
        child: Stack(
          children: [
            if (gestaoState.categorias.isNotEmpty)
              Showcase.withWidget(
                key: TutorialKeys.categorySwipeArea,
                targetShapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(containerRadius),
                ),
                targetBorderRadius: BorderRadius.circular(12.0),
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
                      child: HardStopPageView(
                        key: _pageViewKey,
                        itemCount: gestaoState.categorias.length,
                        initialPage: _lastSettledPageIndex ?? 0,
                        onPageChanged: (index) {
                          _settleToPage(index);
                          // Mostrar FAB e NavBar ao mudar de página
                          if (!_isCategoryNavBarVisible ||
                              !_isAddProductFabVisible) {
                            setState(() {
                              _isCategoryNavBarVisible = true;
                              _isAddProductFabVisible = true;
                            });
                          }
                        },
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: ProductListView(
                            onFabVisibilityRequest: _handleFabVisibilityRequest,
                            categoriaId: gestaoState.categorias[index].id,
                            forceBarVisible: _isCategoryNavBarVisible,
                            onProdutoDoubleTap: (produto) =>
                                GestaoDialogs.mostrarDialogoEditarNome(
                              context,
                              ref,
                              titulo: AppLocalizations.of(context)?.editProduct ??
                                  'Editar Produto',
                              valorAtual: produto.nome,
                              onSalvar: (novoNome) => gestaoNotifier
                                  .atualizarNomeProduto(produto.id, novoNome),
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
                            child: SwipeGestureGuide(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (gestaoState.isReordering) CategoryDeleteArea(ref: ref),
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
                      ? ProductDeleteArea(ref: ref)
                      : const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context,
      GestaoController gestaoNotifier, bool autoHideCategoryBar) {
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor:
            (!autoHideCategoryBar || _isCategoryNavBarVisible) ? 1.0 : 0.0,
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
                  GestaoDialogs.mostrarDialogoEditarNome(
                    context,
                    ref,
                    titulo: AppLocalizations.of(context)?.editCategory ??
                        'Editar Categoria',
                    valorAtual: categoria.nome,
                    onSalvar: (novoNome) => gestaoNotifier.atualizarNomeCategoria(
                        categoria.id, novoNome),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context,
      GestaoState gestaoState, AppLocalizations l10n, ColorScheme colorScheme) {
    return Builder(
      builder: (context) {
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
              GestaoDialogs.mostrarDialogoNovoProduto(
                pageContext: context,
                ref: ref,
                isMounted: () => mounted,
                onProductSaved: () {},
              );
            }
          },
          child: Semantics(
            button: true,
            enabled: gestaoState.categoriaSelecionadaId != null,
            label: l10n.addProductButtonLabel,
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
                          GestaoDialogs.mostrarDialogoNovoProduto(
                            pageContext: context,
                            ref: ref,
                            isMounted: () => mounted,
                            onProductSaved: () {},
                          );
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
    );
  }
}
