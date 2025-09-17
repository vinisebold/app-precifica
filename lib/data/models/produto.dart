import 'package:hive/hive.dart';

part 'produto.g.dart';

@HiveType(typeId: 1) // Usamos o próximo typeId disponível, que é 1
class Produto {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  double preco;

  @HiveField(3) // Este campo faz a ligação com a Categoria
  String categoriaId;

  Produto({
    required this.id,
    required this.nome,
    this.preco = 0.0,
    required this.categoriaId,
  });
}
