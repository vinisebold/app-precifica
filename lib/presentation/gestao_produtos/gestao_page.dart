import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:precifica/domain/entities/produto.dart';
import 'package:precifica/app/core/toast/global_toast_controller.dart';

import 'gestao_controller.dart';
import 'gestao_state.dart';

import 'widgets/categoria_nav_bar.dart';
import 'widgets/product_list_view.dart';

class GestaoPage extends ConsumerStatefulWidget {
  const GestaoPage({super.key});

  @override
  ConsumerState<GestaoPage> createState() => _GestaoPageState();
}

class _GestaoPageState extends ConsumerState<GestaoPage> {
  late PageController _pageController; // safely initialized in initState
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedId =
          ref.read(gestaoControllerProvider).categoriaSelecionadaId;
      final categorias = ref.read(gestaoControllerProvider).categorias;
      final initialPage = selectedId != null
          ? categorias.indexWhere((c) => c.id == selectedId)
          : 0;
      if (initialPage >= 0) {
        try {
          _pageController.jumpToPage(initialPage);
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _mostrarDialogoGerenciarPerfis(BuildContext context, WidgetRef ref) {
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
    final perfilInicial = ref.read(gestaoControllerProvider).perfilAtual;
    String? perfilSelecionado = perfilInicial;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final maxHeight = media.size.height * 0.86;
        return StatefulBuilder(
          builder: (context, setState) {
            final perfis = ref.watch(
                gestaoControllerProvider.select((s) => s.perfisSalvos));
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            return AnimatedPadding(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant.withOpacity(.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gerir Perfis',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _ActionCard(
                                label: 'Importar',
                                icon: Icons.file_download_outlined,
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  gestaoNotifier.importarPerfil();
                                },
                              ),
                              const SizedBox(width: 8),
                              _ActionCard(
                                label: 'Salvar',
                                icon: Icons.save_outlined,
                                onTap: () => _mostrarDialogoSalvarPerfil(
                                    sheetContext, ref),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ActionCard(
                                label: 'Exportar',
                                icon: Icons.file_upload_outlined,
                                isEnabled: perfilInicial != null,
                                onTap: () {
                                  if (perfilInicial == null) return;
                                  Navigator.of(sheetContext).pop();
                                  gestaoNotifier.exportarPerfil(perfilInicial);
                                },
                              ),
                              const SizedBox(width: 8),
                              _ActionCard(
                                label: 'Excluir',
                                icon: Icons.delete_outline,
                                isEnabled: perfilInicial != null,
                                onTap: () {
                                  if (perfilInicial == null) return;
                                  _mostrarDialogoConfirmarAcao(
                                    context: sheetContext,
                                    titulo: 'Excluir Perfil?',
                                    mensagem:
                                        'O perfil "$perfilInicial" será excluído permanentemente.',
                                    onConfirmar: () {
                                      gestaoNotifier.excluirPerfil(
                                          perfilInicial);
                                      setState(() {
                                        perfilSelecionado = null;
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: perfis.isEmpty
                            ? const Center(
                                child: Text('Nenhum perfil salvo.'),
                              )
                            : Scrollbar(
                                thumbVisibility: true,
                                child: ListView.builder(
                                  itemCount: perfis.length,
                                  itemBuilder: (context, index) {
                                    final nomePerfil = perfis[index];
                                    return RadioListTile<String>(
                                      title: Text(nomePerfil),
                                      value: nomePerfil,
                                      groupValue: perfilSelecionado,
                                      onChanged: (value) => setState(
                                          () => perfilSelecionado = value),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                if (perfilSelecionado != null &&
                                    perfilSelecionado != perfilInicial) {
                                  _mostrarDialogoConfirmarAcao(
                                    context: sheetContext,
                                    titulo: 'Carregar Perfil?',
                                    mensagem:
                                        'Isto substituirá todos os seus dados atuais com o perfil "$perfilSelecionado".',
                                    onConfirmar: () {
                                      Navigator.of(sheetContext).pop();
                                      gestaoNotifier.carregarPerfil(
                                          perfilSelecionado!);
                                    },
                                  );
                                } else {
                                  Navigator.of(sheetContext).pop();
                                }
                              },
                              child: const Text('OK'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoConfirmarAcao({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    required VoidCallback onConfirmar,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirmar();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoSalvarPerfil(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salvar Perfil Atual'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nome do Perfil'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(gestaoControllerProvider.notifier)
                  .salvarPerfilAtual(controller.text);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditarNome(
    BuildContext context,
    WidgetRef ref, {
    required String titulo,
    required String valorAtual,
    required Function(String) onSalvar,
  }) {
    final controller = TextEditingController(text: valorAtual);
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo, style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Novo nome"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar', style: textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () {
              final novoNome = controller.text;
              if (novoNome.isNotEmpty) {
                onSalvar(novoNome);
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text('Salvar', style: textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<GestaoState>(
      gestaoControllerProvider,
      (previousState, newState) {
        final toastController =
            ref.read(globalToastControllerProvider.notifier);

        if (newState.errorMessage != null &&
            newState.errorMessage != previousState?.errorMessage) {
          toastController.showError(newState.errorMessage!);
          ref.read(gestaoControllerProvider.notifier).clearError();
        }

        if (newState.ultimoProdutoDeletado != null &&
            newState.ultimoProdutoDeletado !=
                previousState?.ultimoProdutoDeletado) {
          final produtoDeletado = newState.ultimoProdutoDeletado!;
          toastController.show(
            '${produtoDeletado.nome} deletado',
            variant: ToastVariant.warning,
            action: ToastAction(
              label: 'Desfazer',
              onPressed: () {
                ref
                    .read(gestaoControllerProvider.notifier)
                    .desfazerDeletarProduto();
              },
            ),
          );
        }

        if (previousState?.categoriaSelecionadaId !=
            newState.categoriaSelecionadaId) {
          final newIndex = newState.categorias
              .indexWhere((c) => c.id == newState.categoriaSelecionadaId);
          if (newIndex != -1 &&
              _pageController.hasClients &&
              _pageController.page?.round() != newIndex) {
            _pageController.jumpToPage(newIndex);
          }
        }
      },
    );

    final gestaoState = ref.watch(gestaoControllerProvider);
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: colorScheme.surfaceContainerLow,
          drawer: Builder(
            builder: (context) {
              return _buildSidebarMenu(context, gestaoState, ref, gestaoNotifier);
            },
          ),
          onDrawerChanged: (isOpened) {
            // Handle drawer state if needed
          },
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: GestureDetector(
              onLongPress: () {
                HapticFeedback.heavyImpact();
                _mostrarDialogoGerenciarPerfis(context, ref);
              },
              child: Text('Precificador', style: textTheme.titleLarge),
            ),
            actions: [
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final textoRelatorio =
                        gestaoNotifier.gerarTextoRelatorio();
                    Share.share(textoRelatorio);
                  },
                  splashRadius: 26,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 2),
                child: IconButton(
                  icon: const Icon(Icons.add_box_outlined),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _mostrarDialogoNovaCategoria(context, ref);
                  },
                  splashRadius: 26,
                ),
              ),
            ],
          ),
          body: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Stack(
                children: [
                  if (gestaoState.categorias.isNotEmpty)
                    RepaintBoundary(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: gestaoState.categorias.length,
                        onPageChanged: (index) => gestaoNotifier
                            .selecionarCategoriaPorIndice(index),
                        itemBuilder: (context, index) => ProductListView(
                          categoriaId: gestaoState.categorias[index].id,
                          onProdutoDoubleTap: (produto) =>
                              _mostrarDialogoEditarNome(
                            context,
                            ref,
                            titulo: 'Editar Produto',
                            valorAtual: produto.nome,
                            onSalvar: (novoNome) => gestaoNotifier
                                .atualizarNomeProduto(produto.id, novoNome),
                          ),
                          onProdutoTap: (produto) => gestaoNotifier
                              .atualizarStatusProduto(
                                  produto.id, !produto.isAtivo),
                        ),
                      ),
                    ),
                  if (gestaoState.isReordering)
                    _buildDeleteArea(context, ref),
                  if (gestaoState.isDraggingProduto)
                    _buildProdutoDeleteArea(context, ref),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: CategoriaNavBar(
                onCategoriaDoubleTap: (categoria) {
                  _mostrarDialogoEditarNome(
                    context,
                    ref,
                    titulo: 'Editar Categoria',
                    valorAtual: categoria.nome,
                    onSalvar: (novoNome) => gestaoNotifier
                        .atualizarNomeCategoria(categoria.id, novoNome),
                  );
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add-product-fab',
            onPressed: gestaoState.categoriaSelecionadaId != null
                ? () {
                    HapticFeedback.lightImpact();
                    _mostrarDialogoNovoProduto(context, ref);
                  }
                : null,
            elevation: gestaoState.categoriaSelecionadaId != null ? 3.0 : 0.0,
            backgroundColor: gestaoState.categoriaSelecionadaId != null
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainer,
            child: Icon(
              Icons.add_shopping_cart,
              color: gestaoState.categoriaSelecionadaId != null
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.outline,
            ),
          ),
        ),
        _GlobalProcessingOverlay(active: gestaoState.isLoading),
      ],
    );
  }

  void _confirmarOrganizarComIA(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    _mostrarDialogoConfirmarAcao(
      context: context,
      titulo: 'Organizar com IA?',
      mensagem:
          'Tem certeza que deseja reorganizar seus produtos automaticamente?',
      onConfirmar: () {
        ref.read(gestaoControllerProvider.notifier).organizarComIA();
      },
    );
  }

  Widget _buildSidebarMenu(BuildContext context, GestaoState gestaoState,
      WidgetRef ref, GestaoController gestaoNotifier) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: NavigationDrawer(
        elevation: 0,
        backgroundColor: cs.surface,
        selectedIndex: null,
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          switch (index) {
            case 0:
              if (!gestaoState.isLoading) {
                _confirmarOrganizarComIA(context, ref);
              }
              break;
            case 1:
              _abrirConfiguracoes(context);
              break;
          }
        },
        children: [
          // App header - mais clean
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
            child: Text(
              'Precificador',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: cs.onSurface,
              ),
            ),
          ),
          // Navigation items
          NavigationDrawerDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: Text('Organizar com IA'),
            enabled: !gestaoState.isLoading,
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Configurações'),
          ),
          const SizedBox(height: 12),
          // Version footer - minimalista
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Text(
                  'v${snapshot.data!.version}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.outline,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _abrirConfiguracoes(BuildContext context) {
    // Placeholder: abrir uma tela futura de configurações
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações (em breve)')),
    );
  }

  Widget _buildProdutoDeleteArea(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: DragTarget<Produto>(
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isHovering ? 120 : 100,
            decoration: BoxDecoration(
              color: isHovering
                  ? colorScheme.errorContainer.withAlpha((255 * 0.9).round())
                  : colorScheme.errorContainer.withAlpha((255 * 0.7).round()),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(60)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline,
                    color: colorScheme.onErrorContainer, size: 32),
                const SizedBox(height: 8),
                Text('Arraste o produto aqui para apagar',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onErrorContainer)),
              ],
            ),
          );
        },
        onAcceptWithDetails: (details) {
          HapticFeedback.lightImpact();
          ref
              .read(gestaoControllerProvider.notifier)
              .deletarProduto(details.data.id);
          ref.read(gestaoControllerProvider.notifier).setDraggingProduto(false);
        },
      ),
    );
  }

  Widget _buildDeleteArea(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: DragTarget<String>(
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isHovering ? 120 : 100,
            decoration: BoxDecoration(
              color: isHovering
                  ? colorScheme.errorContainer.withAlpha((255 * 0.9).round())
                  : colorScheme.errorContainer.withAlpha((255 * 0.7).round()),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(60)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline,
                    color: colorScheme.onErrorContainer, size: 32),
                const SizedBox(height: 8),
                Text('Arraste aqui para apagar',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onErrorContainer)),
              ],
            ),
          );
        },
        onAcceptWithDetails: (details) {
          HapticFeedback.lightImpact();
          final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
          gestaoNotifier.deletarCategoria(details.data);
          gestaoNotifier.setReordering(false);
        },
      ),
    );
  }

