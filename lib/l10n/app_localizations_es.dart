// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Precifica';

  @override
  String get settings => 'Configuración';

  @override
  String get report => 'Informe';

  @override
  String get reportTemplates => 'Plantillas de Informe';

  @override
  String get defaultTemplate => 'Plantilla Predeterminada';

  @override
  String get visualization => 'Visualización';

  @override
  String get compactMode => 'Modo Compacto';

  @override
  String get compactModeDescription =>
      'Reduce el espaciado para pantallas más pequeñas y muchos productos';

  @override
  String get compactModeEnabled => 'Modo compacto activado';

  @override
  String get compactModeDisabled => 'Modo compacto desactivado';

  @override
  String get language => 'Idioma';

  @override
  String get appLanguage => 'Idioma de la Aplicación';

  @override
  String get appLanguageDescription => 'Seleccione el idioma de la interfaz';

  @override
  String languageChanged(String language) {
    return 'Idioma cambiado a $language';
  }

  @override
  String get resetApp => 'Restablecer Aplicación';

  @override
  String get resetAppTitle => 'Restablecer Aplicación';

  @override
  String get resetAppMessage =>
      'Todos los datos, perfiles guardados y preferencias se eliminarán. La aplicación estará como si se abriera por primera vez.\n\nEsta acción no se puede deshacer. ¿Desea continuar?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get reset => 'Restablecer';

  @override
  String get resetError => 'No se pudo restablecer la aplicación.';

  @override
  String get products => 'Productos';

  @override
  String get categories => 'Categorías';

  @override
  String get add => 'Agregar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get name => 'Nombre';

  @override
  String get price => 'Precio';

  @override
  String get cost => 'Costo';

  @override
  String get margin => 'Margen';

  @override
  String get search => 'Buscar';

  @override
  String get noResults => 'No se encontraron resultados';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get confirm => 'Confirmar';

  @override
  String get close => 'Cerrar';

  @override
  String get alwaysUseDefaultTemplateBanner =>
      'Usando siempre la Plantilla Predeterminada al compartir';

  @override
  String get change => 'Cambiar';

  @override
  String get newTemplate => 'Nueva Plantilla';

  @override
  String get notEditable => 'No editable';

  @override
  String templateSelected(String name) {
    return 'Plantilla \"$name\" seleccionada';
  }

  @override
  String get noTemplatesFound => 'No se encontraron plantillas';

  @override
  String get createFirstTemplateDescription =>
      'Cree su primera plantilla para personalizar informes.';

  @override
  String get categoryEmoji => 'Emoji de Categoría';

  @override
  String get categoryEmojiHint => 'Ej: ⬇️, 🔽, o dejar vacío';

  @override
  String get productsToInclude => 'Productos a Incluir';

  @override
  String get productNameFormat => 'Formato del Nombre del Producto';

  @override
  String get firstWordBold => 'Primera palabra en negrita';

  @override
  String get fullNameBold => 'Nombre completo en negrita';

  @override
  String get hidePrices => 'Ocultar Precios';

  @override
  String get hidePricesSubtitle => 'Útil para listas de verificación';

  @override
  String get showCurrencySymbol => 'Mostrar símbolo de moneda';

  @override
  String get showCurrencySymbolSubtitle =>
      'Si está deshabilitado, solo se muestran valores numéricos';

  @override
  String get zeroPriceText => 'Texto para Precio Cero';

  @override
  String get zeroPriceTextHint => 'Ej: Consulte, A convenir';

  @override
  String get footer => 'Pie de página';

  @override
  String get footerMessage => 'Mensaje de Pie de página';

  @override
  String get footerMessageHint => 'Ej: ¡Ordene ahora! (47) 99999-9999';

  @override
  String get loadingSampleData => 'Cargando datos de ejemplo...';

  @override
  String get menuButtonLabel => 'Abrir menú';

  @override
  String get shareButtonLabel => 'Compartir informe';

  @override
  String get addCategoryButtonLabel => 'Agregar nueva categoría';

  @override
  String get addProductButtonLabel => 'Agregar nuevo producto';

  @override
  String get editCategoryButtonLabel => 'Editar categoría';

  @override
  String get deleteCategoryButtonLabel => 'Eliminar categoría';

  @override
  String categorySelectedAnnouncement(String name) {
    return 'Categoría $name seleccionada';
  }

  @override
  String productPriceLabel(String productName, String price) {
    return 'Precio de $productName: $price';
  }

  @override
  String productActiveLabel(String productName) {
    return '$productName, activo';
  }

  @override
  String productInactiveLabel(String productName) {
    return '$productName, inactivo';
  }

  @override
  String get dragToReorderHint =>
      'Mantenga presionado y arrastre para reordenar';

  @override
  String get doubleTapToEditHint => 'Toque dos veces para editar';

  @override
  String get tapToEditPriceHint => 'Toque para editar el precio';

  @override
  String get settingsButtonLabel => 'Abrir configuración';

  @override
  String get aiOrganizeButtonLabel =>
      'Organizar productos con inteligencia artificial';

  @override
  String get profilesButtonLabel => 'Gestionar perfiles guardados';

  @override
  String get closeMenuButtonLabel => 'Cerrar menú';

  @override
  String introductionImageLabel(String description) {
    return 'Imagen de introducción: $description';
  }

  @override
  String templateCardLabel(String name) {
    return 'Plantilla de informe: $name';
  }

  @override
  String categoryTabLabel(String name, int position, int total) {
    return 'Pestaña de categoría $name, $position de $total';
  }

  @override
  String productItemLabel(String name, String price, String status) {
    return '$name, precio $price, $status';
  }

  @override
  String get activeStatus => 'activo';

  @override
  String get inactiveStatus => 'inactivo';

  @override
  String get toggleProductStatusHint =>
      'Toque para alternar entre activo e inactivo';

  @override
  String get swipeToDeleteHint => 'Deslice a la izquierda para eliminar';
}
