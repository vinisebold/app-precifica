import '../../domain/entities/report_template.dart';

abstract class ISettingsRepository {
  Future<void> init();
  
  // Gerenciamento de templates
  Future<void> saveTemplate(ReportTemplate template);
  Future<void> deleteTemplate(String templateId);
  Future<ReportTemplate?> getTemplate(String templateId);
  List<ReportTemplate> getTemplates();
  
  // Template padrão para novos usuários
  Future<void> ensureDefaultTemplate();
  
  // Template selecionado (modelo ativo)
  Future<void> setTemplateSelecionado(String? templateId);
  String? getTemplateSelecionado();
  ReportTemplate? getTemplateSelecionadoObjeto();
  
  // Preferências
  Future<void> setNaoPerguntarTemplate(bool valor);
  bool getNaoPerguntarTemplate();
  
  // Modo compacto/densidade
  Future<void> setModoCompacto(bool valor);
  bool getModoCompacto();
}
