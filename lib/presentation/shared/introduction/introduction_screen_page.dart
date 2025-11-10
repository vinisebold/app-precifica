import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../gestao_produtos/gestao_page.dart';
import 'introduction_service.dart';

/// Provider para o serviço de introdução
final introductionServiceProvider = Provider<IntroductionService>((ref) {
  return IntroductionService();
});

/// Tela de introdução desenvolvida manualmente para apresentar os principais
/// benefícios do Precifica com um layout previsível e sem dependências de
/// pacotes de terceiros.
class IntroductionScreenPage extends ConsumerStatefulWidget {
  const IntroductionScreenPage({super.key});

  @override
  ConsumerState<IntroductionScreenPage> createState() => _IntroductionScreenPageState();
}

class _IntroductionScreenPageState extends ConsumerState<IntroductionScreenPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pages = _buildPages(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildPage(context, page),
                  );
                },
              ),
            ),
            _buildBottomBar(context, pages.length),
          ],
        ),
      ),
    );
  }

  List<_IntroductionPageData> _buildPages(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      _IntroductionPageData.phone(
        title: 'Preços desorganizados?',
        body:
            'Atualizar preços em listas de papel, planilhas ou anotações é trabalhoso e lento.',
        assetPath: 'assets/introduction/example1.png',
        primaryColor: colorScheme.errorContainer.withOpacity(0.3),
      ),
      _IntroductionPageData.icon(
        title: 'Perdendo tempo?',
        body:
            'Distribuir preços atualizados para clientes pelo WhatsApp ou imprimindo é repetitivo e ineficiente.',
        icon: Icons.schedule_outlined,
        primaryColor: colorScheme.tertiaryContainer,
        iconColor: colorScheme.onTertiaryContainer,
      ),
      _IntroductionPageData.icon(
        title: 'Precifica resolve isso!',
        body:
            'Centralize todos os seus produtos e preços em um só lugar. Organize por categorias de forma prática.',
        icon: Icons.folder_special_outlined,
        primaryColor: colorScheme.primaryContainer,
        iconColor: colorScheme.onPrimaryContainer,
        titleColor: colorScheme.primary,
        hasSubtext: true,
        subtext: 'Suas\nCategorias',
      ),
      _IntroductionPageData.icon(
        title: 'Compartilhe facilmente',
        body:
            'Envie suas listas de preços atualizadas pelo WhatsApp ou imprima de forma rápida e profissional.',
        icon: Icons.share_outlined,
        primaryColor: colorScheme.secondaryContainer,
        iconColor: colorScheme.onSecondaryContainer,
        titleColor: colorScheme.primary,
      ),
      _IntroductionPageData.icon(
        title: 'Pronto para começar!',
        body: 'Vamos configurar seu primeiro catálogo de produtos. É rápido e fácil!',
        icon: Icons.rocket_launch_outlined,
        primaryColor: colorScheme.primary,
        iconColor: colorScheme.onPrimary,
        titleColor: colorScheme.primary,
        gradientColors: [colorScheme.primary, colorScheme.secondary],
      ),
    ];
  }

  Widget _buildPage(BuildContext context, _IntroductionPageData page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (page.type) {
          case _IntroductionPageType.phone:
            return _buildPhonePage(context, constraints, page);
          case _IntroductionPageType.icon:
            return _buildIconPage(context, constraints, page);
        }
      },
    );
  }

  Widget _buildPhonePage(
    BuildContext context,
    BoxConstraints constraints,
    _IntroductionPageData page,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: page.primaryColor,
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                child: Image.asset(
                  page.assetPath!,
                  fit: BoxFit.contain,
                  width: constraints.maxWidth,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  page.body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconPage(
    BuildContext context,
    BoxConstraints constraints,
    _IntroductionPageData page,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: page.primaryColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
            child: Center(
              child: Container(
                width: constraints.maxWidth * 0.5,
                constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
                decoration: BoxDecoration(
                  color: page.gradientColors == null ? page.primaryColor : null,
                  gradient: page.gradientColors != null
                      ? LinearGradient(
                          colors: page.gradientColors!,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: page.hasSubtext
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            page.icon,
                            size: 60,
                            color: page.iconColor ?? colorScheme.onPrimary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            page.subtext!,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: page.iconColor ?? colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        page.icon,
                        size: 80,
                        color: page.iconColor ?? colorScheme.onPrimary,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: page.titleColor ?? colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  page.body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, int totalPages) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isLastPage = _currentPage == totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHigh.withOpacity(0.3)
              : colorScheme.surfaceContainerHigh.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: isLastPage
                  ? const SizedBox.shrink()
                  : TextButton(
                      onPressed: _handleSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Pular'),
                    ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 10,
                    width: isActive ? 24 : 10,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(
              width: 96,
              child: TextButton(
                onPressed: isLastPage ? _handleDone : _handleNext,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: Text(isLastPage ? 'Começar' : 'Próximo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSkip() async {
    await _completeIntroduction();
  }

  Future<void> _handleNext() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleDone() async {
    await _completeIntroduction();
  }

  Future<void> _completeIntroduction() async {
    await ref.read(introductionServiceProvider).setIntroductionCompleted();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => const GestaoPage(),
      ),
    );
  }
}

enum _IntroductionPageType { phone, icon }

class _IntroductionPageData {
  _IntroductionPageData.phone({
    required this.title,
    required this.body,
    required this.assetPath,
    required this.primaryColor,
  })  : type = _IntroductionPageType.phone,
        icon = null,
        iconColor = null,
        titleColor = null,
        gradientColors = null,
        hasSubtext = false,
        subtext = null;

  _IntroductionPageData.icon({
    required this.title,
    required this.body,
    required this.icon,
    required this.primaryColor,
    this.iconColor,
    this.titleColor,
    this.gradientColors,
    this.hasSubtext = false,
    this.subtext,
  })  : type = _IntroductionPageType.icon,
        assetPath = null;

  final _IntroductionPageType type;
  final String title;
  final String body;
  final String? assetPath;
  final IconData? icon;
  final Color primaryColor;
  final Color? iconColor;
  final Color? titleColor;
  final List<Color>? gradientColors;
  final bool hasSubtext;
  final String? subtext;
}
