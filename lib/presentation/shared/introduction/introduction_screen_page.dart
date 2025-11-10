import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'introduction_service.dart';
import '../../gestao_produtos/gestao_page.dart';

/// Provider para o serviço de introdução
final introductionServiceProvider = Provider<IntroductionService>((ref) {
  return IntroductionService();
});

/// Tela de introdução moderna do aplicativo usando introduction_screen.
/// Explica o problema que o Precifica resolve de forma clara e visual.
class IntroductionScreenPage extends ConsumerWidget {
  const IntroductionScreenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntroductionScreen(
      pages: [
        // Página 1: O Problema
        PageViewModel(
          title: "Preços desorganizados?",
          body: "Atualizar preços em listas de papel, planilhas ou anotações é trabalhoso e lento.",
          image: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.assignment_late_outlined,
                size: 80,
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          decoration: PageDecoration(
            titleTextStyle: textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            bodyTextStyle: textTheme.bodyLarge!.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            imagePadding: const EdgeInsets.only(top: 60, bottom: 40),
            pageColor: colorScheme.surface,
          ),
        ),

        // Página 2: A Dor
        PageViewModel(
          title: "Perdendo tempo?",
          body: "Distribuir preços atualizados para clientes pelo WhatsApp ou imprimindo é repetitivo e ineficiente.",
          image: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.schedule_outlined,
                size: 80,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          decoration: PageDecoration(
            titleTextStyle: textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            bodyTextStyle: textTheme.bodyLarge!.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            imagePadding: const EdgeInsets.only(top: 60, bottom: 40),
            pageColor: colorScheme.surface,
          ),
        ),

        // Página 3: A Solução - Espaço para imagem futura
        PageViewModel(
          title: "Precifica resolve isso!",
          body: "Centralize todos os seus produtos e preços em um só lugar. Organize por categorias de forma prática.",
          image: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_special_outlined,
                    size: 60,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Suas\nCategorias',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium!.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          decoration: PageDecoration(
            titleTextStyle: textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            bodyTextStyle: textTheme.bodyLarge!.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            imagePadding: const EdgeInsets.only(top: 60, bottom: 40),
            pageColor: colorScheme.surface,
          ),
        ),

        // Página 4: Compartilhar - Espaço para imagem futura
        PageViewModel(
          title: "Compartilhe facilmente",
          body: "Envie suas listas de preços atualizadas pelo WhatsApp ou imprima de forma rápida e profissional.",
          image: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.share_outlined,
                size: 80,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          decoration: PageDecoration(
            titleTextStyle: textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            bodyTextStyle: textTheme.bodyLarge!.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            imagePadding: const EdgeInsets.only(top: 60, bottom: 40),
            pageColor: colorScheme.surface,
          ),
        ),

        // Página 5: Pronto para começar
        PageViewModel(
          title: "Pronto para começar!",
          body: "Vamos configurar seu primeiro catálogo de produtos. É rápido e fácil!",
          image: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.rocket_launch_outlined,
                size: 80,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          decoration: PageDecoration(
            titleTextStyle: textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            bodyTextStyle: textTheme.bodyLarge!.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            imagePadding: const EdgeInsets.only(top: 60, bottom: 40),
            pageColor: colorScheme.surface,
          ),
        ),
      ],
      onDone: () => _onIntroductionComplete(context, ref),
      onSkip: () => _onIntroductionComplete(context, ref),
      showSkipButton: true,
      skip: Text(
        'Pular',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      next: Icon(
        Icons.arrow_forward,
        color: colorScheme.primary,
      ),
      done: Text(
        'Começar',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(24.0, 10.0),
        activeColor: colorScheme.primary,
        color: colorScheme.surfaceContainerHighest,
        spacing: const EdgeInsets.symmetric(horizontal: 4.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
      globalBackgroundColor: colorScheme.surface,
      curve: Curves.easeInOut,
      controlsPadding: const EdgeInsets.all(16),
      dotsContainerDecorator: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh.withOpacity(0.3)
            : colorScheme.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  /// Callback chamado quando a introdução é completada
  Future<void> _onIntroductionComplete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Marca a introdução como completada
    await ref.read(introductionServiceProvider).setIntroductionCompleted();

    if (!context.mounted) return;

    // Navega para a tela principal (GestaoPage)
    // O tutorial showcase será iniciado automaticamente pelo TutorialController
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GestaoPage(),
      ),
    );
  }
}
