import '../../entities/report_template.dart';
import '../../repositories/i_settings_repository.dart';

class GetTemplate {
  final ISettingsRepository repository;

  GetTemplate(this.repository);

  Future<ReportTemplate?> call(String templateId) async {
    return await repository.getTemplate(templateId);
  }
}
