import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:precifica/domain/entities/produto.dart';

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
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final selectedId =
            ref.read(gestaoControllerProvider).categoriaSelecionadaId;
        final categorias = ref.read(gestaoControllerProvider).categorias;
        final initialPage = selectedId != null
            ? categorias.indexWhere((c) => c.id == selectedId)
            : 0;
        _pageController =
            PageController(initialPage: initialPage > -1 ? initialPage : 0);
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

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, child) {
                final perfis = ref.watch(
                    gestaoControllerProvider.select((s) => s.perfisSalvos));

                final isProfileSelected = perfilSelecionado != null;

                return AlertDialog(
                  title: const Text('Gerir Perfis'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _ActionCard(
                              label: 'Importar',
                              icon: Icons.file_download_outlined,
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                gestaoNotifier.importarPerfil();
                              },
                            ),
                            const SizedBox(width: 8),
                            _ActionCard(
                              label: 'Salvar Atual',
                              icon: Icons.save_outlined,
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                _mostrarDialogoSalvarPerfil(context, ref);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _ActionCard(
                              label: 'Exportar',
                              icon: Icons.file_upload_outlined,
                              isEnabled: isProfileSelected,
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                gestaoNotifier
                                    .exportarPerfil(perfilSelecionado!);
                              },
                            ),
                            const SizedBox(width: 8),
                            _ActionCard(
                              label: 'Excluir',
                              icon: Icons.delete_outline,
                              isEnabled: isProfileSelected,
                              onTap: () {
                                _mostrarDialogoConfirmarAcao(
                                  context: context,
                                  titulo: 'Excluir Perfil?',
                                  mensagem:
                                      'O perfil "$perfilSelecionado" será excluído permanentemente.',
                                  onConfirmar: () {
                                    gestaoNotifier
                                        .excluirPerfil(perfilSelecionado!);
                                    setState(() {
                                      perfilSelecionado = null;
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (perfis.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(child: Text('Nenhum perfil salvo.')),
                          ),
                        if (perfis.isNotEmpty)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: perfis.length,
                              itemBuilder: (context, index) {
                                final String nomePerfil = perfis[index];
                                return RadioListTile<String>(
                                  title: Text(nomePerfil),
                                  value: nomePerfil,
                                  groupValue: perfilSelecionado,
                                  onChanged: (String? value) {
                                    setState(() {
                                      perfilSelecionado = value;
                                    });
                                  },
                                );
                              },
                            ),
                          )
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (perfilSelecionado != null &&
                            perfilSelecionado != perfilInicial) {
                          _mostrarDialogoConfirmarAcao(
                            context: context,
                            titulo: 'Carregar Perfil?',
                            mensagem:
                                'Isto substituirá todos os seus dados atuais com o perfil "$perfilSelecionado".',
                            onConfirmar: () {
                              Navigator.of(dialogContext).pop();
                              gestaoNotifier.carregarPerfil(perfilSelecionado!);
                            },
                          );
                        } else {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _mostrarSheetImpressoras(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gestaoControllerProvider.notifier);

    notifier.buscarImpressoras();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const _PrinterBottomSheet(),
    ).whenComplete(() {
      notifier.pararBuscaImpressoras();
      notifier.limparMensagemImpressora();
    });
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
        if (newState.errorMessage != null &&
            newState.errorMessage != previousState?.errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newState.errorMessage!),
              backgroundColor: colorScheme.errorContainer,
            ),
          );
          ref.read(gestaoControllerProvider.notifier).clearError();
        }

        if (newState.ultimoProdutoDeletado != null &&
            newState.ultimoProdutoDeletado !=
                previousState?.ultimoProdutoDeletado) {
          final produtoDeletado = newState.ultimoProdutoDeletado!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${produtoDeletado.nome} deletado'),
            action: SnackBarAction(
              label: 'DESFAZER',
              onPressed: () {
                ref
                    .read(gestaoControllerProvider.notifier)
                    .desfazerDeletarProduto();
              },
            ),
          ));
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            _mostrarDialogoGerenciarPerfis(context, ref);
          },
          child: Text('Precificador', style: textTheme.titleLarge),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              HapticFeedback.lightImpact();
              _mostrarSheetImpressoras(context, ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              HapticFeedback.lightImpact();
              final textoRelatorio = gestaoNotifier.gerarTextoRelatorio();
              Share.share(textoRelatorio);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              HapticFeedback.lightImpact();
              _mostrarDialogoNovaCategoria(context, ref);
            },
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
                    onPageChanged: (index) {
                      gestaoNotifier.selecionarCategoriaPorIndice(index);
                    },
                    itemBuilder: (context, index) {
                      return ProductListView(
                        categoriaId: gestaoState.categorias[index].id,
                        onProdutoDoubleTap: (produto) {
                          _mostrarDialogoEditarNome(
                            context,
                            ref,
                            titulo: "Editar Produto",
                            valorAtual: produto.nome,
                            onSalvar: (novoNome) {
                              gestaoNotifier.atualizarNomeProduto(
                                  produto.id, novoNome);
                            },
                          );
                        },
                        onProdutoTap: (produto) {
                          gestaoNotifier.atualizarStatusProduto(
                              produto.id, !produto.isAtivo);
                        },
                      );
                    },
                  ),
                ),
              if (gestaoState.isReordering) _buildDeleteArea(context, ref),
              if (gestaoState.isDraggingProduto)
                _buildProdutoDeleteArea(context, ref),
              if (gestaoState.isLoading)
                Container(
                  color: Colors.black.withAlpha((255 * 0.3).round()),
                  child: const Center(child: CircularProgressIndicator()),
                ),
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
                titulo: "Editar Categoria",
                valorAtual: categoria.nome,
                onSalvar: (novoNome) {
                  gestaoNotifier.atualizarNomeCategoria(categoria.id, novoNome);
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: gestaoState.categoriaSelecionadaId != null
            ? () {
                HapticFeedback.lightImpact();
                _mostrarDialogoNovoProduto(context, ref);
              }
            : null,
        elevation: gestaoState.categoriaSelecionadaId != null ? 6.0 : 0.0,
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

class _PrinterBottomSheet extends ConsumerWidget {
  const _PrinterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gestaoControllerProvider);
    final notifier = ref.read(gestaoControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Impressoras Bluetooth',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Buscar novamente',
                icon: state.isBuscandoImpressoras
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: state.isBuscandoImpressoras
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        notifier.buscarImpressoras();
                      },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.mensagemImpressora != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.mensagemImpressora!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      notifier.limparMensagemImpressora();
                    },
                  ),
                ],
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: Builder(
              builder: (_) {
                if (state.impressorasDisponiveis.isEmpty) {
                  if (state.isBuscandoImpressoras) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Nenhuma impressora encontrada.\nCertifique-se de que ela esteja ligada e próxima.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.impressorasDisponiveis.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = state.impressorasDisponiveis[index];
                    final isSameDevice =
                        state.impressoraConectada?.id == device.id;
                    final isConnected = isSameDevice &&
                        !state.isConectandoImpressora &&
                        state.impressoraConectada != null;
                    final isConnecting =
                        isSameDevice && state.isConectandoImpressora;

                    return ListTile(
                      leading: Icon(
                        isConnected ? Icons.print : Icons.print_outlined,
                        color: isConnected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      title:
                          Text(device.name, style: theme.textTheme.bodyLarge),
                      subtitle: Text(device.address,
                          style: theme.textTheme.bodySmall),
                      trailing: isConnected
                          ? TextButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                notifier.desconectarImpressora();
                              },
                              icon: const Icon(Icons.link_off),
                              label: const Text('Desconectar'),
                            )
                          : TextButton.icon(
                              onPressed: state.isConectandoImpressora
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      notifier.conectarImpressora(device);
                                    },
                              icon: isConnecting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.link),
                              label: Text(
                                  isConnecting ? 'Conectando...' : 'Conectar'),
                            ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.impressoraConectada != null && !state.isImprimindo
                ? () {
                    HapticFeedback.lightImpact();
                    notifier.imprimirRelatorioAtual();
                  }
                : null,
            icon: state.isImprimindo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: Text(
              state.isImprimindo ? 'Imprimindo...' : 'Imprimir tabela',
            ),
          ),
          if (state.impressoraConectada != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Conectado a ${state.impressoraConectada!.name}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
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
