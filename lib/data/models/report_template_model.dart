import 'package:hive/hive.dart';
import '../../domain/entities/report_template.dart';

part 'report_template_model.g.dart';

@HiveType(typeId: 3)
class ReportTemplateModel extends ReportTemplate {
  @HiveField(0)
  @override
  String get id => super.id;

  @HiveField(1)
  @override
  String get nome => super.nome;

  @HiveField(1)
  @override
  set nome(String value) => super.nome = value;

  @HiveField(2)
  @override
  String get titulo => super.titulo;

  @HiveField(2)
  @override
  set titulo(String value) => super.titulo = value;

  @HiveField(3)
  @override
  bool get mostrarData => super.mostrarData;

  @HiveField(3)
  @override
  set mostrarData(bool value) => super.mostrarData = value;

  @HiveField(4)
  @override
  bool get mostrarDiaSemana => super.mostrarDiaSemana;

  @HiveField(4)
  @override
  set mostrarDiaSemana(bool value) => super.mostrarDiaSemana = value;

  @HiveField(5)
  @override
  String get mensagemRodape => super.mensagemRodape;

  @HiveField(5)
  @override
  set mensagemRodape(String value) => super.mensagemRodape = value;

  @HiveField(6)
  @override
  bool get agruparPorCategoria => super.agruparPorCategoria;

  @HiveField(6)
  @override
  set agruparPorCategoria(bool value) => super.agruparPorCategoria = value;

  @HiveField(7)
  @override
  CategoryFormatting get formatoCategoria => super.formatoCategoria;

  @HiveField(7)
  @override
  set formatoCategoria(CategoryFormatting value) => super.formatoCategoria = value;

  @HiveField(8)
  @override
  String get emojiCategoria => super.emojiCategoria;

  @HiveField(8)
  @override
  set emojiCategoria(String value) => super.emojiCategoria = value;

  @HiveField(9)
  @override
  ProductFilter get filtroProdutos => super.filtroProdutos;

  @HiveField(9)
  @override
  set filtroProdutos(ProductFilter value) => super.filtroProdutos = value;

  @HiveField(10)
  @override
  ProductNameFormatting get formatoNomeProduto => super.formatoNomeProduto;

  @HiveField(10)
  @override
  set formatoNomeProduto(ProductNameFormatting value) => super.formatoNomeProduto = value;

  @HiveField(11)
  @override
  bool get ocultarPrecos => super.ocultarPrecos;

  @HiveField(11)
  @override
  set ocultarPrecos(bool value) => super.ocultarPrecos = value;

  @HiveField(12)
  @override
  String get textoPrecoZero => super.textoPrecoZero;

  @HiveField(12)
  @override
  set textoPrecoZero(String value) => super.textoPrecoZero = value;

  @HiveField(13)
  @override
  bool get mostrarCifraoPreco => super.mostrarCifraoPreco;

  @HiveField(13)
  @override
  set mostrarCifraoPreco(bool value) => super.mostrarCifraoPreco = value;

  @HiveField(14)
  @override
  bool get isPadrao => super.isPadrao;

  @HiveField(14)
  @override
  set isPadrao(bool value) => super.isPadrao = value;

  ReportTemplateModel({
    required super.id,
    required super.nome,
    required super.titulo,
    required super.mostrarData,
    required super.mostrarDiaSemana,
    required super.mensagemRodape,
    required super.agruparPorCategoria,
    required super.formatoCategoria,
    required super.emojiCategoria,
    required super.filtroProdutos,
    required super.formatoNomeProduto,
    required super.ocultarPrecos,
    required super.textoPrecoZero,
    required super.mostrarCifraoPreco,
    required super.isPadrao,
  });

  factory ReportTemplateModel.fromEntity(ReportTemplate template) {
    return ReportTemplateModel(
      id: template.id,
      nome: template.nome,
      titulo: template.titulo,
      mostrarData: template.mostrarData,
      mostrarDiaSemana: template.mostrarDiaSemana,
      mensagemRodape: template.mensagemRodape,
      agruparPorCategoria: template.agruparPorCategoria,
      formatoCategoria: template.formatoCategoria,
      emojiCategoria: template.emojiCategoria,
      filtroProdutos: template.filtroProdutos,
      formatoNomeProduto: template.formatoNomeProduto,
      ocultarPrecos: template.ocultarPrecos,
      textoPrecoZero: template.textoPrecoZero,
      mostrarCifraoPreco: template.mostrarCifraoPreco,
      isPadrao: template.isPadrao,
    );
  }
}
