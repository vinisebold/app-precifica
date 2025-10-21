import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tutorial_service.dart';

/// Estados possíveis do tutorial.
enum TutorialStep {
  notStarted,
  awaitingFirstCategory,
  awaitingFirstProduct,
  showSampleProfile,
  showNavigation,
  completed,
}

/// Estado do tutorial.
class TutorialState {
  final TutorialStep currentStep;
  final bool isActive;
  final int categoriesCreated;
  final int productsCreated;
  final bool sampleProfileLoaded;

  const TutorialState({
    this.currentStep = TutorialStep.notStarted,
    this.isActive = false,
    this.categoriesCreated = 0,
    this.productsCreated = 0,
    this.sampleProfileLoaded = false,
  });

  TutorialState copyWith({
    TutorialStep? currentStep,
    bool? isActive,
    int? categoriesCreated,
    int? productsCreated,
    bool? sampleProfileLoaded,
  }) {
    return TutorialState(
      currentStep: currentStep ?? this.currentStep,
      isActive: isActive ?? this.isActive,
      categoriesCreated: categoriesCreated ?? this.categoriesCreated,
      productsCreated: productsCreated ?? this.productsCreated,
      sampleProfileLoaded: sampleProfileLoaded ?? this.sampleProfileLoaded,
    );
  }
}

/// Controller para gerenciar o tutorial.
class TutorialController extends Notifier<TutorialState> {
  late final TutorialService _service;

  @override
  TutorialState build() {
    _service = ref.watch(tutorialServiceProvider);
    return const TutorialState();
  }

  /// Inicia o tutorial.
  Future<void> startTutorial() async {
    state = state.copyWith(
      isActive: true,
      currentStep: TutorialStep.awaitingFirstCategory,
      categoriesCreated: 0,
      productsCreated: 0,
      sampleProfileLoaded: false,
    );
  }

  /// Avança para o próximo passo baseado na ação do usuário.
  void onCategoryCreated() {
    final newCount = state.categoriesCreated + 1;
    
    if (state.currentStep == TutorialStep.awaitingFirstCategory && newCount >= 1) {
      state = state.copyWith(
        categoriesCreated: newCount,
        currentStep: TutorialStep.awaitingFirstProduct,
      );
    } else {
      state = state.copyWith(categoriesCreated: newCount);
    }
  }

  void onProductCreated() {
    final newCount = state.productsCreated + 1;
    
    if (state.currentStep == TutorialStep.awaitingFirstProduct && newCount >= 1) {
      state = state.copyWith(
        productsCreated: newCount,
        currentStep: TutorialStep.showSampleProfile,
      );
    } else {
      state = state.copyWith(productsCreated: newCount);
    }
  }

  void onSampleProfileLoaded() {
    if (state.currentStep == TutorialStep.showSampleProfile && !state.sampleProfileLoaded) {
      state = state.copyWith(
        sampleProfileLoaded: true,
        currentStep: TutorialStep.showNavigation,
      );
    }
  }

  /// Avança manualmente para o próximo passo (quando usuário clica "Próximo").
  void nextStep() {
    switch (state.currentStep) {
      case TutorialStep.showNavigation:
        _completeTutorial();
        break;
      default:
        break;
    }
  }

  /// Completa o tutorial.
  Future<void> _completeTutorial() async {
    await _service.setTutorialCompleted();
    state = state.copyWith(
      currentStep: TutorialStep.completed,
      isActive: false,
    );
  }

  /// Pula o tutorial.
  Future<void> skipTutorial() async {
    await _service.setTutorialCompleted();
    state = state.copyWith(
      currentStep: TutorialStep.completed,
      isActive: false,
    );
  }

  /// Verifica se deve iniciar o tutorial automaticamente.
  Future<void> checkAndStartTutorial() async {
    final completed = await _service.isTutorialCompleted();
    if (!completed) {
      await startTutorial();
    }
  }

  /// Reseta o tutorial (para testes ou visualização novamente).
  Future<void> resetTutorial() async {
    await _service.resetTutorial();
    state = const TutorialState();
  }
}

/// Provider para o serviço de tutorial.
final tutorialServiceProvider = Provider<TutorialService>((ref) {
  return TutorialService();
});

/// Provider para o controller do tutorial.
final tutorialControllerProvider =
    NotifierProvider<TutorialController, TutorialState>(TutorialController.new);
