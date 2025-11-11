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
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

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
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              itemCount: pages.length,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() => _currentPage = index);
                }
              },
              itemBuilder: (context, index) => Column(
                children: [
                  Expanded(
                    flex: 7,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                          child: _buildMediaContent(context, pages[index]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: _buildTextContent(context, pages[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(context, pages.length),
        ],
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
        assetPath: 'assets/introduction/wrong-way.png',
        primaryColor: colorScheme.errorContainer.withOpacity(0.3),
      ),
      _IntroductionPageData.phone(
        title: 'Precifica resolve isso!',
        body:
        'Centralize todos os seus produtos e preços em um só lugar. Organize por categorias de forma prática.',
        assetPath: 'assets/introduction/in-app.png',
        primaryColor: colorScheme.primaryContainer,
      ),
      _IntroductionPageData.phone(
        title: 'Compartilhe facilmente',
        body:
        'Envie suas listas de preços atualizadas pelo WhatsApp ou imprima de forma rápida e profissional.',
        assetPath: 'assets/introduction/sharing.png',
        primaryColor: colorScheme.secondaryContainer,
      ),
      _IntroductionPageData.phone(
        title: 'Pronto para começar!',
        body: 'Vamos configurar seu primeiro catálogo de produtos. É rápido e fácil!',
        assetPath: 'assets/introduction/correct-way.png',
        primaryColor: colorScheme.primary,
      ),
    ];
  }

  Widget _buildMediaContent(BuildContext context, _IntroductionPageData page) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (page.type == _IntroductionPageType.phone) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
          ),
          child: Image.asset(
            page.assetPath!,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
      );
    }

    // Icon page
    return Center(
      child: Container(
        width: double.infinity,
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
    );
  }

  Widget _buildTextContent(BuildContext context, _IntroductionPageData page) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
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
        const Spacer(),
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