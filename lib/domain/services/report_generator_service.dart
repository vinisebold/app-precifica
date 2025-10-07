import 'package:intl/intl.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/produto.dart';
import '../../domain/entities/report_template.dart';

class ReportGeneratorService {
  String gerarRelatorio({
    required ReportTemplate template,
    required List<Categoria> categorias,
    required List<Produto> todosProdutos,
  }) {
    if (todosProdutos.isEmpty) {
      return 'Nenhum produto cadastrado para gerar relatório.';
    }

    final buffer = StringBuffer();

    // Cabeçalho
    _adicionarCabecalho(buffer, template);

    // Corpo do relatório
    if (template.agruparPorCategoria) {
      _adicionarProdutosPorCategoria(
        buffer,
        template,
        categorias,
        todosProdutos,
      );
    } else {
      _adicionarProdutosListaUnica(buffer, template, todosProdutos);
    }

    // Rodapé
    _adicionarRodape(buffer, template);

    final report = buffer.toString();
    
    // Verifica se o relatório está vazio (apenas cabeçalho/rodapé)
    final linhasComConteudo = report
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;
    
    if (linhasComConteudo <= 3) {
      return 'Nenhum produto encontrado com os critérios selecionados.';
    }

    return report;
  }

  void _adicionarCabecalho(StringBuffer buffer, ReportTemplate template) {
    final hoje = DateTime.now();
    
    // Título
    if (template.titulo.isNotEmpty) {
      if (template.mostrarDiaSemana) {
        final formatoDiaSemana = DateFormat('EEEE', 'pt_BR');
        final diaSemanaFormatado = formatoDiaSemana.format(hoje);
        buffer.writeln('*${template.titulo}: $diaSemanaFormatado*');
      } else {
        buffer.writeln('*${template.titulo}*');
      }
    }

    // Data
    if (template.mostrarData) {
      final formatoData = DateFormat('dd/MM/yy');
      buffer.writeln(formatoData.format(hoje));
    }

    if (template.titulo.isNotEmpty || template.mostrarData) {
      buffer.writeln();
    }
  }

  void _adicionarRodape(StringBuffer buffer, ReportTemplate template) {
    if (template.mensagemRodape.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(template.mensagemRodape);
    }
  }

  void _adicionarProdutosPorCategoria(
    StringBuffer buffer,
    ReportTemplate template,
    List<Categoria> categorias,
    List<Produto> todosProdutos,
  ) {
    for (var categoria in categorias) {
      final produtosDaCategoria = _filtrarProdutos(
        todosProdutos.where((p) => p.categoriaId == categoria.id).toList(),
        template,
      );

      if (produtosDaCategoria.isNotEmpty) {
        _adicionarNomeCategoria(buffer, categoria.nome, template);
        
        for (var produto in produtosDaCategoria) {
          _adicionarProduto(buffer, produto, template);
        }
        
        buffer.writeln();
      }
    }
  }

  void _adicionarProdutosListaUnica(
    StringBuffer buffer,
    ReportTemplate template,
    List<Produto> todosProdutos,
  ) {
    final produtosFiltrados = _filtrarProdutos(todosProdutos, template);
    
    // Ordena alfabeticamente
    produtosFiltrados.sort((a, b) => a.nome.compareTo(b.nome));

    for (var produto in produtosFiltrados) {
      _adicionarProduto(buffer, produto, template);
    }
  }

  List<Produto> _filtrarProdutos(
    List<Produto> produtos,
    ReportTemplate template,
  ) {
    switch (template.filtroProdutos) {
      case ProductFilter.activeWithPrice:
        return produtos.where((p) => p.isAtivo && p.preco > 0).toList();
      case ProductFilter.allActive:
        return produtos.where((p) => p.isAtivo).toList();
      case ProductFilter.all:
        return produtos;
    }
  }

  void _adicionarNomeCategoria(
    StringBuffer buffer,
    String nomeCategoria,
    ReportTemplate template,
  ) {
    String nome = nomeCategoria;

    switch (template.formatoCategoria) {
      case CategoryFormatting.uppercase:
        nome = nome.toUpperCase();
        break;
      case CategoryFormatting.bold:
        nome = '*$nome*';
        break;
      case CategoryFormatting.normal:
        // Mantém como está
        break;
    }

    final emoji = template.emojiCategoria.isNotEmpty 
        ? ' ${template.emojiCategoria}' 
        : '';
    
    buffer.writeln('$nome:$emoji');
  }

  void _adicionarProduto(
    StringBuffer buffer,
    Produto produto,
    ReportTemplate template,
  ) {
    final nomeFormatado = _formatarNomeProduto(produto.nome, template);
    final precoFormatado = _formatarPreco(produto.preco, template);
    
    final statusInativo = !produto.isAtivo ? ' (inativo)' : '';
    
    if (template.ocultarPrecos) {
      buffer.writeln(' $nomeFormatado$statusInativo');
    } else {
      buffer.writeln(' $nomeFormatado: $precoFormatado$statusInativo');
    }
  }

  String _formatarNomeProduto(String nome, ReportTemplate template) {
    switch (template.formatoNomeProduto) {
      case ProductNameFormatting.firstWordBold:
        final palavras = nome.split(' ');
        final primeiraPalavra = palavras.first;
        final restoDoNome = palavras.skip(1).join(' ');
        
        if (restoDoNome.isEmpty) {
          return '*$primeiraPalavra*';
        } else {
          return '*$primeiraPalavra* $restoDoNome';
        }
      
      case ProductNameFormatting.fullBold:
        return '*$nome*';
      
      case ProductNameFormatting.normal:
        return nome;
    }
  }

  String _formatarPreco(double preco, ReportTemplate template) {
    if (preco == 0) {
      return template.textoPrecoZero;
    }
    
    final valorFormatado = preco.toStringAsFixed(2).replaceAll('.', ',');
    
    if (template.mostrarCifraoPreco) {
      return 'R\$ $valorFormatado';
    } else {
      return valorFormatado;
    }
  }
}
