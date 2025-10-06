// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_template_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReportTemplateModelAdapter extends TypeAdapter<ReportTemplateModel> {
  @override
  final int typeId = 3;

  @override
  ReportTemplateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReportTemplateModel(
      id: fields[0] as String,
      nome: fields[1] as String,
      titulo: fields[2] as String,
      mostrarData: fields[3] as bool,
      mostrarDiaSemana: fields[4] as bool,
      mensagemRodape: fields[5] as String,
      agruparPorCategoria: fields[6] as bool,
      formatoCategoria: fields[7] as CategoryFormatting,
      emojiCategoria: fields[8] as String,
      filtroProdutos: fields[9] as ProductFilter,
      formatoNomeProduto: fields[10] as ProductNameFormatting,
      ocultarPrecos: fields[11] as bool,
      textoPrecoZero: fields[12] as String,
      isPadrao: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ReportTemplateModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.titulo)
      ..writeByte(3)
      ..write(obj.mostrarData)
      ..writeByte(4)
      ..write(obj.mostrarDiaSemana)
      ..writeByte(5)
      ..write(obj.mensagemRodape)
      ..writeByte(6)
      ..write(obj.agruparPorCategoria)
      ..writeByte(7)
      ..write(obj.formatoCategoria)
      ..writeByte(8)
      ..write(obj.emojiCategoria)
      ..writeByte(9)
      ..write(obj.filtroProdutos)
      ..writeByte(10)
      ..write(obj.formatoNomeProduto)
      ..writeByte(11)
      ..write(obj.ocultarPrecos)
      ..writeByte(12)
      ..write(obj.textoPrecoZero)
      ..writeByte(13)
      ..write(obj.isPadrao);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportTemplateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
