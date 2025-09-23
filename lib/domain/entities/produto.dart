class Produto {
  final String id;
  String nome;
  double preco;
  String categoriaId;
  bool isAtivo;

  Produto({
    required this.id,
    required this.nome,
    this.preco = 0.0,
    required this.categoriaId,
    this.isAtivo = true,
  });
}
