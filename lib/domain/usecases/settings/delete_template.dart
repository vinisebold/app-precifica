import '../../repositories/i_settings_repository.dart';

class DeleteTemplate {
  final ISettingsRepository repository;

  DeleteTemplate(this.repository);

  Future<void> call(String templateId) async {
    await repository.deleteTemplate(templateId);
  }
}
