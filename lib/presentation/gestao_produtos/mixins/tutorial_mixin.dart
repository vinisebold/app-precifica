import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:precifica/app/core/l10n/app_localizations.dart';
import 'package:precifica/app/core/snackbar/app_snackbar.dart';
import 'package:precifica/domain/entities/produto.dart';

import '../gestao_controller.dart';
import '../gestao_state.dart';
import '../../shared/showcase/tutorial_controller.dart';
import '../../shared/showcase/tutorial_config.dart';
import '../../shared/showcase/tutorial_keys.dart';
import '../../shared/showcase/tutorial_overlay.dart';

/// Mixin que encapsula toda a lógica relacionada ao tutorial interativo
/// da página de gestão de produtos.
mixin TutorialMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _hasShownDrawerShowcase = false;
  bool _hasShownProfileSelectionTutorial = false;
  bool _hasShownCompletionScreen = false;

  Timer? _navigationShowcaseDismissTimer;
  Timer? _navigationShowcaseAutoAdvanceTimer;
  Timer? _swipeShowcaseDismissTimer;
  Timer? _swipeShowcaseAutoAdvanceTimer;

  bool get hasShownDrawerShowcase => _hasShownDrawerShowcase;
  set hasShownDrawerShowcase(bool value) => _hasShownDrawerShowcase = value;

  bool get hasShownProfileSelectionTutorial => _hasShownProfileSelectionTutorial;
  set hasShownProfileSelectionTutorial(bool value) =>
      _hasShownProfileSelectionTutorial = value;

  bool get hasShownCompletionScreen => _hasShownCompletionScreen;
  set hasShownCompletionScreen(bool value) => _hasShownCompletionScreen = value;

  /// Callback para ser chamado quando as categorias mudam (para verificar criação de categoria)
  void Function()? onCategoryCreatedCallback;

  /// Callback para ser chamado quando produtos são criados
  void Function()? onProductCreatedCallback;

  void initTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() async {
        await ref
            .read(tutorialControllerProvider.notifier)
            .checkAndStartTutorial();
      });
    });
  }

  void disposeTutorial() {
    cancelNavigationShowcaseTimers();
    cancelSwipeShowcaseTimers();
  }

  void showTutorialStep(TutorialStep step) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (step) {
        case TutorialStep.awaitingFirstCategory:
          showCreateCategoryShowcase();
          break;
        case TutorialStep.awaitingFirstProduct:
          showCreateProductShowcase();
          break;
        case TutorialStep.showSampleProfile:
          showSampleProfileTutorial();
          break;
        case TutorialStep.showNavigation:
          showNavigationShowcase();
          break;
        case TutorialStep.showSwipe:
          showSwipeShowcase();
          break;
        default:
          break;
      }
    });
  }

  void showCreateCategoryShowcase() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([TutorialKeys.addCategoryButton]);
    });
  }

  void showCreateProductShowcase() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([TutorialKeys.addProductFab]);
    });
  }

  void showSampleProfileTutorial() {
    _hasShownDrawerShowcase = false;
    _hasShownProfileSelectionTutorial = false;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([TutorialKeys.menuButton]);
    });
  }

  void showNavigationShowcase() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([TutorialKeys.categoryNavBar]);
      _navigationShowcaseAutoAdvanceTimer?.cancel();
      _navigationShowcaseAutoAdvanceTimer =
          Timer(TutorialConfig.autoAdvanceDelay, () {
        if (!mounted) return;
        final tutorialState = ref.read(tutorialControllerProvider);
        if (tutorialState.currentStep == TutorialStep.showNavigation) {
          completeNavigationStep();
        }
      });
    });
  }

  void showSwipeShowcase() {
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
          completeSwipeStep();
        }
      });
    });
  }

  void scheduleNavigationShowcaseDismiss() {
    if (_navigationShowcaseDismissTimer?.isActive ?? false) return;

    _navigationShowcaseDismissTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final tutorialState = ref.read(tutorialControllerProvider);
      if (tutorialState.currentStep == TutorialStep.showNavigation) {
        completeNavigationStep();
      }
    });
  }

  void cancelNavigationShowcaseTimers() {
    _navigationShowcaseDismissTimer?.cancel();
    _navigationShowcaseDismissTimer = null;
    _navigationShowcaseAutoAdvanceTimer?.cancel();
    _navigationShowcaseAutoAdvanceTimer = null;
  }

  void cancelSwipeShowcaseTimers() {
    _swipeShowcaseDismissTimer?.cancel();
    _swipeShowcaseDismissTimer = null;
    _swipeShowcaseAutoAdvanceTimer?.cancel();
    _swipeShowcaseAutoAdvanceTimer = null;
  }

  void completeNavigationStep() {
    if (!mounted) {
      cancelNavigationShowcaseTimers();
      return;
    }

    final tutorialState = ref.read(tutorialControllerProvider);
    if (tutorialState.currentStep != TutorialStep.showNavigation) {
      cancelNavigationShowcaseTimers();
      return;
    }

    cancelNavigationShowcaseTimers();
    ShowcaseView.get().dismiss();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentStep = ref.read(tutorialControllerProvider).currentStep;
      if (currentStep == TutorialStep.showNavigation) {
        ref.read(tutorialControllerProvider.notifier).nextStep();
      }
    });
  }

  void scheduleSwipeShowcaseDismiss() {
    if (_swipeShowcaseDismissTimer?.isActive ?? false) return;

    _swipeShowcaseDismissTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final tutorialState = ref.read(tutorialControllerProvider);
      if (tutorialState.currentStep == TutorialStep.showSwipe) {
        completeSwipeStep();
      }
    });
  }

  void completeSwipeStep() {
    if (!mounted) {
      cancelSwipeShowcaseTimers();
      return;
    }

    final tutorialState = ref.read(tutorialControllerProvider);
    if (tutorialState.currentStep != TutorialStep.showSwipe) {
      cancelSwipeShowcaseTimers();
      return;
    }

    cancelSwipeShowcaseTimers();
    ShowcaseView.get().dismiss();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final currentStep = ref.read(tutorialControllerProvider).currentStep;
      if (currentStep == TutorialStep.showSwipe) {
        ref.read(tutorialControllerProvider.notifier).nextStep();
      }
    });
  }

  List<Map<String, dynamic>> buildTutorialUserSnapshot(GestaoState state) {
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

  void showTutorialCompletionScreen() {
    if (_hasShownCompletionScreen || !mounted) return;
    _hasShownCompletionScreen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseView.get().dismiss();
      showTutorialInstruction(
        context: context,
        title: TutorialConfig.finalTitle(context),
        message: TutorialConfig.finalDescription(context),
        onDismiss: handleTutorialCompletion,
        barrierDismissible: false,
      );
    });
  }

  void handleTutorialCompletion() {
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
            l10n?.aiRestoreError ??
                'Não foi possível restaurar seus dados do tutorial.',
          );
        }
      } finally {
        ref.read(tutorialControllerProvider.notifier).clearUserDataSnapshot();
      }
    });
  }
}
