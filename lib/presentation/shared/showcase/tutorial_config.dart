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

  // Textos do tutorial
  static const String tutorialTitle = 'Bem-vindo';

  static const String step1Title = 'Criar categoria';
  static const String step1Description =
      'Toque no botão para criar uma categoria. Use categorias para organizar seus produtos.';

  static const String categorySaveTitle = 'Salvar categoria';
  static const String categorySaveDescription =
      'Toque em "Salvar" para concluir a criação desta categoria.';

  static const String step2Title = 'Adicionar produto';
  static const String step2Description =
      'Toque no botão para adicionar um produto. Você pode definir o preço depois.';

  static const String productSaveTitle = 'Salvar produto';
  static const String productSaveDescription =
      'Toque em "Salvar" para adicionar o novo produto à sua categoria.';

  static const String step3Title = 'Usar perfil pronto';
  static const String step3Description =
      'Abra o menu lateral, toque em Gerir Perfis e carregue o perfil Hortifruti para ver produtos de exemplo.';
  static const String sampleProfileName = 'Hortifruti';
  static const String profileSelectionTitle = 'Selecione o perfil de exemplo';
  static const String profileSelectionDescription =
      'Escolha o perfil "Hortifruti" para carregar uma base pronta de produtos.';
  static const String profileApplyTitle = 'Aplicar perfil';
  static const String profileApplyDescription =
      'Depois de selecionar, toque em "OK" para confirmar e carregar os dados.';

  static const String step4Title = 'Mover entre categorias';
  static const String step4Description =
      'Use a barra inferior para trocar de categoria. Toque nos ícones para navegar rapidamente.';

  static const String step5Title = 'Deslize a tela';
  static const String step5Description =
      'Passe o dedo para a esquerda ou direita sobre os produtos para alternar rapidamente entre as categorias.';

  static const String menuButtonTitle = 'Menu lateral';
  static const String menuButtonDescription =
      'Abra o menu lateral para acessar os perfis prontos.';

  static const String profileDrawerTitle = 'Gerir Perfis';
  static const String profileDrawerDescription =
      'Toque em "Gerir Perfis" dentro do menu para acessar os perfis prontos.';

  static const String finalTitle = 'Pronto';
  static const String finalDescription =
      'Agora você sabe usar o básico. Continue adicionando categorias e produtos.';

  static const String buttonNext = 'Próximo';
  static const String buttonGotIt = 'Entendi';
  static const String buttonFinish = 'Começar';
  static const String buttonSkip = 'Pular tutorial';
}
