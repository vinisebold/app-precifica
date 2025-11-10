import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'introduction_screen_page.dart';
import '../../gestao_produtos/gestao_page.dart';

/// Wrapper que controla o fluxo inicial do app:
/// 1. Se a introdução nunca foi exibida -> mostra IntroductionScreen
/// 2. Se já foi exibida -> vai direto para GestaoPage
/// 3. GestaoPage automaticamente iniciará o tutorial showcase se necessário
class AppIntroductionWrapper extends ConsumerStatefulWidget {
  const AppIntroductionWrapper({super.key});

  @override
  ConsumerState<AppIntroductionWrapper> createState() =>
      _AppIntroductionWrapperState();
}

class _AppIntroductionWrapperState
    extends ConsumerState<AppIntroductionWrapper> {
  bool _isLoading = true;
  bool _shouldShowIntroduction = false;

  @override
  void initState() {
    super.initState();
    _checkIntroductionStatus();
  }

  Future<void> _checkIntroductionStatus() async {
    final introductionService = ref.read(introductionServiceProvider);
    final isCompleted = await introductionService.isIntroductionCompleted();

    if (mounted) {
      setState(() {
        _shouldShowIntroduction = !isCompleted;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Tela de loading enquanto verifica o status
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // Decide qual tela mostrar
    if (_shouldShowIntroduction) {
      return const IntroductionScreenPage();
    } else {
      return const GestaoPage();
    }
  }
}
