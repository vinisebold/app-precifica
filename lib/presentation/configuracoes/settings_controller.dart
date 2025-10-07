import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/report_template.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../../domain/usecases/settings/delete_template.dart';
import '../../domain/usecases/settings/get_template.dart';
import '../../domain/usecases/settings/get_templates.dart';
import '../../domain/usecases/settings/save_template.dart';
import 'settings_state.dart';

final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
  () => SettingsController(),
);

class SettingsController extends Notifier<SettingsState> {
  late final GetTemplates _getTemplates;
  late final GetTemplate _getTemplate;
  late final SaveTemplate _saveTemplate;
  late final DeleteTemplate _deleteTemplate;
  static const _uuid = Uuid();

  @override
  SettingsState build() {
    final repository = ref.watch(settingsRepositoryProvider);
    _getTemplates = GetTemplates(repository);
    _getTemplate = GetTemplate(repository);
    _saveTemplate = SaveTemplate(repository);
    _deleteTemplate = DeleteTemplate(repository);

    state = SettingsState(isLoading: true);
    _carregarTemplates();
    return state;
  }

  Future<void> _carregarTemplates() async {
    state = state.copyWith(isLoading: true);
    try {
      final templates = _getTemplates();
      state = state.copyWith(templates: templates, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Falha ao carregar modelos: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  void iniciarEdicao(ReportTemplate? template) {
    if (template != null) {
      state = state.copyWith(templateEmEdicao: template);
    } else {
      // Criar novo template
      final novoTemplate = ReportTemplate(
        id: _uuid.v4(),
        nome: 'Novo Modelo',
      );
      state = state.copyWith(templateEmEdicao: novoTemplate);
    }
  }

  void cancelarEdicao() {
    state = state.copyWith(clearTemplateEmEdicao: true);
  }

  void atualizarTemplateEmEdicao(ReportTemplate template) {
    state = state.copyWith(templateEmEdicao: template);
  }

  Future<void> salvarTemplate() async {
    if (state.templateEmEdicao == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await _saveTemplate(state.templateEmEdicao!);
      await _carregarTemplates();
      state = state.copyWith(clearTemplateEmEdicao: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Falha ao salvar modelo: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> deletarTemplate(String templateId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _deleteTemplate(templateId);
      await _carregarTemplates();
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<ReportTemplate?> obterTemplate(String templateId) async {
    return await _getTemplate(templateId);
  }

  Future<void> setNaoPerguntarTemplate(bool valor) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.setNaoPerguntarTemplate(valor);
  }

  bool getNaoPerguntarTemplate() {
    final repository = ref.read(settingsRepositoryProvider);
    return repository.getNaoPerguntarTemplate();
  }

  Future<void> setModoCompacto(bool valor) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.setModoCompacto(valor);
  }

  bool getModoCompacto() {
    final repository = ref.read(settingsRepositoryProvider);
    return repository.getModoCompacto();
  }

  void clearError() => state = state.copyWith(clearErrorMessage: true);
}
