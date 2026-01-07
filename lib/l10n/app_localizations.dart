import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// The title of the application
  ///
  /// In pt, this message translates to:
  /// **'Precifica'**
  String get appTitle;

  /// Settings page title
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings;

  /// Report section header
  ///
  /// In pt, this message translates to:
  /// **'Relatório'**
  String get report;

  /// Report templates option
  ///
  /// In pt, this message translates to:
  /// **'Modelos de Relatório'**
  String get reportTemplates;

  /// Default template name
  ///
  /// In pt, this message translates to:
  /// **'Modelo Padrão'**
  String get defaultTemplate;

  /// Visualization section header
  ///
  /// In pt, this message translates to:
  /// **'Visualização'**
  String get visualization;

  /// Compact mode option
  ///
  /// In pt, this message translates to:
  /// **'Modo Compacto'**
  String get compactMode;

  /// Compact mode description
  ///
  /// In pt, this message translates to:
  /// **'Reduz espaçamentos para telas menores e muitos produtos'**
  String get compactModeDescription;

  /// Compact mode enabled message
  ///
  /// In pt, this message translates to:
  /// **'Modo compacto ativado'**
  String get compactModeEnabled;

  /// Compact mode disabled message
  ///
  /// In pt, this message translates to:
  /// **'Modo compacto desativado'**
  String get compactModeDisabled;

  /// Language section header
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// App language option
  ///
  /// In pt, this message translates to:
  /// **'Idioma do Aplicativo'**
  String get appLanguage;

  /// App language description
  ///
  /// In pt, this message translates to:
  /// **'Selecione o idioma da interface'**
  String get appLanguageDescription;

  /// Language changed message
  ///
  /// In pt, this message translates to:
  /// **'Idioma alterado para {language}'**
  String languageChanged(String language);

  /// Reset app button
  ///
  /// In pt, this message translates to:
  /// **'Resetar Aplicativo'**
  String get resetApp;

  /// Reset app dialog title
  ///
  /// In pt, this message translates to:
  /// **'Reset do Aplicativo'**
  String get resetAppTitle;

  /// Reset app confirmation message
  ///
  /// In pt, this message translates to:
  /// **'Todos os dados, perfis salvos e preferências serão removidos. O aplicativo ficará como se estivesse sendo aberto pela primeira vez.\n\nEsta ação não pode ser desfeita. Deseja continuar?'**
  String get resetAppMessage;

  /// Cancel button
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// Reset button
  ///
  /// In pt, this message translates to:
  /// **'Resetar'**
  String get reset;

  /// Reset error message
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível resetar o aplicativo.'**
  String get resetError;

  /// Products label
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get products;

  /// Categories label
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get categories;

  /// Add button
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get add;

  /// Edit button
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get edit;

  /// Delete button
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// Save button
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// Name label
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get name;

  /// Price label
  ///
  /// In pt, this message translates to:
  /// **'Preço'**
  String get price;

  /// Cost label
  ///
  /// In pt, this message translates to:
  /// **'Custo'**
  String get cost;

  /// Margin label
  ///
  /// In pt, this message translates to:
  /// **'Margem'**
  String get margin;

  /// Search label
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No results message
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado encontrado'**
  String get noResults;

  /// Loading message
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get loading;

  /// Error label
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get error;

  /// Success label
  ///
  /// In pt, this message translates to:
  /// **'Sucesso'**
  String get success;

  /// Confirm button
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// Close button
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;

  /// Banner message when always using default template
  ///
  /// In pt, this message translates to:
  /// **'Usando sempre o Modelo Padrão ao compartilhar'**
  String get alwaysUseDefaultTemplateBanner;

  /// Change button
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get change;

  /// New template button label
  ///
  /// In pt, this message translates to:
  /// **'Novo Modelo'**
  String get newTemplate;

  /// Not editable tooltip
  ///
  /// In pt, this message translates to:
  /// **'Não editável'**
  String get notEditable;

  /// Template selected message
  ///
  /// In pt, this message translates to:
  /// **'Modelo \"{name}\" selecionado'**
  String templateSelected(String name);

  /// Empty state message for templates
  ///
  /// In pt, this message translates to:
  /// **'Nenhum modelo encontrado'**
  String get noTemplatesFound;

  /// Empty state description for templates
  ///
  /// In pt, this message translates to:
  /// **'Crie seu primeiro modelo para personalizar relatórios.'**
  String get createFirstTemplateDescription;

  /// Category emoji label
  ///
  /// In pt, this message translates to:
  /// **'Emoji da Categoria'**
  String get categoryEmoji;

  /// Category emoji hint
  ///
  /// In pt, this message translates to:
  /// **'Ex: ⬇️, 🔽, ou deixe vazio'**
  String get categoryEmojiHint;

  /// Products filter dropdown label
  ///
  /// In pt, this message translates to:
  /// **'Produtos a Incluir'**
  String get productsToInclude;

  /// Product name format dropdown label
  ///
  /// In pt, this message translates to:
  /// **'Formato do Nome do Produto'**
  String get productNameFormat;

  /// First word bold format option
  ///
  /// In pt, this message translates to:
  /// **'Primeira palavra em negrito'**
  String get firstWordBold;

  /// Full name bold format option
  ///
  /// In pt, this message translates to:
  /// **'Nome completo em negrito'**
  String get fullNameBold;

  /// Hide prices toggle label
  ///
  /// In pt, this message translates to:
  /// **'Ocultar Preços'**
  String get hidePrices;

  /// Hide prices toggle subtitle
  ///
  /// In pt, this message translates to:
  /// **'Útil para listas de conferência'**
  String get hidePricesSubtitle;

  /// Show currency symbol toggle label
  ///
  /// In pt, this message translates to:
  /// **'Mostrar \"R\$\" nos Preços'**
  String get showCurrencySymbol;

  /// Show currency symbol toggle subtitle
  ///
  /// In pt, this message translates to:
  /// **'Se desabilitado, mostra apenas os valores numéricos'**
  String get showCurrencySymbolSubtitle;

  /// Zero price text field label
  ///
  /// In pt, this message translates to:
  /// **'Texto para Preço Zerado'**
  String get zeroPriceText;

  /// Zero price text field hint
  ///
  /// In pt, this message translates to:
  /// **'Ex: Consulte, A combinar'**
  String get zeroPriceTextHint;

  /// Footer section header
  ///
  /// In pt, this message translates to:
  /// **'Rodapé'**
  String get footer;

  /// Footer message field label
  ///
  /// In pt, this message translates to:
  /// **'Mensagem de Rodapé'**
  String get footerMessage;

  /// Footer message field hint
  ///
  /// In pt, this message translates to:
  /// **'Ex: Peça já! (47) 99999-9999'**
  String get footerMessageHint;

  /// Loading sample data message
  ///
  /// In pt, this message translates to:
  /// **'Carregando dados de exemplo...'**
  String get loadingSampleData;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
