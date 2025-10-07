import 'package:hive/hive.dart';
import '../../domain/entities/report_template.dart';

part 'report_template_model.g.dart';

@HiveType(typeId: 3)
class ReportTemplateModel extends ReportTemplate {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  String nome;

  @HiveField(2)
  @override
  String titulo;

  @HiveField(3)
  @override
  bool mostrarData;

  @HiveField(4)
  @override
  bool mostrarDiaSemana;

  @HiveField(5)
  @override
  String mensagemRodape;

  @HiveField(6)
  @override
  bool agruparPorCategoria;

  @HiveField(7)
  @override
  CategoryFormatting formatoCategoria;

  @HiveField(8)
  @override
  String emojiCategoria;

  @HiveField(9)
  @override
  ProductFilter filtroProdutos;

  @HiveField(10)
  @override
  ProductNameFormatting formatoNomeProduto;

  @HiveField(11)
  @override
  bool ocultarPrecos;

  @HiveField(12)
  @override
  String textoPrecoZero;

  @HiveField(13)
  @override
  bool mostrarCifraoPreco;

  @HiveField(14)
  @override
  bool isPadrao;

  ReportTemplateModel({
    required this.id,
    required this.nome,
    required this.titulo,
    required this.mostrarData,
    required this.mostrarDiaSemana,
    required this.mensagemRodape,
    required this.agruparPorCategoria,
    required this.formatoCategoria,
    required this.emojiCategoria,
    required this.filtroProdutos,
    required this.formatoNomeProduto,
    required this.ocultarPrecos,
    required this.textoPrecoZero,
    required this.mostrarCifraoPreco,
    required this.isPadrao,
  }) : super(
          id: id,
          nome: nome,
          titulo: titulo,
          mostrarData: mostrarData,
          mostrarDiaSemana: mostrarDiaSemana,
          mensagemRodape: mensagemRodape,
          agruparPorCategoria: agruparPorCategoria,
          formatoCategoria: formatoCategoria,
          emojiCategoria: emojiCategoria,
          filtroProdutos: filtroProdutos,
          formatoNomeProduto: formatoNomeProduto,
          ocultarPrecos: ocultarPrecos,
          textoPrecoZero: textoPrecoZero,
          mostrarCifraoPreco: mostrarCifraoPreco,
          isPadrao: isPadrao,
        );

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
