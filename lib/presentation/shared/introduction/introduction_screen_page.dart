import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/l10n/app_localizations.dart';
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
  Timer? _autoPlayTimer;
  Timer? _progressTimer;
  double _progress = 0.0;
  static const _autoPlayDuration = Duration(seconds: 5);
  static const _progressUpdateInterval = Duration(milliseconds: 16); // ~60fps

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _progressTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _progress = 0.0;
    _progressTimer?.cancel();
    _autoPlayTimer?.cancel();

    _progressTimer = Timer.periodic(_progressUpdateInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _progress += _progressUpdateInterval.inMilliseconds / _autoPlayDuration.inMilliseconds;
        if (_progress >= 1.0) {
          _progress = 1.0;
        }
      });
    });

    _autoPlayTimer = Timer(_autoPlayDuration, () {
      if (!mounted) return;
      
      if (_currentPage < 3) {
        _handleNext();
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _progressTimer?.cancel();
  }

  void _resetAutoPlay() {
    _stopAutoPlay();
    _startAutoPlay();
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
                  _resetAutoPlay();
                }
              },
              itemBuilder: (context, index) => Column(
                children: [
                  Expanded(
                    flex: 8,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: _buildMediaContent(context, pages[index]),
                    ),
                  ),
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
    final l10n = AppLocalizations.of(context)!;

    return [
      _IntroductionPageData(
        title: l10n.introTitle1,
        body: l10n.introBody1,
        assetPath: 'assets/introduction/wrong-way.png',
  primaryColor: colorScheme.errorContainer.withValues(alpha: 0.3),
      ),
      _IntroductionPageData(
        title: l10n.introTitle2,
        body: l10n.introBody2,
        assetPath: 'assets/introduction/in-app.png',
        primaryColor: colorScheme.primaryContainer,
      ),
      _IntroductionPageData(
        title: l10n.introTitle3,
        body: l10n.introBody3,
        assetPath: 'assets/introduction/sharing.png',
        primaryColor: colorScheme.secondaryContainer,
      ),
      _IntroductionPageData(
        title: l10n.introTitle4,
        body: l10n.introBody4,
        assetPath: 'assets/introduction/correct-way.png',
        primaryColor: colorScheme.primary,
      ),
    ];
  }

  Widget _buildMediaContent(BuildContext context, _IntroductionPageData page) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        child: Image.asset(
          page.assetPath,
          fit: BoxFit.contain,
          width: double.infinity,
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
            color: colorScheme.onSurface,
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
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Container(
        decoration: BoxDecoration(
      color: isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.3)
        : colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.5, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: isLastPage
                    ? const SizedBox.shrink(key: ValueKey('empty'))
                    : TextButton(
                        key: const ValueKey('skip'),
                        onPressed: _handleSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        child: Text(l10n.skip),
                      ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  final isActive = index == _currentPage;
                  final isPast = index < _currentPage;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 10,
                    width: 24,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          tween: Tween<double>(
                            begin: isPast ? 24 : (isActive ? 24 * _progress : 0),
                            end: isPast ? 24 : (isActive ? 24 * _progress : 0),
                          ),
                          builder: (context, value, child) {
                            return Container(
                              height: 10,
                              width: value,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(24),
                              ),
                            );
                          },
                        ),
                      ),
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
                child: Text(isLastPage ? l10n.start : l10n.next),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSkip() async {
    _stopAutoPlay();
    await _completeIntroduction();
  }

  Future<void> _handleNext() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleDone() async {
    _stopAutoPlay();
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

class _IntroductionPageData {
  _IntroductionPageData({
    required this.title,
    required this.body,
    required this.assetPath,
    required this.primaryColor,
  });

  final String title;
  final String body;
  final String assetPath;
  final Color primaryColor;
}