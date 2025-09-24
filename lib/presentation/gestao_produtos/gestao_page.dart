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

  // O diálogo principal para gerir perfis
  void _mostrarDialogoGerenciarPerfis(BuildContext context, WidgetRef ref) {
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, child) {
            final perfis = ref
                .watch(gestaoControllerProvider.select((s) => s.perfisSalvos));
            final perfilAtual = ref
                .watch(gestaoControllerProvider.select((s) => s.perfilAtual));

            return AlertDialog(
              title: const Text('Gerir Perfis'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Garante altura mínima
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Perfil Carregado: ${perfilAtual ?? "Nenhum (dados não salvos)"}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const Divider(),
                    if (perfis.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: Text('Nenhum perfil salvo.')),
                      ),
                    if (perfis.isNotEmpty)
                      SizedBox(
                        // Define uma altura máxima para a lista
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: perfis.length,
                          itemBuilder: (context, index) {
                            final nomePerfil = perfis[index];
                            return ListTile(
                              title: Text(nomePerfil),
                              onTap: () {
                                _mostrarDialogoConfirmarAcao(
                                  context: context,
                                  titulo: 'Carregar Perfil?',
                                  mensagem:
                                      'Isto substituirá todos os seus dados atuais. Esta ação não pode ser desfeita.',
                                  onConfirmar: () {
                                    Navigator.of(dialogContext)
                                        .pop(); // Fecha o modal de perfis
                                    gestaoNotifier.carregarPerfil(nomePerfil);
                                  },
                                );
                              },
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                      value: 'export', child: Text('Exportar')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Excluir')),
                                ],
                                onSelected: (value) {
                                  if (value == 'export') {
                                    gestaoNotifier.exportarPerfil(nomePerfil);
                                  } else if (value == 'delete') {
                                    _mostrarDialogoConfirmarAcao(
                                      context: context,
                                      titulo: 'Excluir Perfil?',
                                      mensagem:
                                          'O perfil "$nomePerfil" será excluído permanentemente.',
                                      onConfirmar: () {
                                        gestaoNotifier
                                            .excluirPerfil(nomePerfil);
                                      },
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _mostrarDialogoSalvarPerfil(context, ref);
                  },
                  child: const Text('SALVAR ATUAL'),
                ),
                TextButton(
                  onPressed: () {
                    gestaoNotifier.importarPerfil();
                  },
                  child: const Text('IMPORTAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Diálogo de confirmação genérico para ações destrutivas
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
              // A PageView agora só é construída se houver categorias
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
              // A tela de carregamento cobre tudo
              if (gestaoState.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
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
                  ? colorScheme.errorContainer.withValues(alpha: 0.9)
                  : colorScheme.errorContainer.withValues(alpha: 0.7),
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
                  ? colorScheme.errorContainer.withValues(alpha: 0.9)
                  : colorScheme.errorContainer.withValues(alpha: 0.7),
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
