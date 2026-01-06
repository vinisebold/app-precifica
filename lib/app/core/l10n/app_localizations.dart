import 'package:flutter/material.dart';

/// Supported languages in the app
enum AppLanguage {
  portuguese('pt', 'BR', 'Português'),
  english('en', 'US', 'English'),
  spanish('es', 'ES', 'Español');

  final String languageCode;
  final String countryCode;
  final String displayName;

  const AppLanguage(this.languageCode, this.countryCode, this.displayName);

  Locale get locale => Locale(languageCode, countryCode);

  static AppLanguage fromLocale(Locale locale) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.languageCode == locale.languageCode,
      orElse: () => AppLanguage.portuguese,
    );
  }

  static AppLanguage fromLanguageCode(String? code) {
    if (code == null) return AppLanguage.portuguese;
    return AppLanguage.values.firstWhere(
      (lang) => lang.languageCode == code,
      orElse: () => AppLanguage.portuguese,
    );
  }
}

/// App localizations class
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'pt': {
      // App general
      'appTitle': 'Precifica',
      
      // Settings page
      'settings': 'Configurações',
      'report': 'Relatório',
      'reportTemplates': 'Modelos de Relatório',
      'defaultTemplate': 'Modelo Padrão',
      'visualization': 'Visualização',
      'compactMode': 'Modo Compacto',
      'compactModeDescription': 'Reduz espaçamentos para telas menores e muitos produtos',
      'compactModeEnabled': 'Modo compacto ativado',
      'compactModeDisabled': 'Modo compacto desativado',
      'language': 'Idioma',
      'appLanguage': 'Idioma do Aplicativo',
      'appLanguageDescription': 'Selecione o idioma da interface',
      'languageChanged': 'Idioma alterado para {language}',
      'resetApp': 'Resetar Aplicativo',
      'resetAppTitle': 'Reset do Aplicativo',
      'resetAppMessage': 'Todos os dados, perfis salvos e preferências serão removidos. O aplicativo ficará como se estivesse sendo aberto pela primeira vez.\n\nEsta ação não pode ser desfeita. Deseja continuar?',
      
      // Report settings page
      'customize': 'Personalizar',
      'templateName': 'Nome do Modelo',
      'header': 'Cabeçalho',
      'reportTitle': 'Título do Relatório',
      'reportTitleHint': 'Ex: Preços, Ofertas da Semana',
      'showDayOfWeek': 'Mostrar Dia da Semana',
      'showDate': 'Mostrar Data',
      'groupByCategory': 'Agrupar por Categoria',
      'nameFormat': 'Formato do Nome',
      'normal': 'Normal',
      'uppercase': 'MAIÚSCULAS',
      'bold': 'Negrito',
      'onlyActiveWithPrice': 'Apenas ativos com preço',
      'allActive': 'Todos os ativos',
      'allIncludingInactive': 'Todos (incluindo inativos)',
      'firstWordBold': 'Primeira palavra em negrito',
      'fullNameBold': 'Nome completo em negrito',
      'noFormatting': 'Sem formatação',
      'renameTemplate': 'Renomear Modelo',
      'deleteTemplate': 'Excluir Modelo',
      'deleteTemplateMessage': 'Tem certeza que deseja excluir este modelo?',
      
      // Common buttons
      'cancel': 'Cancelar',
      'reset': 'Resetar',
      'confirm': 'Confirmar',
      'save': 'Salvar',
      'delete': 'Excluir',
      'edit': 'Editar',
      'add': 'Adicionar',
      'close': 'Fechar',
      'ok': 'OK',
      'skip': 'Pular',
      'next': 'Próximo',
      'start': 'Começar',
      'rename': 'Renomear',
      
      // Products and categories
      'products': 'Produtos',
      'categories': 'Categorias',
      'catalogs': 'Catálogos',
      'name': 'Nome',
      'price': 'Preço',
      'cost': 'Custo',
      'margin': 'Margem',
      'newProduct': 'Novo Produto',
      'newCategory': 'Nova Categoria',
      'editProduct': 'Editar Produto',
      'editCategory': 'Editar Categoria',
      'productName': 'Nome do produto',
      'categoryName': 'Nome da categoria',
      'newName': 'Novo nome',
      'productAdded': 'Produto "{name}" adicionado com sucesso!',
      'categoryAdded': 'Categoria "{name}" adicionada com sucesso!',
      'deleted': '{name} deletado',
      'undo': 'Desfazer',
      
      // Profiles
      'importProfile': 'Importar',
      'exportProfile': 'Exportar',
      'saveProfile': 'Salvar',
      'deleteProfile': 'Excluir',
      'loadProfile': 'Carregar Perfil?',
      'loadProfileMessage': 'Isto substituirá todos os seus dados atuais com o perfil "{name}".',
      'deleteProfileTitle': 'Excluir Perfil?',
      'deleteProfileMessage': 'O perfil "{name}" será excluído permanentemente.',
      'saveCurrentProfile': 'Salvar Perfil Atual',
      'profileName': 'Nome do Perfil',
      'noProfilesSaved': 'Nenhum perfil salvo.',
      
      // Sidebar menu
      'organizeWithAI': 'Organizar com IA',
      
      // Share options
      'shareReport': 'Compartilhar Relatório',
      'chooseFormat': 'Escolha o formato para compartilhar',
      'share': 'Compartilhar',
      'shareToWhatsApp': 'Enviar texto para WhatsApp',
      'print': 'Imprimir',
      'generateImage': 'Gerar imagem para impressão',
      
      // Search and status
      'search': 'Buscar',
      'noResults': 'Nenhum resultado encontrado',
      'loading': 'Carregando...',
      'error': 'Erro',
      'success': 'Sucesso',
      'resetError': 'Não foi possível resetar o aplicativo.',
      
      // Introduction pages
      'introTitle1': 'Preços desorganizados?',
      'introBody1': 'Atualizar preços em listas de papel, planilhas ou anotações é trabalhoso e lento.',
      'introTitle2': 'Precifica resolve isso!',
      'introBody2': 'Centralize todos os seus produtos e preços em um só lugar. Organize por categorias de forma prática.',
      'introTitle3': 'Compartilhe facilmente',
      'introBody3': 'Envie suas listas de preços atualizadas pelo WhatsApp ou imprima de forma rápida e profissional.',
      'introTitle4': 'Pronto para começar!',
      'introBody4': 'Vamos configurar seu primeiro catálogo de produtos. É rápido e fácil!',
      
      // AI processing messages
      'aiProcessing1': 'Organizando os itens para você...',
      'aiProcessing2': 'Analisando categorias e agrupamentos...',
      'aiProcessing3': 'Separando os itens com carinho...',
      'aiProcessing4': 'Quase pronto! Ajustando os últimos detalhes...',
      'aiProcessingSubtitle': 'Nossa IA está cuidando de tudo, só um instante.',
      'aiRestoreError': 'Não foi possível restaurar seus dados do tutorial.',
      
      // AI confirmation dialog
      'organizeWithAIQuestion': 'Organizar com IA?',
      'organizeWithAIConfirmation': 'Tem certeza que deseja reorganizar seus produtos automaticamente?',
      
      // Tutorial strings
      'tutorialTitle': 'Bem-vindo',
      'tutorialStep1Title': 'Criar categoria',
      'tutorialStep1Description': 'Toque no botão para criar uma categoria. Use categorias para organizar seus produtos.',
      'tutorialCategorySaveTitle': 'Salvar categoria',
      'tutorialCategorySaveDescription': 'Toque em "Salvar" para concluir a criação desta categoria.',
      'tutorialStep2Title': 'Adicionar produto',
      'tutorialStep2Description': 'Toque no botão para adicionar um produto. Você pode definir o preço depois.',
      'tutorialProductSaveTitle': 'Salvar produto',
      'tutorialProductSaveDescription': 'Toque em "Salvar" para adicionar o novo produto à sua categoria.',
      'tutorialStep3Title': 'Usar perfil pronto',
      'tutorialStep3Description': 'Abra o menu lateral, toque em Gerir Perfis e carregue o perfil Hortifruti para ver produtos de exemplo.',
      'tutorialProfileSelectionTitle': 'Selecione o perfil de exemplo',
      'tutorialProfileSelectionDescription': 'Escolha o perfil "Hortifruti" para carregar uma base pronta de produtos.',
      'tutorialProfileApplyTitle': 'Aplicar perfil',
      'tutorialProfileApplyDescription': 'Depois de selecionar, toque em "OK" para confirmar e carregar os dados.',
      'tutorialStep4Title': 'Mover entre categorias',
      'tutorialStep4Description': 'Use a barra inferior para trocar de categoria. Toque nos ícones para navegar rapidamente.',
      'tutorialStep5Title': 'Deslize a tela',
      'tutorialStep5Description': 'Passe o dedo para a esquerda ou direita sobre os produtos para alternar rapidamente entre as categorias.',
      'tutorialMenuButtonTitle': 'Menu lateral',
      'tutorialMenuButtonDescription': 'Abra o menu lateral para acessar os perfis prontos.',
      'tutorialProfileDrawerTitle': 'Gerir Perfis',
      'tutorialProfileDrawerDescription': 'Toque em "Gerir Perfis" dentro do menu para acessar os perfis prontos.',
      'tutorialFinalTitle': 'Pronto',
      'tutorialFinalDescription': 'Agora você sabe usar o básico. Continue adicionando categorias e produtos.',
      'tutorialButtonNext': 'Próximo',
      'tutorialButtonGotIt': 'Entendi',
      'tutorialButtonFinish': 'Começar',
      'tutorialButtonSkip': 'Pular tutorial',
    },
    'en': {
      // App general
      'appTitle': 'Precifica',
      
      // Settings page
      'settings': 'Settings',
      'report': 'Report',
      'reportTemplates': 'Report Templates',
      'defaultTemplate': 'Default Template',
      'visualization': 'Visualization',
      'compactMode': 'Compact Mode',
      'compactModeDescription': 'Reduces spacing for smaller screens and many products',
      'compactModeEnabled': 'Compact mode enabled',
      'compactModeDisabled': 'Compact mode disabled',
      'language': 'Language',
      'appLanguage': 'App Language',
      'appLanguageDescription': 'Select the interface language',
      'languageChanged': 'Language changed to {language}',
      'resetApp': 'Reset App',
      'resetAppTitle': 'App Reset',
      'resetAppMessage': 'All data, saved profiles and preferences will be removed. The app will be as if it were being opened for the first time.\n\nThis action cannot be undone. Do you want to continue?',
      
      // Report settings page
      'customize': 'Customize',
      'templateName': 'Template Name',
      'header': 'Header',
      'reportTitle': 'Report Title',
      'reportTitleHint': 'Ex: Prices, Weekly Deals',
      'showDayOfWeek': 'Show Day of Week',
      'showDate': 'Show Date',
      'groupByCategory': 'Group by Category',
      'nameFormat': 'Name Format',
      'normal': 'Normal',
      'uppercase': 'UPPERCASE',
      'bold': 'Bold',
      'onlyActiveWithPrice': 'Only active with price',
      'allActive': 'All active',
      'allIncludingInactive': 'All (including inactive)',
      'firstWordBold': 'First word bold',
      'fullNameBold': 'Full name bold',
      'noFormatting': 'No formatting',
      'renameTemplate': 'Rename Template',
      'deleteTemplate': 'Delete Template',
      'deleteTemplateMessage': 'Are you sure you want to delete this template?',
      
      // Common buttons
      'cancel': 'Cancel',
      'reset': 'Reset',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'close': 'Close',
      'ok': 'OK',
      'skip': 'Skip',
      'next': 'Next',
      'start': 'Start',
      'rename': 'Rename',
      
      // Products and categories
      'products': 'Products',
      'categories': 'Categories',
      'catalogs': 'Catalogs',
      'name': 'Name',
      'price': 'Price',
      'cost': 'Cost',
      'margin': 'Margin',
      'newProduct': 'New Product',
      'newCategory': 'New Category',
      'editProduct': 'Edit Product',
      'editCategory': 'Edit Category',
      'productName': 'Product name',
      'categoryName': 'Category name',
      'newName': 'New name',
      'productAdded': 'Product "{name}" added successfully!',
      'categoryAdded': 'Category "{name}" added successfully!',
      'deleted': '{name} deleted',
      'undo': 'Undo',
      
      // Profiles
      'importProfile': 'Import',
      'exportProfile': 'Export',
      'saveProfile': 'Save',
      'deleteProfile': 'Delete',
      'loadProfile': 'Load Profile?',
      'loadProfileMessage': 'This will replace all your current data with the profile "{name}".',
      'deleteProfileTitle': 'Delete Profile?',
      'deleteProfileMessage': 'The profile "{name}" will be permanently deleted.',
      'saveCurrentProfile': 'Save Current Profile',
      'profileName': 'Profile Name',
      'noProfilesSaved': 'No profiles saved.',
      
      // Sidebar menu
      'organizeWithAI': 'Organize with AI',
      
      // Share options
      'shareReport': 'Share Report',
      'chooseFormat': 'Choose the format to share',
      'share': 'Share',
      'shareToWhatsApp': 'Send text to WhatsApp',
      'print': 'Print',
      'generateImage': 'Generate image for printing',
      
      // Search and status
      'search': 'Search',
      'noResults': 'No results found',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'resetError': 'Could not reset the app.',
      
      // Introduction pages
      'introTitle1': 'Disorganized prices?',
      'introBody1': 'Updating prices on paper lists, spreadsheets or notes is laborious and slow.',
      'introTitle2': 'Precifica solves this!',
      'introBody2': 'Centralize all your products and prices in one place. Organize by categories in a practical way.',
      'introTitle3': 'Share easily',
      'introBody3': 'Send your updated price lists via WhatsApp or print quickly and professionally.',
      'introTitle4': 'Ready to start!',
      'introBody4': 'Let\'s set up your first product catalog. It\'s quick and easy!',
      
      // AI processing messages
      'aiProcessing1': 'Organizing items for you...',
      'aiProcessing2': 'Analyzing categories and groupings...',
      'aiProcessing3': 'Separating items with care...',
      'aiProcessing4': 'Almost ready! Adjusting the last details...',
      'aiProcessingSubtitle': 'Our AI is taking care of everything, just a moment.',
      'aiRestoreError': 'Could not restore your tutorial data.',
      
      // AI confirmation dialog
      'organizeWithAIQuestion': 'Organize with AI?',
      'organizeWithAIConfirmation': 'Are you sure you want to automatically reorganize your products?',
      
      // Tutorial strings
      'tutorialTitle': 'Welcome',
      'tutorialStep1Title': 'Create category',
      'tutorialStep1Description': 'Tap the button to create a category. Use categories to organize your products.',
      'tutorialCategorySaveTitle': 'Save category',
      'tutorialCategorySaveDescription': 'Tap "Save" to complete the creation of this category.',
      'tutorialStep2Title': 'Add product',
      'tutorialStep2Description': 'Tap the button to add a product. You can set the price later.',
      'tutorialProductSaveTitle': 'Save product',
      'tutorialProductSaveDescription': 'Tap "Save" to add the new product to your category.',
      'tutorialStep3Title': 'Use a ready profile',
      'tutorialStep3Description': 'Open the side menu, tap Manage Profiles and load the Grocery profile to see sample products.',
      'tutorialProfileSelectionTitle': 'Select sample profile',
      'tutorialProfileSelectionDescription': 'Choose the "Grocery" profile to load a ready product database.',
      'tutorialProfileApplyTitle': 'Apply profile',
      'tutorialProfileApplyDescription': 'After selecting, tap "OK" to confirm and load the data.',
      'tutorialStep4Title': 'Move between categories',
      'tutorialStep4Description': 'Use the bottom bar to switch categories. Tap the icons to navigate quickly.',
      'tutorialStep5Title': 'Swipe the screen',
      'tutorialStep5Description': 'Swipe left or right on the products to quickly switch between categories.',
      'tutorialMenuButtonTitle': 'Side menu',
      'tutorialMenuButtonDescription': 'Open the side menu to access ready profiles.',
      'tutorialProfileDrawerTitle': 'Manage Profiles',
      'tutorialProfileDrawerDescription': 'Tap "Manage Profiles" in the menu to access ready profiles.',
      'tutorialFinalTitle': 'Done',
      'tutorialFinalDescription': 'Now you know the basics. Continue adding categories and products.',
      'tutorialButtonNext': 'Next',
      'tutorialButtonGotIt': 'Got it',
      'tutorialButtonFinish': 'Start',
      'tutorialButtonSkip': 'Skip tutorial',
    },
    'es': {
      // App general
      'appTitle': 'Precifica',
      
      // Settings page
      'settings': 'Configuración',
      'report': 'Informe',
      'reportTemplates': 'Plantillas de Informe',
      'defaultTemplate': 'Plantilla Predeterminada',
      'visualization': 'Visualización',
      'compactMode': 'Modo Compacto',
      'compactModeDescription': 'Reduce el espaciado para pantallas más pequeñas y muchos productos',
      'compactModeEnabled': 'Modo compacto activado',
      'compactModeDisabled': 'Modo compacto desactivado',
      'language': 'Idioma',
      'appLanguage': 'Idioma de la Aplicación',
      'appLanguageDescription': 'Seleccione el idioma de la interfaz',
      'languageChanged': 'Idioma cambiado a {language}',
      'resetApp': 'Restablecer Aplicación',
      'resetAppTitle': 'Restablecer Aplicación',
      'resetAppMessage': 'Todos los datos, perfiles guardados y preferencias se eliminarán. La aplicación estará como si se abriera por primera vez.\n\nEsta acción no se puede deshacer. ¿Desea continuar?',
      
      // Report settings page
      'customize': 'Personalizar',
      'templateName': 'Nombre del Modelo',
      'header': 'Encabezado',
      'reportTitle': 'Título del Informe',
      'reportTitleHint': 'Ej: Precios, Ofertas de la Semana',
      'showDayOfWeek': 'Mostrar Día de la Semana',
      'showDate': 'Mostrar Fecha',
      'groupByCategory': 'Agrupar por Categoría',
      'nameFormat': 'Formato del Nombre',
      'normal': 'Normal',
      'uppercase': 'MAYÚSCULAS',
      'bold': 'Negrita',
      'onlyActiveWithPrice': 'Solo activos con precio',
      'allActive': 'Todos los activos',
      'allIncludingInactive': 'Todos (incluyendo inactivos)',
      'firstWordBold': 'Primera palabra en negrita',
      'fullNameBold': 'Nombre completo en negrita',
      'noFormatting': 'Sin formato',
      'renameTemplate': 'Renombrar Modelo',
      'deleteTemplate': 'Eliminar Modelo',
      'deleteTemplateMessage': '¿Está seguro de que desea eliminar este modelo?',
      
      // Common buttons
      'cancel': 'Cancelar',
      'reset': 'Restablecer',
      'confirm': 'Confirmar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'add': 'Agregar',
      'close': 'Cerrar',
      'ok': 'OK',
      'skip': 'Omitir',
      'next': 'Siguiente',
      'start': 'Comenzar',
      'rename': 'Renombrar',
      
      // Products and categories
      'products': 'Productos',
      'categories': 'Categorías',
      'catalogs': 'Catálogos',
      'name': 'Nombre',
      'price': 'Precio',
      'cost': 'Costo',
      'margin': 'Margen',
      'newProduct': 'Nuevo Producto',
      'newCategory': 'Nueva Categoría',
      'editProduct': 'Editar Producto',
      'editCategory': 'Editar Categoría',
      'productName': 'Nombre del producto',
      'categoryName': 'Nombre de la categoría',
      'newName': 'Nuevo nombre',
      'productAdded': '¡Producto "{name}" agregado con éxito!',
      'categoryAdded': '¡Categoría "{name}" agregada con éxito!',
      'deleted': '{name} eliminado',
      'undo': 'Deshacer',
      
      // Profiles
      'importProfile': 'Importar',
      'exportProfile': 'Exportar',
      'saveProfile': 'Guardar',
      'deleteProfile': 'Eliminar',
      'loadProfile': '¿Cargar Perfil?',
      'loadProfileMessage': 'Esto reemplazará todos sus datos actuales con el perfil "{name}".',
      'deleteProfileTitle': '¿Eliminar Perfil?',
      'deleteProfileMessage': 'El perfil "{name}" se eliminará permanentemente.',
      'saveCurrentProfile': 'Guardar Perfil Actual',
      'profileName': 'Nombre del Perfil',
      'noProfilesSaved': 'No hay perfiles guardados.',
      
      // Sidebar menu
      'organizeWithAI': 'Organizar con IA',
      
      // Share options
      'shareReport': 'Compartir Informe',
      'chooseFormat': 'Elija el formato para compartir',
      'share': 'Compartir',
      'shareToWhatsApp': 'Enviar texto a WhatsApp',
      'print': 'Imprimir',
      'generateImage': 'Generar imagen para impresión',
      
      // Search and status
      'search': 'Buscar',
      'noResults': 'No se encontraron resultados',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'resetError': 'No se pudo restablecer la aplicación.',
      
      // Introduction pages
      'introTitle1': '¿Precios desorganizados?',
      'introBody1': 'Actualizar precios en listas de papel, hojas de cálculo o notas es laborioso y lento.',
      'introTitle2': '¡Precifica resuelve esto!',
      'introBody2': 'Centralice todos sus productos y precios en un solo lugar. Organice por categorías de forma práctica.',
      'introTitle3': 'Comparta fácilmente',
      'introBody3': 'Envíe sus listas de precios actualizadas por WhatsApp o imprima de forma rápida y profesional.',
      'introTitle4': '¡Listo para comenzar!',
      'introBody4': 'Vamos a configurar su primer catálogo de productos. ¡Es rápido y fácil!',
      
      // AI processing messages
      'aiProcessing1': 'Organizando los artículos para usted...',
      'aiProcessing2': 'Analizando categorías y agrupaciones...',
      'aiProcessing3': 'Separando los artículos con cuidado...',
      'aiProcessing4': '¡Casi listo! Ajustando los últimos detalles...',
      'aiProcessingSubtitle': 'Nuestra IA se está encargando de todo, solo un momento.',
      'aiRestoreError': 'No se pudieron restaurar sus datos del tutorial.',
      
      // AI confirmation dialog
      'organizeWithAIQuestion': '¿Organizar con IA?',
      'organizeWithAIConfirmation': '¿Está seguro de que desea reorganizar sus productos automáticamente?',
      
      // Tutorial strings
      'tutorialTitle': 'Bienvenido',
      'tutorialStep1Title': 'Crear categoría',
      'tutorialStep1Description': 'Toque el botón para crear una categoría. Use categorías para organizar sus productos.',
      'tutorialCategorySaveTitle': 'Guardar categoría',
      'tutorialCategorySaveDescription': 'Toque "Guardar" para completar la creación de esta categoría.',
      'tutorialStep2Title': 'Agregar producto',
      'tutorialStep2Description': 'Toque el botón para agregar un producto. Puede definir el precio después.',
      'tutorialProductSaveTitle': 'Guardar producto',
      'tutorialProductSaveDescription': 'Toque "Guardar" para agregar el nuevo producto a su categoría.',
      'tutorialStep3Title': 'Usar perfil listo',
      'tutorialStep3Description': 'Abra el menú lateral, toque Administrar Perfiles y cargue el perfil Frutas y Verduras para ver productos de ejemplo.',
      'tutorialProfileSelectionTitle': 'Seleccione el perfil de ejemplo',
      'tutorialProfileSelectionDescription': 'Elija el perfil "Frutas y Verduras" para cargar una base de datos de productos lista.',
      'tutorialProfileApplyTitle': 'Aplicar perfil',
      'tutorialProfileApplyDescription': 'Después de seleccionar, toque "OK" para confirmar y cargar los datos.',
      'tutorialStep4Title': 'Moverse entre categorías',
      'tutorialStep4Description': 'Use la barra inferior para cambiar de categoría. Toque los íconos para navegar rápidamente.',
      'tutorialStep5Title': 'Deslice la pantalla',
      'tutorialStep5Description': 'Deslice hacia la izquierda o derecha sobre los productos para cambiar rápidamente entre categorías.',
      'tutorialMenuButtonTitle': 'Menú lateral',
      'tutorialMenuButtonDescription': 'Abra el menú lateral para acceder a los perfiles listos.',
      'tutorialProfileDrawerTitle': 'Administrar Perfiles',
      'tutorialProfileDrawerDescription': 'Toque "Administrar Perfiles" en el menú para acceder a los perfiles listos.',
      'tutorialFinalTitle': 'Listo',
      'tutorialFinalDescription': 'Ahora conoce lo básico. Continúe agregando categorías y productos.',
      'tutorialButtonNext': 'Siguiente',
      'tutorialButtonGotIt': 'Entendido',
      'tutorialButtonFinish': 'Comenzar',
      'tutorialButtonSkip': 'Omitir tutorial',
    },
  };

  String _translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['pt']![key] ??
        key;
  }

  // Getters for all translations
  String get appTitle => _translate('appTitle');
  String get settings => _translate('settings');
  String get report => _translate('report');
  String get reportTemplates => _translate('reportTemplates');
  String get defaultTemplate => _translate('defaultTemplate');
  String get visualization => _translate('visualization');
  String get compactMode => _translate('compactMode');
  String get compactModeDescription => _translate('compactModeDescription');
  String get compactModeEnabled => _translate('compactModeEnabled');
  String get compactModeDisabled => _translate('compactModeDisabled');
  String get language => _translate('language');
  String get appLanguage => _translate('appLanguage');
  String get appLanguageDescription => _translate('appLanguageDescription');
  String languageChanged(String language) =>
      _translate('languageChanged').replaceAll('{language}', language);
  String get resetApp => _translate('resetApp');
  String get resetAppTitle => _translate('resetAppTitle');
  String get resetAppMessage => _translate('resetAppMessage');
  String get cancel => _translate('cancel');
  String get reset => _translate('reset');
  String get resetError => _translate('resetError');
  
  // Report settings
  String get customize => _translate('customize');
  String get templateName => _translate('templateName');
  String get header => _translate('header');
  String get reportTitle => _translate('reportTitle');
  String get reportTitleHint => _translate('reportTitleHint');
  String get showDayOfWeek => _translate('showDayOfWeek');
  String get showDate => _translate('showDate');
  String get groupByCategory => _translate('groupByCategory');
  String get nameFormat => _translate('nameFormat');
  String get normal => _translate('normal');
  String get uppercase => _translate('uppercase');
  String get bold => _translate('bold');
  String get onlyActiveWithPrice => _translate('onlyActiveWithPrice');
  String get allActive => _translate('allActive');
  String get allIncludingInactive => _translate('allIncludingInactive');
  String get firstWordBold => _translate('firstWordBold');
  String get fullNameBold => _translate('fullNameBold');
  String get noFormatting => _translate('noFormatting');
  String get renameTemplate => _translate('renameTemplate');
  String get deleteTemplate => _translate('deleteTemplate');
  String get deleteTemplateMessage => _translate('deleteTemplateMessage');
  
  String get products => _translate('products');
  String get categories => _translate('categories');
  String get catalogs => _translate('catalogs');
  String get add => _translate('add');
  String get edit => _translate('edit');
  String get delete => _translate('delete');
  String get save => _translate('save');
  String get name => _translate('name');
  String get price => _translate('price');
  String get cost => _translate('cost');
  String get margin => _translate('margin');
  String get search => _translate('search');
  String get noResults => _translate('noResults');
  String get loading => _translate('loading');
  String get error => _translate('error');
  String get success => _translate('success');
  String get confirm => _translate('confirm');
  String get close => _translate('close');
  String get ok => _translate('ok');
  String get skip => _translate('skip');
  String get next => _translate('next');
  String get start => _translate('start');
  String get rename => _translate('rename');
  
  // Products and categories
  String get newProduct => _translate('newProduct');
  String get newCategory => _translate('newCategory');
  String get editProduct => _translate('editProduct');
  String get editCategory => _translate('editCategory');
  String get productName => _translate('productName');
  String get categoryName => _translate('categoryName');
  String get newName => _translate('newName');
  String productAdded(String name) =>
      _translate('productAdded').replaceAll('{name}', name);
  String categoryAdded(String name) =>
      _translate('categoryAdded').replaceAll('{name}', name);
  String deleted(String name) =>
      _translate('deleted').replaceAll('{name}', name);
  String get undo => _translate('undo');
  
  // Profiles
  String get importProfile => _translate('importProfile');
  String get exportProfile => _translate('exportProfile');
  String get saveProfile => _translate('saveProfile');
  String get deleteProfile => _translate('deleteProfile');
  String get loadProfile => _translate('loadProfile');
  String loadProfileMessage(String name) =>
      _translate('loadProfileMessage').replaceAll('{name}', name);
  String get deleteProfileTitle => _translate('deleteProfileTitle');
  String deleteProfileMessage(String name) =>
      _translate('deleteProfileMessage').replaceAll('{name}', name);
  String get saveCurrentProfile => _translate('saveCurrentProfile');
  String get profileName => _translate('profileName');
  String get noProfilesSaved => _translate('noProfilesSaved');
  
  // Sidebar menu
  String get organizeWithAI => _translate('organizeWithAI');
  
  // Share options
  String get shareReport => _translate('shareReport');
  String get chooseFormat => _translate('chooseFormat');
  String get share => _translate('share');
  String get shareToWhatsApp => _translate('shareToWhatsApp');
  String get print => _translate('print');
  String get generateImage => _translate('generateImage');
  
  // Introduction pages
  String get introTitle1 => _translate('introTitle1');
  String get introBody1 => _translate('introBody1');
  String get introTitle2 => _translate('introTitle2');
  String get introBody2 => _translate('introBody2');
  String get introTitle3 => _translate('introTitle3');
  String get introBody3 => _translate('introBody3');
  String get introTitle4 => _translate('introTitle4');
  String get introBody4 => _translate('introBody4');
  
  // AI processing messages
  String get aiProcessing1 => _translate('aiProcessing1');
  String get aiProcessing2 => _translate('aiProcessing2');
  String get aiProcessing3 => _translate('aiProcessing3');
  String get aiProcessing4 => _translate('aiProcessing4');
  String get aiProcessingSubtitle => _translate('aiProcessingSubtitle');
  String get aiRestoreError => _translate('aiRestoreError');
  
  // AI confirmation dialog
  String get organizeWithAIQuestion => _translate('organizeWithAIQuestion');
  String get organizeWithAIConfirmation => _translate('organizeWithAIConfirmation');
  
  // Tutorial strings
  String get tutorialTitle => _translate('tutorialTitle');
  String get tutorialStep1Title => _translate('tutorialStep1Title');
  String get tutorialStep1Description => _translate('tutorialStep1Description');
  String get tutorialCategorySaveTitle => _translate('tutorialCategorySaveTitle');
  String get tutorialCategorySaveDescription => _translate('tutorialCategorySaveDescription');
  String get tutorialStep2Title => _translate('tutorialStep2Title');
  String get tutorialStep2Description => _translate('tutorialStep2Description');
  String get tutorialProductSaveTitle => _translate('tutorialProductSaveTitle');
  String get tutorialProductSaveDescription => _translate('tutorialProductSaveDescription');
  String get tutorialStep3Title => _translate('tutorialStep3Title');
  String get tutorialStep3Description => _translate('tutorialStep3Description');
  String get tutorialProfileSelectionTitle => _translate('tutorialProfileSelectionTitle');
  String get tutorialProfileSelectionDescription => _translate('tutorialProfileSelectionDescription');
  String get tutorialProfileApplyTitle => _translate('tutorialProfileApplyTitle');
  String get tutorialProfileApplyDescription => _translate('tutorialProfileApplyDescription');
  String get tutorialStep4Title => _translate('tutorialStep4Title');
  String get tutorialStep4Description => _translate('tutorialStep4Description');
  String get tutorialStep5Title => _translate('tutorialStep5Title');
  String get tutorialStep5Description => _translate('tutorialStep5Description');
  String get tutorialMenuButtonTitle => _translate('tutorialMenuButtonTitle');
  String get tutorialMenuButtonDescription => _translate('tutorialMenuButtonDescription');
  String get tutorialProfileDrawerTitle => _translate('tutorialProfileDrawerTitle');
  String get tutorialProfileDrawerDescription => _translate('tutorialProfileDrawerDescription');
  String get tutorialFinalTitle => _translate('tutorialFinalTitle');
  String get tutorialFinalDescription => _translate('tutorialFinalDescription');
  String get tutorialButtonNext => _translate('tutorialButtonNext');
  String get tutorialButtonGotIt => _translate('tutorialButtonGotIt');
  String get tutorialButtonFinish => _translate('tutorialButtonFinish');
  String get tutorialButtonSkip => _translate('tutorialButtonSkip');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['pt', 'en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
