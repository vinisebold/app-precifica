import 'package:flutter/material.dart';
import 'package:precifica/app/core/l10n/app_localizations.dart';

/// Configurações visuais e comportamentais para o tutorial.
class TutorialConfig {
  // Cores
  // Cores derivadas em runtime a partir do tema ativo (veja `tutorial_widgets.dart`).

  // Espaçamentos
  static const double tooltipPadding = 16.0;
  static const double tooltipRadius = 12.0;
  static const double tooltipActionSpacing = 12.0;

  // Animações
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration tooltipDelay = Duration(milliseconds: 500);

  // Comportamento do Showcase
  static const bool disableBarrierInteraction =
      true; // Permite clicar nos widgets
  static const bool disableDefaultTargetGestures =
      false; // Mantém gestos do widget
  static const Duration autoAdvanceDelay =
      Duration(seconds: 8); // Avança automaticamente se não interagir

  // Profile name (não traduzido pois é um identificador)
  static const String sampleProfileName = 'Hortifruti';

  // Métodos para obter textos localizados
  static String tutorialTitle(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialTitle ?? 'Bem-vindo';

  static String step1Title(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialStep1Title ?? 'Criar categoria';
  static String step1Description(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialStep1Description ??
      'Toque no botão para criar uma categoria. Use categorias para organizar seus produtos.';

  static String categorySaveTitle(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialCategorySaveTitle ?? 'Salvar categoria';
  static String categorySaveDescription(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialCategorySaveDescription ??
      'Toque em "Salvar" para concluir a criação desta categoria.';

  static String step2Title(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialStep2Title ?? 'Adicionar produto';
  static String step2Description(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialStep2Description ??
      'Toque no botão para adicionar um produto. Você pode definir o preço depois.';

  static String productSaveTitle(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialProductSaveTitle ?? 'Salvar produto';
  static String productSaveDescription(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialProductSaveDescription ??
      'Toque em "Salvar" para adicionar o novo produto à sua categoria.';

  static String step3Title(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialStep3Title ?? 'Usar perfil pronto';
  static String step3Description(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialStep3Description ??
      'Abra o menu lateral, toque em Gerir Perfis e carregue o perfil Hortifruti para ver produtos de exemplo.';
  static String profileSelectionTitle(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialProfileSelectionTitle ?? 'Selecione o perfil de exemplo';
  static String profileSelectionDescription(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialProfileSelectionDescription ??
      'Escolha o perfil "Hortifruti" para carregar uma base pronta de produtos.';
  static String profileApplyTitle(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialProfileApplyTitle ?? 'Aplicar perfil';
  static String profileApplyDescription(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialProfileApplyDescription ??
      'Depois de selecionar, toque em "OK" para confirmar e carregar os dados.';

  static String step4Title(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialStep4Title ?? 'Mover entre categorias';
  static String step4Description(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialStep4Description ??
      'Use a barra inferior para trocar de categoria. Toque nos ícones para navegar rapidamente.';

  static String step5Title(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialStep5Title ?? 'Deslize a tela';
  static String step5Description(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialStep5Description ??
      'Passe o dedo para a esquerda ou direita sobre os produtos para alternar rapidamente entre as categorias.';

  static String menuButtonTitle(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialMenuButtonTitle ?? 'Menu lateral';
  static String menuButtonDescription(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialMenuButtonDescription ??
      'Abra o menu lateral para acessar os perfis prontos.';

  static String profileDrawerTitle(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialProfileDrawerTitle ?? 'Gerir Perfis';
  static String profileDrawerDescription(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialProfileDrawerDescription ??
      'Toque em "Gerir Perfis" dentro do menu para acessar os perfis prontos.';

  static String finalTitle(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialFinalTitle ?? 'Pronto';
  static String finalDescription(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialFinalDescription ??
      'Agora você sabe usar o básico. Continue adicionando categorias e produtos.';

  static String buttonNext(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialButtonNext ?? 'Próximo';
  static String buttonGotIt(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialButtonGotIt ?? 'Entendi';
  static String buttonFinish(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialButtonFinish ?? 'Começar';
  static String buttonSkip(BuildContext context) =>
      AppLocalizations.of(context)?.tutorialButtonSkip ?? 'Pular tutorial';
}
