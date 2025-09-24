// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'produto_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProdutoModelAdapter extends TypeAdapter<ProdutoModel> {
  @override
  final int typeId = 1;

  @override
  ProdutoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProdutoModel(
      id: fields[0] as String,
      nome: fields[1] as String,
      preco: fields[2] as double,
      categoriaId: fields[3] as String,
      isAtivo: fields[4] == null ? true : fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProdutoModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.preco)
      ..writeByte(3)
      ..write(obj.categoriaId)
      ..writeByte(4)
      ..write(obj.isAtivo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProdutoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
