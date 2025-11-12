import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/categoria.dart';
import '../../../domain/entities/produto.dart';
import '../../../domain/entities/report_template.dart';

/// Widget que renderiza o relatório em formato visual para captura como imagem
class ReportImageWidget extends StatelessWidget {
  final ReportTemplate template;
  final List<Categoria> categorias;
  final List<Produto> todosProdutos;

  const ReportImageWidget({
    super.key,
    required this.template,
    required this.categorias,
    required this.todosProdutos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          _buildCabecalho(),
          const SizedBox(height: 24),
          
          // Corpo do relatório
          if (template.agruparPorCategoria)
            _buildProdutosPorCategoria()
          else
            _buildProdutosListaUnica(),
          
          // Rodapé
          if (template.mensagemRodape.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildRodape(),
          ],
        ],
      ),
    );
  }

  Widget _buildCabecalho() {
    final hoje = DateTime.now();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        if (template.titulo.isNotEmpty) ...[
          Text(
            template.mostrarDiaSemana
                ? '${template.titulo}: ${DateFormat('EEEE', 'pt_BR').format(hoje)}'
                : template.titulo,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Data
        if (template.mostrarData)
          Text(
            DateFormat('dd/MM/yy').format(hoje),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
      ],
    );
  }

  Widget _buildRodape() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        template.mensagemRodape,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildProdutosPorCategoria() {
    final widgets = <Widget>[];
    
    for (var categoria in categorias) {
      final produtosDaCategoria = _filtrarProdutos(
        todosProdutos.where((p) => p.categoriaId == categoria.id).toList(),
      );

      if (produtosDaCategoria.isNotEmpty) {
        widgets.add(_buildCategoria(categoria.nome, produtosDaCategoria));
        widgets.add(const SizedBox(height: 20));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildCategoria(String nomeCategoria, List<Produto> produtos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome da categoria (sem emoji na versão imagem)
        Text(
          _formatarNomeCategoria(nomeCategoria),
          style: TextStyle(
            fontSize: 20,
            fontWeight: template.formatoCategoria == CategoryFormatting.bold
                ? FontWeight.bold
                : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        // Produtos
        ...produtos.map((produto) => _buildProduto(produto)),
      ],
    );
  }

  Widget _buildProdutosListaUnica() {
    final produtosFiltrados = _filtrarProdutos(todosProdutos);
    produtosFiltrados.sort((a, b) => a.nome.compareTo(b.nome));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: produtosFiltrados.map((produto) => _buildProduto(produto)).toList(),
    );
  }

  Widget _buildProduto(Produto produto) {
    final nomeFormatado = _formatarNomeProduto(produto.nome);
    final precoFormatado = _formatarPreco(produto.preco);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  // Nome do produto
                  _buildNomeProdutoSpan(nomeFormatado),
                  
                  // Preço (se não estiver oculto)
                  if (!template.ocultarPrecos) ...[
                    const TextSpan(text: ': '),
                    TextSpan(
                      text: precoFormatado,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  
                  // Status inativo
                  if (!produto.isAtivo)
                    const TextSpan(
                      text: ' (inativo)',
                      style: TextStyle(
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildNomeProdutoSpan(String nome) {
    switch (template.formatoNomeProduto) {
      case ProductNameFormatting.firstWordBold:
        final palavras = nome.split(' ');
        final primeiraPalavra = palavras.first;
        final restoDoNome = palavras.skip(1).join(' ');
        
        if (restoDoNome.isEmpty) {
          return TextSpan(
            text: primeiraPalavra,
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
        } else {
          return TextSpan(
            children: [
              TextSpan(
                text: primeiraPalavra,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' $restoDoNome'),
            ],
          );
        }
      
      case ProductNameFormatting.fullBold:
        return TextSpan(
          text: nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
      
      case ProductNameFormatting.normal:
        return TextSpan(text: nome);
    }
  }

  List<Produto> _filtrarProdutos(List<Produto> produtos) {
    switch (template.filtroProdutos) {
      case ProductFilter.activeWithPrice:
        return produtos.where((p) => p.isAtivo && p.preco > 0).toList();
      case ProductFilter.allActive:
        return produtos.where((p) => p.isAtivo).toList();
      case ProductFilter.all:
        return produtos;
    }
  }

  String _formatarNomeCategoria(String nome) {
    switch (template.formatoCategoria) {
      case CategoryFormatting.uppercase:
        return nome.toUpperCase();
      case CategoryFormatting.bold:
      case CategoryFormatting.normal:
        return nome;
    }
  }

  String _formatarNomeProduto(String nome) {
    // Retorna o nome sem formatação, pois a formatação é feita no TextSpan
    return nome;
  }

  String _formatarPreco(double preco) {
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
