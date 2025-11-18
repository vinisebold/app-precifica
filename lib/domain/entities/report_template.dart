enum CategoryFormatting {
  normal, // Texto simples
  uppercase, // MAIÚSCULAS
  bold, // *Negrito*
}

enum ProductNameFormatting {
  firstWordBold, // Primeira palavra em negrito (padrão)
  fullBold, // Nome completo em negrito
  normal, // Sem formatação especial
}

enum ProductFilter {
  activeWithPrice, // Apenas produtos ativos com preço (comportamento atual)
  allActive, // Todos os produtos ativos (incluindo preço zero)
  all, // Todos os produtos (incluindo inativos)
}

class ReportTemplate {
  final String id;
  String nome;

  // Cabeçalho
  String titulo; // Título personalizado
  bool mostrarData;
  bool mostrarDiaSemana;

  // Rodapé
  String mensagemRodape;

  // Estrutura das Categorias
  bool agruparPorCategoria;
  CategoryFormatting formatoCategoria;
  String emojiCategoria; // Emoji que acompanha a categoria (ex: "⬇️")

  // Estrutura dos Produtos
  ProductFilter filtroProdutos;
  ProductNameFormatting formatoNomeProduto;
  bool ocultarPrecos;
  String textoPrecoZero; // Texto para produtos com preço zerado (ex: "Consulte")
  bool mostrarCifraoPreco; // Se true, mostra "R$ 10,00"; se false, mostra "10,00"

  // Controle
  bool isPadrao; // Indica se é o modelo padrão (não pode ser excluído)

  ReportTemplate({
    required this.id,
    required this.nome,
    this.titulo = '',
    this.mostrarData = true,
    this.mostrarDiaSemana = true,
    this.mensagemRodape = '',
    this.agruparPorCategoria = true,
    this.formatoCategoria = CategoryFormatting.uppercase,
    this.emojiCategoria = '⬇️',
    this.filtroProdutos = ProductFilter.activeWithPrice,
    this.formatoNomeProduto = ProductNameFormatting.firstWordBold,
    this.ocultarPrecos = false,
    this.textoPrecoZero = 'Consulte',
  this.mostrarCifraoPreco = true,
    this.isPadrao = false,
  });

  ReportTemplate copyWith({
    String? id,
    String? nome,
    String? titulo,
    bool? mostrarData,
    bool? mostrarDiaSemana,
    String? mensagemRodape,
    bool? agruparPorCategoria,
    CategoryFormatting? formatoCategoria,
    String? emojiCategoria,
    ProductFilter? filtroProdutos,
    ProductNameFormatting? formatoNomeProduto,
    bool? ocultarPrecos,
    String? textoPrecoZero,
    bool? mostrarCifraoPreco,
    bool? isPadrao,
  }) {
    return ReportTemplate(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      titulo: titulo ?? this.titulo,
      mostrarData: mostrarData ?? this.mostrarData,
      mostrarDiaSemana: mostrarDiaSemana ?? this.mostrarDiaSemana,
      mensagemRodape: mensagemRodape ?? this.mensagemRodape,
      agruparPorCategoria: agruparPorCategoria ?? this.agruparPorCategoria,
      formatoCategoria: formatoCategoria ?? this.formatoCategoria,
      emojiCategoria: emojiCategoria ?? this.emojiCategoria,
      filtroProdutos: filtroProdutos ?? this.filtroProdutos,
      formatoNomeProduto: formatoNomeProduto ?? this.formatoNomeProduto,
      ocultarPrecos: ocultarPrecos ?? this.ocultarPrecos,
      textoPrecoZero: textoPrecoZero ?? this.textoPrecoZero,
      mostrarCifraoPreco: mostrarCifraoPreco ?? this.mostrarCifraoPreco,
      isPadrao: isPadrao ?? this.isPadrao,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'titulo': titulo,
      'mostrarData': mostrarData,
      'mostrarDiaSemana': mostrarDiaSemana,
      'mensagemRodape': mensagemRodape,
      'agruparPorCategoria': agruparPorCategoria,
      'formatoCategoria': formatoCategoria.index,
      'emojiCategoria': emojiCategoria,
      'filtroProdutos': filtroProdutos.index,
      'formatoNomeProduto': formatoNomeProduto.index,
      'ocultarPrecos': ocultarPrecos,
      'textoPrecoZero': textoPrecoZero,
      'mostrarCifraoPreco': mostrarCifraoPreco,
      'isPadrao': isPadrao,
    };
  }

  factory ReportTemplate.fromJson(Map<String, dynamic> json) {
    return ReportTemplate(
      id: json['id'] as String,
      nome: json['nome'] as String,
      titulo: json['titulo'] as String? ?? '',
      mostrarData: json['mostrarData'] as bool? ?? true,
      mostrarDiaSemana: json['mostrarDiaSemana'] as bool? ?? true,
      mensagemRodape: json['mensagemRodape'] as String? ?? '',
      agruparPorCategoria: json['agruparPorCategoria'] as bool? ?? true,
      formatoCategoria: CategoryFormatting.values[json['formatoCategoria'] as int? ?? 1],
      emojiCategoria: json['emojiCategoria'] as String? ?? '⬇️',
      filtroProdutos: ProductFilter.values[json['filtroProdutos'] as int? ?? 0],
      formatoNomeProduto: ProductNameFormatting.values[json['formatoNomeProduto'] as int? ?? 0],
      ocultarPrecos: json['ocultarPrecos'] as bool? ?? false,
      textoPrecoZero: json['textoPrecoZero'] as String? ?? 'Consulte',
  mostrarCifraoPreco: json['mostrarCifraoPreco'] as bool? ?? true,
      isPadrao: json['isPadrao'] as bool? ?? false,
    );
  }

  // Factory para criar o modelo padrão
  factory ReportTemplate.padrao() {
    return ReportTemplate(
      id: 'default',
      nome: 'Modelo Padrão',
      titulo: 'Preços',
      mostrarData: true,
      mostrarDiaSemana: true,
      mensagemRodape: '',
      agruparPorCategoria: true,
      formatoCategoria: CategoryFormatting.uppercase,
      emojiCategoria: '⬇️',
      filtroProdutos: ProductFilter.activeWithPrice,
      formatoNomeProduto: ProductNameFormatting.firstWordBold,
      ocultarPrecos: false,
      textoPrecoZero: 'Consulte',
  mostrarCifraoPreco: true,
      isPadrao: true,
    );
  }
}
