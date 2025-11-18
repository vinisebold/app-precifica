import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/categoria.dart';
import '../../domain/entities/produto.dart';
import '../../domain/entities/report_template.dart';

/// Serviço responsável por gerar e compartilhar relatórios em PDF prontos para impressão
/// garantindo, sempre que possível, que o conteúdo ocupe no máximo duas páginas A4.
class ReportImageService {
  static const double _maxFontSize = 13;
  static const double _minFontSize = 6;
  static const double _fontStep = 0.5;

  Future<void> compartilharRelatorioComoImagem({
    required ReportTemplate template,
    required List<Categoria> categorias,
    required List<Produto> todosProdutos,
  }) async {
    final pdfBytes = await _gerarPdfAjustado(
      template: template,
      categorias: categorias,
      todosProdutos: todosProdutos,
    );

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/relatorio_$timestamp.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType: 'application/pdf',
          name: 'relatorio_precos.pdf',
        ),
      ],
      text:
          'Relatório de Produtos - ${template.titulo.isEmpty ? 'Precifica' : template.titulo}',
    );

    Future.delayed(const Duration(seconds: 10), () {
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // Ignora eventuais erros ao remover o arquivo temporário
      }
    });
  }

  Future<Uint8List> _gerarPdfAjustado({
    required ReportTemplate template,
    required List<Categoria> categorias,
    required List<Produto> todosProdutos,
  }) async {
    double fontSize = _maxFontSize;
    late _PdfResult resultado;

    while (true) {
      resultado = await _gerarPdf(
        template: template,
        categorias: categorias,
        todosProdutos: todosProdutos,
        fontSize: fontSize,
      );

      if (resultado.pageCount <= 2 || fontSize <= _minFontSize) {
        break;
      }

      fontSize =
          (fontSize - _fontStep).clamp(_minFontSize, _maxFontSize).toDouble();
    }

    // Se ainda extrapolar, tenta novamente com margens reduzidas.
    if (resultado.pageCount > 2) {
      resultado = await _gerarPdf(
        template: template,
        categorias: categorias,
        todosProdutos: todosProdutos,
        fontSize: _minFontSize,
  margin: const pw.EdgeInsets.fromLTRB(18, 18, 18, 28),
      );
    }

    return resultado.bytes;
  }

  Future<_PdfResult> _gerarPdf({
    required ReportTemplate template,
    required List<Categoria> categorias,
    required List<Produto> todosProdutos,
    required double fontSize,
    pw.EdgeInsets? margin,
  }) async {
    final document = pw.Document();
    final categoriasOrdenadas = List<Categoria>.from(categorias)
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
  margin: margin ?? const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        build: (context) => _buildConteudo(
          template: template,
          categorias: categoriasOrdenadas,
          todosProdutos: todosProdutos,
          fontSize: fontSize,
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize:
                  ((fontSize - 2).clamp(_minFontSize - 1, fontSize)).toDouble(),
              color: PdfColors.grey700,
            ),
          ),
        ),
      ),
    );

    final bytes = await document.save();
    final pageCount = document.document.pdfPageList.pages.length;

    return _PdfResult(bytes: bytes, pageCount: pageCount);
  }

  List<pw.Widget> _buildConteudo({
    required ReportTemplate template,
    required List<Categoria> categorias,
    required List<Produto> todosProdutos,
    required double fontSize,
  }) {
    final widgets = <pw.Widget>[];

    widgets.add(_buildCabecalho(template, fontSize));
    widgets.add(pw.SizedBox(height: fontSize));

    if (template.agruparPorCategoria) {
      for (final categoria in categorias) {
        final produtosDaCategoria = _filtrarProdutos(
          todosProdutos.where((p) => p.categoriaId == categoria.id).toList(),
          template.filtroProdutos,
        );

        if (produtosDaCategoria.isEmpty) continue;

        widgets.add(
          _buildCategoria(
            nomeCategoria: categoria.nome,
            produtos: produtosDaCategoria,
            template: template,
            fontSize: fontSize,
          ),
        );
        widgets.add(pw.SizedBox(height: fontSize * 0.6));
      }
    } else {
      final produtos = _filtrarProdutos(
        List<Produto>.from(todosProdutos)
          ..sort((a, b) => a.nome.compareTo(b.nome)),
        template.filtroProdutos,
      );

      for (final produto in produtos) {
        widgets.add(_buildProduto(produto, template, fontSize));
      }
    }

    if (template.mensagemRodape.isNotEmpty) {
      widgets.add(pw.SizedBox(height: fontSize));
      widgets.add(_buildRodape(template, fontSize));
    }

    return widgets;
  }

  pw.Widget _buildCabecalho(ReportTemplate template, double fontSize) {
    final hoje = DateTime.now();
    final children = <pw.Widget>[];

    if (template.titulo.isNotEmpty) {
      final titulo = template.mostrarDiaSemana
          ? '${template.titulo}: ${DateFormat('EEEE', 'pt_BR').format(hoje)}'
          : template.titulo;

      children.add(
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontSize: fontSize + 6,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      );
      children.add(pw.SizedBox(height: 6));
    }

    if (template.mostrarData) {
      children.add(
        pw.Text(
          DateFormat('dd/MM/yy').format(hoje),
          style: pw.TextStyle(
            fontSize: fontSize - 1,
            color: PdfColors.grey700,
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _buildRodape(ReportTemplate template, double fontSize) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#f5f5f5'),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        template.mensagemRodape,
        style: pw.TextStyle(
          fontSize: fontSize - 1,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildCategoria({
    required String nomeCategoria,
    required List<Produto> produtos,
    required ReportTemplate template,
    required double fontSize,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _formatarNomeCategoria(nomeCategoria, template.formatoCategoria),
          style: pw.TextStyle(
            fontSize: fontSize + 2,
            fontWeight: template.formatoCategoria == CategoryFormatting.bold
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(height: fontSize * 0.3),
        ...produtos.map((produto) => _buildProduto(produto, template, fontSize)),
      ],
    );
  }

  pw.Widget _buildProduto(
    Produto produto,
    ReportTemplate template,
    double fontSize,
  ) {
    final baseStyle = pw.TextStyle(
      fontSize: fontSize,
      color: PdfColors.black,
      height: 1.2,
    );

    final spans = <pw.InlineSpan>[];
    spans.addAll(
      _buildNomeProdutoSpans(
        produto.nome,
        template.formatoNomeProduto,
        baseStyle,
      ),
    );

    if (!template.ocultarPrecos) {
      spans.add(const pw.TextSpan(text: ': '));
      spans.add(
        pw.TextSpan(
          text: _formatarPreco(produto.preco, template),
          style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    if (!produto.isAtivo) {
      spans.add(
        pw.TextSpan(
          text: ' (inativo)',
          style: baseStyle.copyWith(
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.red400,
          ),
        ),
      );
    }

    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: fontSize * 0.1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: fontSize * 0.35,
            height: fontSize * 0.35,
            margin: pw.EdgeInsets.only(top: fontSize * 0.35),
            decoration: const pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(width: fontSize * 0.5),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                style: baseStyle,
                children: spans,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<pw.TextSpan> _buildNomeProdutoSpans(
    String nome,
    ProductNameFormatting formato,
    pw.TextStyle baseStyle,
  ) {
  final texto = nome.trim();
  if (texto.isEmpty) return [const pw.TextSpan(text: '')];

    switch (formato) {
      case ProductNameFormatting.firstWordBold:
        final partes = texto.split(RegExp(r'\s+'));
        final primeira = partes.first;
        final resto = partes.skip(1).join(' ');
        return [
          pw.TextSpan(
            text: primeira,
            style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
          ),
          if (resto.isNotEmpty) pw.TextSpan(text: ' $resto'),
        ];
      case ProductNameFormatting.fullBold:
        return [
          pw.TextSpan(
            text: texto,
            style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
          ),
        ];
      case ProductNameFormatting.normal:
        return [pw.TextSpan(text: texto)];
    }
  }

  List<Produto> _filtrarProdutos(
    List<Produto> produtos,
    ProductFilter filtro,
  ) {
    switch (filtro) {
      case ProductFilter.activeWithPrice:
        return produtos.where((p) => p.isAtivo && p.preco > 0).toList();
      case ProductFilter.allActive:
        return produtos.where((p) => p.isAtivo).toList();
      case ProductFilter.all:
        return produtos;
    }
  }

  String _formatarNomeCategoria(String nome, CategoryFormatting formato) {
    switch (formato) {
      case CategoryFormatting.uppercase:
        return nome.toUpperCase();
      case CategoryFormatting.bold:
      case CategoryFormatting.normal:
        return nome;
    }
  }

  String _formatarPreco(double preco, ReportTemplate template) {
    if (preco == 0) {
      return template.textoPrecoZero;
    }

    final valorFormatado = preco.toStringAsFixed(2).replaceAll('.', ',');
    return template.mostrarCifraoPreco ? 'R\$ $valorFormatado' : valorFormatado;
  }
}

class _PdfResult {
  final Uint8List bytes;
  final int pageCount;

  const _PdfResult({required this.bytes, required this.pageCount});
}
