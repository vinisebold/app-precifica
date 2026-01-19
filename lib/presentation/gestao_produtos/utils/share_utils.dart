import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:precifica/app/core/snackbar/app_snackbar.dart';
import 'package:precifica/domain/entities/report_template.dart';

import '../gestao_controller.dart';
import '../../configuracoes/settings_controller.dart';
import '../../shared/widgets/share_options_drawer.dart';

/// Utilitários para compartilhamento de relatórios.
class ShareUtils {
  ShareUtils._();

  /// Mostra as opções de compartilhamento (texto ou imagem).
  static void mostrarOpcoesCompartilhamento(
      BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareOptionsDrawer(
        onShareText: () => _compartilharRelatorioTexto(context, ref),
        onShareImage: () => _compartilharRelatorioImagem(context, ref),
      ),
    );
  }

  static void _compartilharRelatorioTexto(BuildContext context, WidgetRef ref) {
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

    final template = settingsNotifier.getTemplateSelecionadoObjeto();

    if (template == null) {
      final textoRelatorio = gestaoNotifier.gerarTextoRelatorio();
      Share.share(textoRelatorio);
    } else {
      final textoRelatorio =
          gestaoNotifier.gerarTextoRelatorioComTemplate(template);
      Share.share(textoRelatorio);
    }
  }

  static Future<void> _compartilharRelatorioImagem(
      BuildContext context, WidgetRef ref) async {
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

    // Obtém o template selecionado ou usa o padrão
    final template = settingsNotifier.getTemplateSelecionadoObjeto() ??
        ReportTemplate.padrao();

    // Guarda uma referência ao navigator antes de operações assíncronas
    final navigator = Navigator.of(context);
    bool dialogShown = false;

    try {
      // Mostra indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
      dialogShown = true;

      await gestaoNotifier.compartilharRelatorioComoImagem(template);
    } catch (e) {
      // Mostra mensagem de erro após fechar o loading
      // Aguarda um pouco para garantir que a UI está pronta
      await Future.delayed(const Duration(milliseconds: 100));
      if (context.mounted) {
        AppSnackbar.show(
          context,
          'Erro ao gerar imagem: ${e.toString()}',
        );
      }
    } finally {
      // Sempre fecha o indicador de carregamento no finally
      if (dialogShown) {
        try {
          navigator.pop();
        } catch (_) {
          // Ignora erro se o diálogo já foi fechado
        }
      }
    }
  }
}
