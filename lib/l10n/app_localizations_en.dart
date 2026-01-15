// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Precifica';

  @override
  String get settings => 'Settings';

  @override
  String get report => 'Report';

  @override
  String get reportTemplates => 'Report Templates';

  @override
  String get defaultTemplate => 'Default Template';

  @override
  String get visualization => 'Visualization';

  @override
  String get compactMode => 'Compact Mode';

  @override
  String get compactModeDescription =>
      'Reduces spacing for smaller screens and many products';

  @override
  String get compactModeEnabled => 'Compact mode enabled';

  @override
  String get compactModeDisabled => 'Compact mode disabled';

  @override
  String get language => 'Language';

  @override
  String get appLanguage => 'App Language';

  @override
  String get appLanguageDescription => 'Select the interface language';

  @override
  String languageChanged(String language) {
    return 'Language changed to $language';
  }

  @override
  String get resetApp => 'Reset App';

  @override
  String get resetAppTitle => 'App Reset';

  @override
  String get resetAppMessage =>
      'All data, saved profiles and preferences will be removed. The app will be as if it were being opened for the first time.\n\nThis action cannot be undone. Do you want to continue?';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get resetError => 'Could not reset the app.';

  @override
  String get products => 'Products';

  @override
  String get categories => 'Categories';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get name => 'Name';

  @override
  String get price => 'Price';

  @override
  String get cost => 'Cost';

  @override
  String get margin => 'Margin';

  @override
  String get search => 'Search';

  @override
  String get noResults => 'No results found';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get alwaysUseDefaultTemplateBanner =>
      'Always use Default Template when sharing';

  @override
  String get change => 'Change';

  @override
  String get newTemplate => 'New Template';

  @override
  String get notEditable => 'Not editable';

  @override
  String templateSelected(String name) {
    return 'Template \"$name\" selected';
  }

  @override
  String get noTemplatesFound => 'No templates found';

  @override
  String get createFirstTemplateDescription =>
      'Create your first template to customize reports.';

  @override
  String get categoryEmoji => 'Category Emoji';

  @override
  String get categoryEmojiHint => 'Ex: ⬇️, 🔽, or leave empty';

  @override
  String get productsToInclude => 'Products to Include';

  @override
  String get productNameFormat => 'Product Name Format';

  @override
  String get firstWordBold => 'First word bold';

  @override
  String get fullNameBold => 'Full name bold';

  @override
  String get hidePrices => 'Hide Prices';

  @override
  String get hidePricesSubtitle => 'Useful for conference lists';

  @override
  String get showCurrencySymbol => 'Show currency symbol';

  @override
  String get showCurrencySymbolSubtitle =>
      'If disabled, only numeric values are shown';

  @override
  String get zeroPriceText => 'Text for Zero Price';

  @override
  String get zeroPriceTextHint => 'Ex: Consult, To be agreed';

  @override
  String get footer => 'Footer';

  @override
  String get footerMessage => 'Footer Message';

  @override
  String get footerMessageHint => 'Ex: Order now! (47) 99999-9999';

  @override
  String get loadingSampleData => 'Loading sample data...';

  @override
  String get menuButtonLabel => 'Open menu';

  @override
  String get shareButtonLabel => 'Share report';

  @override
  String get addCategoryButtonLabel => 'Add new category';

  @override
  String get addProductButtonLabel => 'Add new product';

  @override
  String get editCategoryButtonLabel => 'Edit category';

  @override
  String get deleteCategoryButtonLabel => 'Delete category';

  @override
  String categorySelectedAnnouncement(String name) {
    return 'Category $name selected';
  }

  @override
  String productPriceLabel(String productName, String price) {
    return 'Price of $productName: $price';
  }

  @override
  String productActiveLabel(String productName) {
    return '$productName, active';
  }

  @override
  String productInactiveLabel(String productName) {
    return '$productName, inactive';
  }

  @override
  String get dragToReorderHint => 'Long press and drag to reorder';

  @override
  String get doubleTapToEditHint => 'Double tap to edit';

  @override
  String get tapToEditPriceHint => 'Tap to edit price';

  @override
  String get settingsButtonLabel => 'Open settings';

  @override
  String get aiOrganizeButtonLabel =>
      'Organize products with artificial intelligence';

  @override
  String get profilesButtonLabel => 'Manage saved profiles';

  @override
  String get closeMenuButtonLabel => 'Close menu';

  @override
  String introductionImageLabel(String description) {
    return 'Introduction image: $description';
  }

  @override
  String templateCardLabel(String name) {
    return 'Report template: $name';
  }

  @override
  String categoryTabLabel(String name, int position, int total) {
    return 'Category tab $name, $position of $total';
  }

  @override
  String productItemLabel(String name, String price, String status) {
    return '$name, price $price, $status';
  }

  @override
  String get activeStatus => 'active';

  @override
  String get inactiveStatus => 'inactive';

  @override
  String get toggleProductStatusHint =>
      'Tap to toggle between active and inactive';

  @override
  String get swipeToDeleteHint => 'Swipe left to delete';
}
