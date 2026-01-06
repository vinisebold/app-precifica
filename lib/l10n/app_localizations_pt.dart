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
}