  void _mostrarDialogoNovoProduto(BuildContext pageContext, WidgetRef ref) {
    final controller = TextEditingController();
    final textTheme = Theme.of(pageContext).textTheme;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Novo Produto', style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nome do produto"),
          autofocus: true,
          onSubmitted: (_) =>
              _salvarNovoProduto(dialogContext, controller, ref),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar', style: textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () => _salvarNovoProduto(dialogContext, controller, ref),
            child: Text('Salvar', style: textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  void _salvarNovoProduto(BuildContext dialogContext,
      TextEditingController controller, WidgetRef ref) {
    HapticFeedback.lightImpact();
    final nomeProduto = controller.text;
    if (nomeProduto.isNotEmpty) {
      ref.read(gestaoControllerProvider.notifier).criarProduto(nomeProduto);
      Navigator.of(dialogContext).pop();
    }
  }

  void _mostrarDialogoNovaCategoria(BuildContext pageContext, WidgetRef ref) {
    final controller = TextEditingController();
    final textTheme = Theme.of(pageContext).textTheme;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Nova Categoria', style: textTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nome da categoria"),
          autofocus: true,
          onSubmitted: (_) =>
              _salvarNovaCategoria(dialogContext, controller, ref),
        ),
        actions: [
          TextButton(
            child: Text('Cancelar', style: textTheme.labelLarge),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text('Salvar', style: textTheme.labelLarge),
            onPressed: () =>
                _salvarNovaCategoria(dialogContext, controller, ref),
          ),
        ],
      ),
    );
  }

  void _salvarNovaCategoria(BuildContext dialogContext,
      TextEditingController controller, WidgetRef ref) {
    HapticFeedback.lightImpact();
    final nomeCategoria = controller.text;
    if (nomeCategoria.isNotEmpty) {
      ref.read(gestaoControllerProvider.notifier).criarCategoria(nomeCategoria);
      Navigator.of(dialogContext).pop();
    }
  }
}

