import 'package:hive_flutter/hive_flutter.dart';
import 'package:organiza_ae/data/models/categoria.dart';
import 'package:organiza_ae/data/models/produto.dart';
import 'package:uuid/uuid.dart';

class LocalStorageService {
  // Nomes das "caixas" (tabelas) do nosso banco de dados.
  static const _categoriasBox = 'categorias_box';
  static const _produtosBox = 'produtos_box';

  // Instância do gerador de IDs
  final _uuid = Uuid();

  // Métod para inicializar o Hive e registrar os adaptadores
  Future<void> init() async {
    Hive.registerAdapter(CategoriaAdapter());
    Hive.registerAdapter(ProdutoAdapter());

    await Hive.openBox<Categoria>(_categoriasBox);
    await Hive.openBox<Produto>(_produtosBox);
  }

  // Criar categoria
  Future<void> criarCategoria(String nome) async {
    final box = Hive.box<Categoria>(_categoriasBox);
    final novoId = _uuid.v4();
    final novaCategoria = Categoria(id: novoId, nome: nome);
    await box.put(novoId, novaCategoria);
  }

  // Listar categorias
  List<Categoria> getCategorias() {
    final box = Hive.box<Categoria>(_categoriasBox);
    return box.values.toList();
  }

  // Criar produto
  Future<void> criarProduto(String nome, String categoriaId) async {
    final box = Hive.box<Produto>(_produtosBox);
    final novoId = _uuid.v4();

    // Cria um novo produto, associando-o à categoria pelo ID.
    final novoProduto = Produto(
      id: novoId,
      nome: nome,
      categoriaId: categoriaId,
      // O preço inicial será 0.0, conforme definido no nosso modelo.
    );

    await box.put(novoId, novoProduto);
  }

  // Listar produto
  List<Produto> getProdutosPorCategoria(String categoriaId) {
    final box = Hive.box<Produto>(_produtosBox);

    // Pega todos os produtos e usa o ".where" para filtrar
    // apenas aqueles cujo categoriaId seja igual ao que foi passado.
    return box.values.where((produto) => produto.categoriaId == categoriaId).toList();
  }

  // Listar todos os produtos
  List<Produto> getAllProdutos() {
    final box = Hive.box<Produto>(_produtosBox);
    return box.values.toList();
  }

  // Atualizar preco do produto
  Future<void> atualizarPrecoProduto(String produtoId, double novoPreco) async {
    final box = Hive.box<Produto>(_produtosBox);

    // Pega o produto existente na caixa usando seu ID (que é a chave).
    final produto = box.get(produtoId);

    if (produto != null) {
      // Atualiza o preço do objeto.
      produto.preco = novoPreco;

      // Salva o objeto de volta na caixa com a mesma chave para persistir a alteração.
      await box.put(produtoId, produto);
    }
  }

  // Adicione esta função na seção de "FUNÇÕES PARA CATEGORIAS"
  Future<void> deletarCategoria(String categoriaId) async {
    final boxCategorias = Hive.box<Categoria>(_categoriasBox);
    final boxProdutos = Hive.box<Produto>(_produtosBox);

    // 1. Encontra todos os produtos que pertencem a esta categoria.
    final produtosParaDeletar = boxProdutos.values.where((p) => p.categoriaId == categoriaId).toList();

    // 2. Pega as chaves (IDs) desses produtos.
    final chavesDosProdutos = produtosParaDeletar.map((p) => p.id).toList();

    // 3. Deleta todos os produtos associados de uma só vez.
    await boxProdutos.deleteAll(chavesDosProdutos);

    // 4. Finalmente, deleta a própria categoria.
    await boxCategorias.delete(categoriaId);
  }
}
