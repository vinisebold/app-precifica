import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'tutorial_config.dart';

/// Widget customizado para os tooltips do tutorial.
class TutorialTooltip extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final bool showSkip;
  final String? buttonText;

  const TutorialTooltip({
    required this.title,
    required this.description,
    this.onNext,
    this.onSkip,
    this.showSkip = true,
    this.buttonText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final effectiveButtonText = buttonText ?? TutorialConfig.buttonNext(context);

    final backgroundColor = colorScheme.surfaceContainerHigh;
  final titleColor =
    colorScheme.onSurface.withValues(alpha: isDark ? 0.92 : 0.86);
  final descriptionColor = colorScheme.onSurfaceVariant
    .withValues(alpha: isDark ? 0.88 : 0.72);
  final skipColor = colorScheme.onSurfaceVariant
    .withValues(alpha: isDark ? 0.75 : 0.6);
  final primaryShadow =
    colorScheme.shadow.withValues(alpha: isDark ? 0.55 : 0.2);
    final filledButtonStyle = FilledButton.styleFrom(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
    );

    return Container(
      padding: const EdgeInsets.all(TutorialConfig.tooltipPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(TutorialConfig.tooltipRadius),
        boxShadow: [
          BoxShadow(
            color: primaryShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: descriptionColor,
            ),
          ),
          const SizedBox(height: TutorialConfig.tooltipActionSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showSkip && onSkip != null) ...[
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: skipColor,
                  ),
                  child: Text(TutorialConfig.buttonSkip(context)),
                ),
                const SizedBox(width: 8),
              ],
              if (onNext != null)
                FilledButton(
                  onPressed: onNext,
                  style: filledButtonStyle,
                  child: Text(effectiveButtonText),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget helper para criar um Showcase com configuração padrão.
Widget buildTutorialShowcase({
  required BuildContext context,
  required GlobalKey key,
  required Widget child,
  required String title,
  required String description,
  VoidCallback? onTargetClick,
  VoidCallback? onToolTipClick,
  TooltipPosition? tooltipPosition,
  ShapeBorder? targetShapeBorder,
  EdgeInsets? targetPadding,
  double? targetBorderRadius,
  Color? overlayColor,
  bool disposeOnTap = true,
  bool? disableDefaultTargetGestures,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;
  final isDark = theme.brightness == Brightness.dark;

  final titleStyle = textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w700,
  color: colorScheme.onSurface.withValues(alpha: isDark ? 0.92 : 0.86),
  );

  final descriptionStyle = textTheme.bodyMedium?.copyWith(
  color: colorScheme.onSurfaceVariant.withValues(alpha: isDark ? 0.88 : 0.68),
    height: 1.35,
  );

  final tooltipBackground = colorScheme.surfaceContainerHigh;
  final overlayTint =
    overlayColor ?? colorScheme.scrim.withValues(alpha: isDark ? 0.65 : 0.32);

  final effectiveOnTargetClick = onTargetClick ?? () {};

  return Showcase(
    key: key,
    title: title,
    description: description,
    tooltipBackgroundColor: tooltipBackground,
    titleTextStyle: titleStyle,
    descTextStyle: descriptionStyle,
    tooltipPadding: const EdgeInsets.all(TutorialConfig.tooltipPadding),
    targetShapeBorder: targetShapeBorder ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(targetBorderRadius ?? 12),
        ),
    targetPadding: targetPadding ?? EdgeInsets.zero,
    tooltipPosition: tooltipPosition,
    onTargetClick: effectiveOnTargetClick,
    onToolTipClick: onToolTipClick,
    disposeOnTap: disposeOnTap,
    disableDefaultTargetGestures:
        disableDefaultTargetGestures ?? TutorialConfig.disableDefaultTargetGestures,
    overlayColor: overlayTint,
    disableBarrierInteraction: TutorialConfig.disableBarrierInteraction,
    disableMovingAnimation: false,
    scaleAnimationDuration: TutorialConfig.animationDuration,
    scaleAnimationCurve: Curves.easeOutCubic,
    child: child,
  );
}

/// Botão flutuante sutil para pular o tutorial.
/// Usa o globalFloatingActionWidget do ShowcaseView para ficar garantidamente acima.
class SkipTutorialButton extends StatelessWidget {
  final VoidCallback onSkip;

  const SkipTutorialButton({
    required this.onSkip,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Semantics(
        label: TutorialConfig.buttonSkip(context),
        button: true,
        enabled: true,
        onTap: onSkip,
        child: GestureDetector(
          onTap: onSkip,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(
                alpha: isDark ? 0.7 : 0.8,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.skip_next,
                  size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(
                    alpha: isDark ? 0.7 : 0.6,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  TutorialConfig.buttonSkip(context),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: isDark ? 0.7 : 0.6,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}