class _GlobalProcessingOverlay extends StatefulWidget {
  final bool active;

  const _GlobalProcessingOverlay({required this.active});

  @override
  State<_GlobalProcessingOverlay> createState() =>
      _GlobalProcessingOverlayState();
}

class _GlobalProcessingOverlayState extends State<_GlobalProcessingOverlay>
    with TickerProviderStateMixin {
  static const _messages = [
    'Organizando os itens para você...',
    'Analisando categorias e agrupamentos...',
    'Separando os itens com carinho...',
    'Quase pronto! Ajustando os últimos detalhes...'
  ];

  late Timer _timer;
  int _currentMessageIndex = 0;
  late AnimationController _glowController;
  late AnimationController _visibilityController; // 0..1 para entrada/saída

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
      });
    });
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 260),
    );
    if (widget.active) {
      _visibilityController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _glowController.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GlobalProcessingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _visibilityController,
        builder: (context, _) {
          final v = Curves.easeInOut.transform(_visibilityController.value);
          if (v == 0) return const SizedBox.shrink();
          return IgnorePointer(
            ignoring: v < 0.05,
            child: Opacity(
              opacity: v,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 18 * v,
                          sigmaY: 18 * v,
                        ),
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _GlowBackdropPainter(
                                progress: _glowController.value,
                                colorScheme: colorScheme,
                              ),
                              child: Container(
                                color: Colors.black.withOpacity(0.02 * v),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: _visibilityController,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                    opacity: animation, child: child),
                            child: Opacity(
                              key: ValueKey('${_currentMessageIndex}_$v'),
                              opacity: v.clamp(0, 1),
                              child: Text(
                                _messages[_currentMessageIndex],
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.15,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.25 * v),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Opacity(
                            opacity: (v * 0.95).clamp(0, 1),
                            child: Text(
                              'Nossa IA está cuidando de tudo, só um instante.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.9 * v),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2 * v),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlowBackdropPainter extends CustomPainter {
  final double progress; // 0..1 loop
  final ColorScheme colorScheme;

  _GlowBackdropPainter({required this.progress, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    // Three moving glow blobs (radial gradients) whose centers animate softly
    final paints = <_GlowSpec>[
      _GlowSpec(
        baseOffset: const Offset(0.18, 0.22),
        radiusFactor: 0.65,
        // maior
        hueShift: 0.0,
        speed: 0.9,
        intensity: 0.38, // mais leve
      ),
      _GlowSpec(
        baseOffset: const Offset(0.88, 0.78),
        radiusFactor: 0.80,
        hueShift: 0.07,
        speed: 0.55,
        intensity: 0.30,
      ),
      _GlowSpec(
        baseOffset: const Offset(0.78, 0.20),
        radiusFactor: 0.55,
        hueShift: -0.05,
        speed: 1.25,
        intensity: 0.25,
      ),
    ];

    for (final spec in paints) {
      final localT = (progress * spec.speed) % 1.0;
      final wobbleX = math.sin(localT * math.pi * 2) * 0.04;
      final wobbleY = math.cos(localT * math.pi * 2) * 0.04;
      final center = Offset(
        (spec.baseOffset.dx + wobbleX) * size.width,
        (spec.baseOffset.dy + wobbleY) * size.height,
      );
      final radius = spec.radiusFactor * size.shortestSide;
      final gradient = RadialGradient(
        colors: [
          _tint(colorScheme.primary, spec.hueShift)
              .withOpacity(spec.intensity * 0.50),
          _tint(colorScheme.primaryContainer, spec.hueShift)
              .withOpacity(spec.intensity * 0.22),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      );
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }
  }

  Color _tint(Color base, double shift) {
    // Simple hue shift approximation by mixing with complementary/white
    if (shift == 0) return base;
    final hsl = HSLColor.fromColor(base);
    final shifted = hsl.withHue((hsl.hue + shift * 360) % 360);
    return shifted.toColor();
  }

  @override
  bool shouldRepaint(covariant _GlowBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colorScheme != colorScheme;
}

class _GlowSpec {
  final Offset baseOffset; // relative 0..1
  final double radiusFactor; // relative to shortestSide
  final double hueShift; // -1..1 -> fraction of 360 degrees
  final double speed; // multiplier for animation speed
  final double intensity; // base opacity scaler
  _GlowSpec({
    required this.baseOffset,
    required this.radiusFactor,
    required this.hueShift,
    required this.speed,
    required this.intensity,
  });
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEnabled
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : Theme.of(context).colorScheme.outline;

    return Expanded(
      child: Card(
        elevation: isEnabled ? 1 : 0,
        color: isEnabled
            ? null
            : Theme.of(context)
                .colorScheme
                .surface
                .withAlpha((255 * 0.5).round()),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Navigation Drawer using Material You 3 native components

