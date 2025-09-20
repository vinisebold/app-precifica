import 'package:hive/hive.dart';
import 'package:precifica/domain/entities/produto.dart';

part 'produto_model.g.dart';

@HiveType(typeId: 1)
class ProdutoModel extends Produto {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  double preco;

  @HiveField(3)
  String categoriaId;

  ProdutoModel({
    required this.id,
    required this.nome,
    this.preco = 0.0,
    required this.categoriaId,
  }) : super(id: id, nome: nome, preco: preco, categoriaId: categoriaId);

  factory ProdutoModel.fromEntity(Produto produto) {
    return ProdutoModel(
      id: produto.id,
      nome: produto.nome,
      preco: produto.preco,
      categoriaId: produto.categoriaId,
    );
  }
}