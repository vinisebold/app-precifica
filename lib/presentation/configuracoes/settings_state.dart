import '../../domain/entities/report_template.dart';

class SettingsState {
  final List<ReportTemplate> templates;
  final ReportTemplate? templateEmEdicao;
  final String? templateSelecionadoId;
  final bool isLoading;
  final String? errorMessage;

  SettingsState({
    this.templates = const [],
    this.templateEmEdicao,
    this.templateSelecionadoId,
    this.isLoading = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    List<ReportTemplate>? templates,
    ReportTemplate? templateEmEdicao,
    String? templateSelecionadoId,
    bool? isLoading,
    String? errorMessage,
    bool clearTemplateEmEdicao = false,
    bool clearErrorMessage = false,
  }) {
    return SettingsState(
      templates: templates ?? this.templates,
      templateEmEdicao: clearTemplateEmEdicao ? null : (templateEmEdicao ?? this.templateEmEdicao),
      templateSelecionadoId: templateSelecionadoId ?? this.templateSelecionadoId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
