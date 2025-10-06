import '../../entities/report_template.dart';
import '../../repositories/i_settings_repository.dart';

class GetTemplates {
  final ISettingsRepository repository;

  GetTemplates(this.repository);

  List<ReportTemplate> call() {
    return repository.getTemplates();
  }
}
