import 'package:hive/hive.dart';
import 'package:precifica/domain/entities/produto.dart';

part 'produto_model.g.dart';

@HiveType(typeId: 1)
class ProdutoModel extends Produto {
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
  double get preco => super.preco;

  @HiveField(2)
  @override
  set preco(double value) => super.preco = value;

  @HiveField(3)
  @override
  String get categoriaId => super.categoriaId;

  @HiveField(3)
  @override
  set categoriaId(String value) => super.categoriaId = value;

  @HiveField(4, defaultValue: true)
  @override
  bool get isAtivo => super.isAtivo;

  @HiveField(4)
  @override
  set isAtivo(bool value) => super.isAtivo = value;

  ProdutoModel({
    required super.id,
    required super.nome,
    super.preco,
    required super.categoriaId,
    super.isAtivo,
  });

  factory ProdutoModel.fromEntity(Produto produto) {
    return ProdutoModel(
      id: produto.id,
      nome: produto.nome,
      preco: produto.preco,
      categoriaId: produto.categoriaId,
      isAtivo: produto.isAtivo,
    );
  }
}
