import 'package:hive/hive.dart';

part 'categoria.g.dart';

@HiveType(typeId: 0) // typeId deve ser único para cada modelo
class Categoria {
  @HiveField(0) // Índice do campo
  final String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  int ordem;

  Categoria({
    required this.id,
    required this.nome,
    required this.ordem,
  });
}
