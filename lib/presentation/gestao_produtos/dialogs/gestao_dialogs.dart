import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:precifica/app/core/l10n/app_localizations.dart';
import 'package:precifica/app/core/snackbar/app_snackbar.dart';

import '../gestao_controller.dart';
import '../../shared/showcase/tutorial_controller.dart';
import '../../shared/showcase/tutorial_config.dart';
import '../../shared/showcase/tutorial_keys.dart';
import '../../shared/showcase/tutorial_widgets.dart';

/// Classe utilitária que contém todos os diálogos usados na GestaoPage.
class GestaoDialogs {
  GestaoDialogs._();

  /// Mostra diálogo de confirmação genérico.
  static void mostrarDialogoConfirmarAcao({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    required VoidCallback onConfirmar,
  }) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.cancel ?? 'Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirmar();
            },
            child: Text(l10n?.confirm ?? 'Confirmar'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo para salvar perfil atual.
  static void mostrarDialogoSalvarPerfil(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.saveCurrentProfile ?? 'Salvar Perfil Atual'),
        content: TextField(
          controller: controller,
          decoration:
              InputDecoration(hintText: l10n?.profileName ?? 'Nome do Perfil'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.cancel ?? 'Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(gestaoControllerProvider.notifier)
                  .salvarPerfilAtual(controller.text);
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n?.save ?? 'Salvar'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo para editar nome (categoria ou produto).
  static void mostrarDialogoEditarNome(
    BuildContext context,
    WidgetRef ref, {
    required String titulo,
    required String valorAtual,
    required Function(String) onSalvar,
  }) {
    final controller = TextEditingController(text: valorAtual);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo, style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n?.newName ?? "Novo nome"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child:
                Text(l10n?.cancel ?? 'Cancelar', style: textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () {
              final novoNome = controller.text;
              if (novoNome.isNotEmpty) {
                onSalvar(novoNome);
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(l10n?.save ?? 'Salvar', style: textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo para adicionar novo produto.
  static void mostrarDialogoNovoProduto({
    required BuildContext pageContext,
    required WidgetRef ref,
    required bool Function() isMounted,
    required VoidCallback onProductSaved,
  }) {
    final controller = TextEditingController();
    final textTheme = Theme.of(pageContext).textTheme;
    final colorScheme = Theme.of(pageContext).colorScheme;
    final l10n = AppLocalizations.of(pageContext);

    final tutorialState = ref.read(tutorialControllerProvider);
    final isAwaitingFirstProductTutorial = tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.awaitingFirstProduct;

    Timer? savePromptTimer;
    bool hasShownSavePrompt = false;
    bool listenerAttached = false;
    bool isDisposed = false;
    bool isClosing = false;

    void cancelSavePromptTimer() {
      savePromptTimer?.cancel();
      savePromptTimer = null;
    }

    void triggerSaveShowcase() {
      if (!isMounted() ||
          !isAwaitingFirstProductTutorial ||
          hasShownSavePrompt ||
          isDisposed) {
        return;
      }
      hasShownSavePrompt = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isMounted() || isDisposed) return;
        ShowcaseView.get()
            .startShowCase([TutorialKeys.productDialogSaveButton]);
      });
    }

    void textListener() {
      if (!isMounted() || isDisposed) return;
      cancelSavePromptTimer();
      if (hasShownSavePrompt) return;
      if (controller.text.trim().isEmpty) return;
      savePromptTimer =
          Timer(const Duration(milliseconds: 2600), triggerSaveShowcase);
    }

    if (isAwaitingFirstProductTutorial) {
      controller.addListener(textListener);
      listenerAttached = true;
    }

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        void handleCancel() {
          if (isDisposed || isClosing) return;
          isClosing = true;
          cancelSavePromptTimer();
          Navigator.of(dialogContext).pop();
        }

        void handleSave() {
          if (isDisposed || isClosing) return;
          isClosing = true;
          cancelSavePromptTimer();
          _salvarNovoProduto(
            pageContext: pageContext,
            dialogContext: dialogContext,
            controller: controller,
            ref: ref,
            isMounted: isMounted,
          );
        }

        return AlertDialog(
          title: Text(l10n?.newProduct ?? 'Novo Produto',
              style: textTheme.headlineSmall),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n?.productName ?? "Nome do produto",
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            autofocus: true,
            onSubmitted: (_) => handleSave(),
          ),
          actions: [
            TextButton(
              onPressed: handleCancel,
              child:
                  Text(l10n?.cancel ?? 'Cancelar', style: textTheme.labelLarge),
            ),
            Builder(
              builder: (context) {
                Widget saveButton = TextButton(
                  onPressed: handleSave,
                  child:
                      Text(l10n?.save ?? 'Salvar', style: textTheme.labelLarge),
                );

                if (isAwaitingFirstProductTutorial) {
                  saveButton = buildTutorialShowcase(
                    context: context,
                    key: TutorialKeys.productDialogSaveButton,
                    title: TutorialConfig.productSaveTitle(context),
                    description: TutorialConfig.productSaveDescription(context),
                    targetShapeBorder: const CircleBorder(),
                    targetPadding: const EdgeInsets.all(4),
                    onTargetClick: () {
                      ShowcaseView.get().dismiss();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!isDisposed && !isClosing) {
                          handleSave();
                        }
                      });
                    },
                    child: saveButton,
                  );
                }

                return saveButton;
              },
            ),
          ],
        );
      },
    ).then((_) {
      if (isDisposed) return;
      isDisposed = true;
      cancelSavePromptTimer();
      if (listenerAttached) {
        controller.removeListener(textListener);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    });
  }

  static void _salvarNovoProduto({
    required BuildContext pageContext,
    required BuildContext dialogContext,
    required TextEditingController controller,
    required WidgetRef ref,
    required bool Function() isMounted,
  }) {
    HapticFeedback.lightImpact();
    final nomeProduto = controller.text.trim();
    if (nomeProduto.isNotEmpty) {
      ref.read(gestaoControllerProvider.notifier).criarProduto(nomeProduto);
      Navigator.of(dialogContext).pop();

      // Exibe feedback de sucesso
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isMounted()) {
          final l10n = AppLocalizations.of(pageContext);
          AppSnackbar.showSuccess(
            pageContext,
            l10n?.productAdded(nomeProduto) ??
                'Produto "$nomeProduto" adicionado com sucesso!',
          );
        }
      });
    }
  }

  /// Mostra diálogo para adicionar nova categoria.
  static void mostrarDialogoNovaCategoria({
    required BuildContext pageContext,
    required WidgetRef ref,
    required bool Function() isMounted,
    required VoidCallback onCategorySaved,
  }) {
    final controller = TextEditingController();
    final textTheme = Theme.of(pageContext).textTheme;
    final colorScheme = Theme.of(pageContext).colorScheme;
    final l10n = AppLocalizations.of(pageContext);

    final tutorialState = ref.read(tutorialControllerProvider);
    final isAwaitingFirstCategoryTutorial = tutorialState.isActive &&
        tutorialState.currentStep == TutorialStep.awaitingFirstCategory;

    Timer? savePromptTimer;
    bool hasShownSavePrompt = false;
    bool listenerAttached = false;
    bool isDisposed = false;
    bool isClosing = false;

    void cancelSavePromptTimer() {
      savePromptTimer?.cancel();
      savePromptTimer = null;
    }

    void triggerSaveShowcase() {
      if (!isMounted() ||
          !isAwaitingFirstCategoryTutorial ||
          hasShownSavePrompt ||
          isDisposed) {
        return;
      }
      hasShownSavePrompt = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isMounted() || isDisposed) return;
        ShowcaseView.get()
            .startShowCase([TutorialKeys.categoryDialogSaveButton]);
      });
    }

    void textListener() {
      if (!isMounted() || isDisposed) return;
      cancelSavePromptTimer();
      if (hasShownSavePrompt) return;
      if (controller.text.trim().isEmpty) return;
      savePromptTimer =
          Timer(const Duration(milliseconds: 2200), triggerSaveShowcase);
    }

    if (isAwaitingFirstCategoryTutorial) {
      controller.addListener(textListener);
      listenerAttached = true;
    }

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        void handleCancel() {
          if (isDisposed || isClosing) return;
          isClosing = true;
          cancelSavePromptTimer();
          Navigator.of(dialogContext).pop();
        }

        void handleSave() {
          if (isDisposed || isClosing) return;
          isClosing = true;
          cancelSavePromptTimer();
          _salvarNovaCategoria(
            pageContext: pageContext,
            dialogContext: dialogContext,
            controller: controller,
            ref: ref,
            isMounted: isMounted,
          );
        }

        return AlertDialog(
          title: Text(l10n?.newCategory ?? 'Nova Categoria',
              style: textTheme.headlineSmall),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n?.categoryName ?? "Nome da categoria",
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            autofocus: true,
            onSubmitted: (_) => handleSave(),
          ),
          actions: [
            TextButton(
              onPressed: handleCancel,
              child:
                  Text(l10n?.cancel ?? 'Cancelar', style: textTheme.labelLarge),
            ),
            Builder(
              builder: (context) {
                Widget saveButton = TextButton(
                  onPressed: handleSave,
                  child:
                      Text(l10n?.save ?? 'Salvar', style: textTheme.labelLarge),
                );

                if (isAwaitingFirstCategoryTutorial) {
                  saveButton = buildTutorialShowcase(
                    context: context,
                    key: TutorialKeys.categoryDialogSaveButton,
                    title: TutorialConfig.categorySaveTitle(context),
                    description:
                        TutorialConfig.categorySaveDescription(context),
                    targetShapeBorder: const CircleBorder(),
                    targetPadding: const EdgeInsets.all(4),
                    onTargetClick: () {
                      ShowcaseView.get().dismiss();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!isDisposed && !isClosing) {
                          handleSave();
                        }
                      });
                    },
                    child: saveButton,
                  );
                }

                return saveButton;
              },
            ),
          ],
        );
      },
    ).then((_) {
      if (isDisposed) return;
      isDisposed = true;
      cancelSavePromptTimer();
      if (listenerAttached) {
        controller.removeListener(textListener);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    });
  }

  static void _salvarNovaCategoria({
    required BuildContext pageContext,
    required BuildContext dialogContext,
    required TextEditingController controller,
    required WidgetRef ref,
    required bool Function() isMounted,
  }) {
    HapticFeedback.lightImpact();
    final nomeCategoria = controller.text.trim();
    if (nomeCategoria.isNotEmpty) {
      ref
          .read(gestaoControllerProvider.notifier)
          .criarCategoria(nomeCategoria);
      Navigator.of(dialogContext).pop();

      // Exibe feedback de sucesso
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isMounted()) {
          final l10n = AppLocalizations.of(pageContext);
          AppSnackbar.showSuccess(
            pageContext,
            l10n?.categoryAdded(nomeCategoria) ??
                'Categoria "$nomeCategoria" adicionada com sucesso!',
          );
        }
      });
    }
  }

  /// Mostra diálogo de confirmação para organizar com IA.
  static void mostrarDialogoConfirmacaoIA(
      BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => ConfirmacaoIAOverlay(
        onConfirmar: () {
          Navigator.of(dialogContext).pop();
          ref.read(gestaoControllerProvider.notifier).organizarComIA();
        },
        onCancelar: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}

/// Overlay de confirmação para organizar com IA.
class ConfirmacaoIAOverlay extends StatelessWidget {
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  const ConfirmacaoIAOverlay({
    super.key,
    required this.onConfirmar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);
    final overlayColor = theme.brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.82)
        : Colors.black.withValues(alpha: 0.02);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Overlay de blur cobrindo toda a tela sem restrições
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: overlayColor,
              ),
            ),
          ),
          // Conteúdo do diálogo respeitando SafeArea
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: colorScheme.primary,
                          size: 56,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n?.organizeWithAIQuestion ?? 'Organizar com IA?',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n?.organizeWithAIConfirmation ??
                              'Tem certeza que deseja reorganizar seus produtos automaticamente?',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onCancelar,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(l10n?.cancel ?? 'Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: onConfirmar,
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(l10n?.confirm ?? 'Confirmar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
