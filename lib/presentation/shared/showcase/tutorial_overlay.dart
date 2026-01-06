import 'package:flutter/material.dart';
import 'dart:ui';
import 'tutorial_config.dart';

/// Overlay que mostra instruções entre os passos do tutorial.
class TutorialInstructionOverlay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;
  final bool dismissible;

  const TutorialInstructionOverlay({
    required this.title,
    required this.message,
    this.onDismiss,
    this.dismissible = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blur backdrop
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.02),
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Icon(
                      Icons.school_outlined,
                      color: colorScheme.primary,
                      size: 56,
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Message
                    Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (onDismiss != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDismiss?.call();
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            TutorialConfig.buttonGotIt(context),
                            style: textTheme.labelLarge,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mostra um overlay de instrução.
void showTutorialInstruction({
  required BuildContext context,
  required String title,
  required String message,
  VoidCallback? onDismiss,
  bool barrierDismissible = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black54,
    builder: (context) => TutorialInstructionOverlay(
      title: title,
      message: message,
      onDismiss: onDismiss ?? () => Navigator.of(context).pop(),
      dismissible: true,
    ),
  );
}

