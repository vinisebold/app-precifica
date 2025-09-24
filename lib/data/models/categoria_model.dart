import 'package:hive/hive.dart';
import 'package:precifica/domain/entities/categoria.dart';

part 'categoria_model.g.dart';

@HiveType(typeId: 0)
class CategoriaModel extends Categoria {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  int ordem;

  @HiveField(3, defaultValue: [])
  List<String> produtoIds;

  CategoriaModel({
    required this.id,
    required this.nome,
    required this.ordem,
    this.produtoIds = const [],
  }) : super(id: id, nome: nome, ordem: ordem);

  factory CategoriaModel.fromEntity(Categoria categoria) {
    return CategoriaModel(
      id: categoria.id,
      nome: categoria.nome,
      ordem: categoria.ordem,

      // Se a entidade tiver a lista, passe-a. Caso contrário, use uma lista vazia.
      produtoIds: (categoria is CategoriaModel) ? categoria.produtoIds : [],
    );
  }
}
