// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Precifica';

  @override
  String get settings => 'Configurações';

  @override
  String get report => 'Relatório';

  @override
  String get reportTemplates => 'Modelos de Relatório';

  @override
  String get defaultTemplate => 'Modelo Padrão';

  @override
  String get visualization => 'Visualização';

  @override
  String get compactMode => 'Modo Compacto';

  @override
  String get compactModeDescription =>
      'Reduz espaçamentos para telas menores e muitos produtos';

  @override
  String get compactModeEnabled => 'Modo compacto ativado';

  @override
  String get compactModeDisabled => 'Modo compacto desativado';

  @override
  String get language => 'Idioma';

  @override
  String get appLanguage => 'Idioma do Aplicativo';

  @override
  String get appLanguageDescription => 'Selecione o idioma da interface';

  @override
  String languageChanged(String language) {
    return 'Idioma alterado para $language';
  }

  @override
  String get resetApp => 'Resetar Aplicativo';

  @override
  String get resetAppTitle => 'Reset do Aplicativo';

  @override
  String get resetAppMessage =>
      'Todos os dados, perfis salvos e preferências serão removidos. O aplicativo ficará como se estivesse sendo aberto pela primeira vez.\n\nEsta ação não pode ser desfeita. Deseja continuar?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get reset => 'Resetar';

  @override
  String get resetError => 'Não foi possível resetar o aplicativo.';

  @override
  String get products => 'Produtos';

  @override
  String get categories => 'Categorias';

  @override
  String get add => 'Adicionar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String get save => 'Salvar';

  @override
  String get name => 'Nome';

  @override
  String get price => 'Preço';

  @override
  String get cost => 'Custo';

  @override
  String get margin => 'Margem';

  @override
  String get search => 'Buscar';

  @override
  String get noResults => 'Nenhum resultado encontrado';

  @override
  String get loading => 'Carregando...';

  @override
  String get error => 'Erro';

  @override
  String get success => 'Sucesso';

  @override
  String get confirm => 'Confirmar';

  @override
  String get close => 'Fechar';

  @override
  String get alwaysUseDefaultTemplateBanner =>
      'Usando sempre o Modelo Padrão ao compartilhar';

  @override
  String get change => 'Alterar';

  @override
  String get newTemplate => 'Novo Modelo';

  @override
  String get notEditable => 'Não editável';

  @override
  String templateSelected(String name) {
    return 'Modelo \"$name\" selecionado';
  }

  @override
  String get noTemplatesFound => 'Nenhum modelo encontrado';

  @override
  String get createFirstTemplateDescription =>
      'Crie seu primeiro modelo para personalizar relatórios.';

  @override
  String get categoryEmoji => 'Emoji da Categoria';

  @override
  String get categoryEmojiHint => 'Ex: ⬇️, 🔽, ou deixe vazio';

  @override
  String get productsToInclude => 'Produtos a Incluir';

  @override
  String get productNameFormat => 'Formato do Nome do Produto';

  @override
  String get firstWordBold => 'Primeira palavra em negrito';

  @override
  String get fullNameBold => 'Nome completo em negrito';

  @override
  String get hidePrices => 'Ocultar Preços';

  @override
  String get hidePricesSubtitle => 'Útil para listas de conferência';

  @override
  String get showCurrencySymbol => 'Mostrar \"R\$\" nos Preços';

  @override
  String get showCurrencySymbolSubtitle =>
      'Se desabilitado, mostra apenas os valores numéricos';

  @override
  String get zeroPriceText => 'Texto para Preço Zerado';

  @override
  String get zeroPriceTextHint => 'Ex: Consulte, A combinar';

  @override
  String get footer => 'Rodapé';

  @override
  String get footerMessage => 'Mensagem de Rodapé';

  @override
  String get footerMessageHint => 'Ex: Peça já! (47) 99999-9999';

  @override
  String get loadingSampleData => 'Carregando dados de exemplo...';

  @override
  String get menuButtonLabel => 'Abrir menu';

  @override
  String get shareButtonLabel => 'Compartilhar relatório';

  @override
  String get addCategoryButtonLabel => 'Adicionar nova categoria';

  @override
  String get addProductButtonLabel => 'Adicionar novo produto';

  @override
  String get editCategoryButtonLabel => 'Editar categoria';

  @override
  String get deleteCategoryButtonLabel => 'Excluir categoria';

  @override
  String categorySelectedAnnouncement(String name) {
    return 'Categoria $name selecionada';
  }

  @override
  String productPriceLabel(String productName, String price) {
    return 'Preço de $productName: $price';
  }

  @override
  String productActiveLabel(String productName) {
    return '$productName, ativo';
  }

  @override
  String productInactiveLabel(String productName) {
    return '$productName, inativo';
  }

  @override
  String get dragToReorderHint =>
      'Pressione e segure para arrastar e reordenar';

  @override
  String get doubleTapToEditHint => 'Toque duas vezes para editar';

  @override
  String get tapToEditPriceHint => 'Toque para editar o preço';

  @override
  String get settingsButtonLabel => 'Abrir configurações';

  @override
  String get aiOrganizeButtonLabel =>
      'Organizar produtos com inteligência artificial';

  @override
  String get profilesButtonLabel => 'Gerenciar perfis salvos';

  @override
  String get closeMenuButtonLabel => 'Fechar menu';

  @override
  String introductionImageLabel(String description) {
    return 'Imagem de introdução: $description';
  }

  @override
  String templateCardLabel(String name) {
    return 'Modelo de relatório: $name';
  }

  @override
  String categoryTabLabel(String name, int position, int total) {
    return 'Aba da categoria $name, $position de $total';
  }

  @override
  String productItemLabel(String name, String price, String status) {
    return '$name, preço $price, $status';
  }

  @override
  String get activeStatus => 'ativo';

  @override
  String get inactiveStatus => 'inativo';

  @override
  String get toggleProductStatusHint =>
      'Toque para alternar entre ativo e inativo';

  @override
  String get swipeToDeleteHint => 'Deslize para a esquerda para excluir';
}
