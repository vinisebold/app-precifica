import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/report_template_model.dart';
import '../../domain/entities/report_template.dart';
import '../../domain/repositories/i_settings_repository.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  static const _templatesBox = 'report_templates_box';
  static const _preferencesBox = 'preferences_box';
  static const _keyNaoPerguntarTemplate = 'nao_perguntar_template';

  @override
  Future<void> init() async {
    Hive.registerAdapter(ReportTemplateModelAdapter());
    Hive.registerAdapter(CategoryFormattingAdapter());
    Hive.registerAdapter(ProductFilterAdapter());
    Hive.registerAdapter(ProductNameFormattingAdapter());
    
    await Hive.openBox<ReportTemplateModel>(_templatesBox);
    await Hive.openBox(_preferencesBox);
    await ensureDefaultTemplate();
  }

  @override
  Future<void> ensureDefaultTemplate() async {
    final box = Hive.box<ReportTemplateModel>(_templatesBox);
    
    // Verifica se já existe o template padrão
    if (box.get('default') == null) {
      final defaultTemplate = ReportTemplate.padrao();
      final model = ReportTemplateModel.fromEntity(defaultTemplate);
      await box.put('default', model);
    }
  }

  @override
  Future<void> saveTemplate(ReportTemplate template) async {
    final box = Hive.box<ReportTemplateModel>(_templatesBox);
    final model = ReportTemplateModel.fromEntity(template);
    await box.put(template.id, model);
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    final box = Hive.box<ReportTemplateModel>(_templatesBox);
    final template = box.get(templateId);
    
    // Não permite deletar o template padrão
    if (template?.isPadrao ?? false) {
      throw Exception('Não é possível deletar o modelo padrão');
    }
    
    await box.delete(templateId);
  }

  @override
  Future<ReportTemplate?> getTemplate(String templateId) async {
    final box = Hive.box<ReportTemplateModel>(_templatesBox);
    return box.get(templateId);
  }

  @override
  List<ReportTemplate> getTemplates() {
    final box = Hive.box<ReportTemplateModel>(_templatesBox);
    final templates = box.values.toList();
    
    // Ordena: padrão primeiro, depois alfabeticamente
    templates.sort((a, b) {
      if (a.isPadrao) return -1;
      if (b.isPadrao) return 1;
      return a.nome.compareTo(b.nome);
    });
    
    return templates;
  }

  @override
  Future<void> setNaoPerguntarTemplate(bool valor) async {
    final box = Hive.box(_preferencesBox);
    await box.put(_keyNaoPerguntarTemplate, valor);
  }

  @override
  bool getNaoPerguntarTemplate() {
    final box = Hive.box(_preferencesBox);
    return box.get(_keyNaoPerguntarTemplate, defaultValue: false) as bool;
  }
}

// Adapters para os enums
class CategoryFormattingAdapter extends TypeAdapter<CategoryFormatting> {
  @override
  final int typeId = 4;

  @override
  CategoryFormatting read(BinaryReader reader) {
    return CategoryFormatting.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, CategoryFormatting obj) {
    writer.writeByte(obj.index);
  }
}

class ProductFilterAdapter extends TypeAdapter<ProductFilter> {
  @override
  final int typeId = 5;

  @override
  ProductFilter read(BinaryReader reader) {
    return ProductFilter.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ProductFilter obj) {
    writer.writeByte(obj.index);
  }
}

class ProductNameFormattingAdapter extends TypeAdapter<ProductNameFormatting> {
  @override
  final int typeId = 6;

  @override
  ProductNameFormatting read(BinaryReader reader) {
    return ProductNameFormatting.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ProductNameFormatting obj) {
    writer.writeByte(obj.index);
  }
}
