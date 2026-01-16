import 'package:hive/hive.dart';
import 'package:precifica/domain/entities/categoria.dart';

part 'categoria_model.g.dart';

@HiveType(typeId: 0)
class CategoriaModel extends Categoria {
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
  int get ordem => super.ordem;

  @HiveField(2)
  @override
  set ordem(int value) => super.ordem = value;

  @HiveField(3, defaultValue: [])
  List<String> produtoIds;

  CategoriaModel({
    required super.id,
    required super.nome,
    required super.ordem,
    List<String>? produtoIds,
  })  : produtoIds = List<String>.from(produtoIds ?? const []);

  factory CategoriaModel.fromEntity(Categoria categoria) {
    return CategoriaModel(
      id: categoria.id,
      nome: categoria.nome,
      ordem: categoria.ordem,

      // Se a entidade tiver a lista, passe-a. Caso contrário, use uma lista vazia.
      produtoIds: (categoria is CategoriaModel)
          ? categoria.produtoIds
          : List<String>.from(const []),
    );
  }
}
