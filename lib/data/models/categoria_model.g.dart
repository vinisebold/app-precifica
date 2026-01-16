// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categoria_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoriaModelAdapter extends TypeAdapter<CategoriaModel> {
  @override
  final int typeId = 0;

  @override
  CategoriaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoriaModel(
      id: fields[0] as String,
      nome: fields[1] as String,
      ordem: fields[2] as int,
      produtoIds: fields[3] == null ? [] : (fields[3] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CategoriaModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(3)
      ..write(obj.produtoIds)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.ordem);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoriaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
