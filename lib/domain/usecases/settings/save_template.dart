import '../../entities/report_template.dart';
import '../../repositories/i_settings_repository.dart';

class SaveTemplate {
  final ISettingsRepository repository;

  SaveTemplate(this.repository);

  Future<void> call(ReportTemplate template) async {
    await repository.saveTemplate(template);
  }
}
