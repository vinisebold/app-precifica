import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/produto.dart';
import '../../domain/entities/report_template.dart';
import '../../presentation/shared/widgets/report_image_widget.dart';

/// Serviço responsável por gerar e compartilhar imagens de relatórios
class ReportImageService {
  final ScreenshotController _screenshotController = ScreenshotController();

  /// Gera uma imagem do relatório e compartilha
  Future<void> compartilharRelatorioComoImagem({
    required ReportTemplate template,
    required List<Categoria> categorias,
    required List<Produto> todosProdutos,
  }) async {
    try {
      // Captura o widget como imagem
      final Uint8List? imageBytes = await _screenshotController.captureFromWidget(
        Material(
          child: ReportImageWidget(
            template: template,
            categorias: categorias,
            todosProdutos: todosProdutos,
          ),
        ),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 200),
      );

      if (imageBytes == null) {
        throw Exception('Falha ao capturar imagem do relatório');
      }

      // Salva temporariamente o arquivo
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/relatorio_$timestamp.png');
      await file.writeAsBytes(imageBytes);

      // Compartilha a imagem e aguarda a conclusão
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Relatório de Produtos - ${template.titulo}',
      );

      // Remove o arquivo temporário após um delay
      // Aumenta o delay para garantir que o compartilhamento foi concluído
      Future.delayed(const Duration(seconds: 10), () {
        try {
          if (file.existsSync()) {
            file.delete();
          }
        } catch (_) {
          // Ignora erros ao deletar arquivo temporário
        }
      });
      
      // Retorna normalmente após o compartilhamento
      return;
    } catch (e) {
      rethrow;
    }
  }

  /// Gera uma imagem do relatório e retorna os bytes
  Future<Uint8List?> gerarImagemRelatorio({
    required ReportTemplate template,
    required List<Categoria> categorias,
    required List<Produto> todosProdutos,
  }) async {
    try {
      return await _screenshotController.captureFromWidget(
        Material(
          child: ReportImageWidget(
            template: template,
            categorias: categorias,
            todosProdutos: todosProdutos,
          ),
        ),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 100),
      );
    } catch (e) {
      rethrow;
    }
  }
}
