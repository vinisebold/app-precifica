import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/report_template.dart';
import '../../domain/services/report_generator_service.dart';
import '../../domain/services/sample_data_service.dart';
import 'settings_controller.dart';
import 'widgets/whatsapp_formatted_text.dart';
import '../../app/core/snackbar/app_snackbar.dart';

class ReportSettingsPage extends ConsumerStatefulWidget {
  final String? templateId;

  const ReportSettingsPage({super.key, this.templateId});

  @override
  ConsumerState<ReportSettingsPage> createState() => _ReportSettingsPageState();
}

class _ReportSettingsPageState extends ConsumerState<ReportSettingsPage> {
  final _nomeController = TextEditingController();
  final _tituloController = TextEditingController();
  final _rodapeController = TextEditingController();
  final _emojiController = TextEditingController();
  final _textoPrecoZeroController = TextEditingController();
  final _reportGenerator = ReportGeneratorService();
  bool _sampleDataLoaded = false;
  
  // Controle de redimensionamento
  double _topFlex = 0.5; // 50% para cada área inicialmente
  double _dragStartPosition = 0;
  double _dragStartFlex = 0;

  // Template original para comparação
  ReportTemplate? _templateOriginal;
  
  // Flag para indicar que o template foi excluído
  bool _templateExcluido = false;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.templateId != null) {
        _carregarTemplate();
      } else {
        ref.read(settingsControllerProvider.notifier).iniciarEdicao(null);
        // Salvar o template original para comparação
        final template = ref.read(settingsControllerProvider).templateEmEdicao;
        _templateOriginal = template;
      }
    });
  }

  Future<void> _loadSampleData() async {
    await SampleDataService.loadSampleData();
    if (mounted) {
      setState(() {
        _sampleDataLoaded = true;
      });
    }
  }

  Future<void> _carregarTemplate() async {
    final controller = ref.read(settingsControllerProvider.notifier);
    final template = await controller.obterTemplate(widget.templateId!);
    if (template != null) {
      controller.iniciarEdicao(template);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _tituloController.dispose();
    _rodapeController.dispose();
    _emojiController.dispose();
    _textoPrecoZeroController.dispose();
    super.dispose();
  }

  void _atualizarControllers(ReportTemplate template) {
    if (_nomeController.text != template.nome) {
      _nomeController.text = template.nome;
    }
    if (_tituloController.text != template.titulo) {
      _tituloController.text = template.titulo;
    }
    if (_rodapeController.text != template.mensagemRodape) {
      _rodapeController.text = template.mensagemRodape;
    }
    if (_emojiController.text != template.emojiCategoria) {
      _emojiController.text = template.emojiCategoria;
    }
    if (_textoPrecoZeroController.text != template.textoPrecoZero) {
      _textoPrecoZeroController.text = template.textoPrecoZero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsControllerProvider);
    final template = settingsState.templateEmEdicao;
    final colorScheme = Theme.of(context).colorScheme;

    if (template == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Personalizar'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _atualizarControllers(template);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_templateExcluido) {
          // Só salva se houver mudanças ou se for um template existente
          if (_templateFoiModificado(template)) {
            ref.read(settingsControllerProvider.notifier).salvarTemplate();
          } else {
            // Se não houve modificações, cancela a edição (não salva)
            ref.read(settingsControllerProvider.notifier).cancelarEdicao();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personalizar'),
          actions: [
            if (!template.isPadrao)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'rename') {
                    _showRenameDialog(context, template);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, template);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 12),
                        Text('Renomear'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 8),
          ],
        ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Painel de configurações (metade superior)
              Expanded(
                flex: (_topFlex * 100).round(),
                child: _buildConfigPanel(context, template),
              ),
              
              // Divisor arrastável
              GestureDetector(
                onVerticalDragStart: (details) {
                  _dragStartPosition = details.globalPosition.dy;
                  _dragStartFlex = _topFlex;
                },
                onVerticalDragUpdate: (details) {
                  setState(() {
                    final delta = details.globalPosition.dy - _dragStartPosition;
                    final deltaFlex = delta / constraints.maxHeight;
                    _topFlex = (_dragStartFlex + deltaFlex).clamp(0.2, 0.8);
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Pré-visualização (metade inferior)
              Expanded(
                flex: ((1 - _topFlex) * 100).round(),
                child: _buildPreview(context, template),
              ),
            ],
          );
        },
      ),
    ),
    );
  }

  Widget _buildConfigPanel(BuildContext context, ReportTemplate template) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Nome do modelo
          TextField(
            controller: _nomeController,
            decoration: InputDecoration(
              labelText: 'Nome do Modelo',
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
            onChanged: (value) {
              _atualizarTemplate(template.copyWith(nome: value));
            },
          ),
          const SizedBox(height: 32),

          // Seção: Cabeçalho
          _buildSectionHeader(context, 'Cabeçalho'),
          const SizedBox(height: 16),
          
          TextField(
            controller: _tituloController,
            decoration: InputDecoration(
              labelText: 'Título do Relatório',
              hintText: 'Ex: Preços, Ofertas da Semana',
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
            onChanged: (value) {
              _atualizarTemplate(template.copyWith(titulo: value));
            },
          ),
          const SizedBox(height: 12),

          _buildSwitchTile(
            context,
            title: 'Mostrar Dia da Semana',
            value: template.mostrarDiaSemana,
            onChanged: (value) {
              _atualizarTemplate(template.copyWith(mostrarDiaSemana: value));
            },
          ),

          _buildSwitchTile(
            context,
            title: 'Mostrar Data',
            value: template.mostrarData,
            onChanged: (value) {
              _atualizarTemplate(template.copyWith(mostrarData: value));
            },
          ),
          const SizedBox(height: 32),

          // Seção: Categorias
          _buildSectionHeader(context, 'Categorias'),
          const SizedBox(height: 16),

          _buildSwitchTile(
            context,
            title: 'Agrupar por Categoria',
            value: template.agruparPorCategoria,
            onChanged: (value) {
              _atualizarTemplate(template.copyWith(agruparPorCategoria: value));
            },
          ),

          if (template.agruparPorCategoria) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<CategoryFormatting>(
              initialValue: template.formatoCategoria,
              decoration: InputDecoration(
                labelText: 'Formato do Nome',
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
              items: const [
                DropdownMenuItem(
                  value: CategoryFormatting.normal,
                  child: Text('Normal'),
                ),
                DropdownMenuItem(
                  value: CategoryFormatting.uppercase,
                  child: Text('MAIÚSCULAS'),
                ),
                DropdownMenuItem(
                  value: CategoryFormatting.bold,
                  child: Text('Negrito'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _atualizarTemplate(template.copyWith(formatoCategoria: value));
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emojiController,
              decoration: InputDecoration(
                labelText: 'Emoji da Categoria',
                hintText: 'Ex: ⬇️, 🔽, ou deixe vazio',
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
              onChanged: (value) {
                _atualizarTemplate(template.copyWith(emojiCategoria: value));
              },
            ),
          ],
          const SizedBox(height: 32),

          // Seção: Produtos
          _buildSectionHeader(context, 'Produtos'),
          const SizedBox(height: 16),

          DropdownButtonFormField<ProductFilter>(
            initialValue: template.filtroProdutos,
            decoration: InputDecoration(
              labelText: 'Produtos a Incluir',
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
            items: const [
              DropdownMenuItem(
                value: ProductFilter.activeWithPrice,
                child: Text('Apenas ativos com preço'),
              ),
              DropdownMenuItem(
                value: ProductFilter.allActive,
                child: Text('Todos os ativos'),
              ),
              DropdownMenuItem(
                value: ProductFilter.all,
                child: Text('Todos (incluindo inativos)'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _atualizarTemplate(template.copyWith(filtroProdutos: value));
              }
            },
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<ProductNameFormatting>(
            initialValue: template.formatoNomeProduto,
            decoration: InputDecoration(
              labelText: 'Formato do Nome do Produto',
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
            items: const [
              DropdownMenuItem(
                value: ProductNameFormatting.firstWordBold,
                child: Text('Primeira palavra em negrito'),
              ),
              DropdownMenuItem(
                value: ProductNameFormatting.fullBold,
                child: Text('Nome completo em negrito'),
              ),
              DropdownMenuItem(
                value: ProductNameFormatting.normal,
                child: Text('Sem formatação'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _atualizarTemplate(template.copyWith(formatoNomeProduto: value));
              }
            },
          ),
          const SizedBox(height: 12),

          _buildSwitchTile(
            context,
            title: 'Ocultar Preços',
            subtitle: 'Útil para listas de conferência',
            value: template.ocultarPrecos,
            onChanged: (value) {
              _atualizarTemplate(template.copyWith(ocultarPrecos: value));
            },
          ),

          if (!template.ocultarPrecos) ...[
            const SizedBox(height: 12),
            _buildSwitchTile(
              context,
              title: 'Mostrar "R\$" nos Preços',
              subtitle: 'Se desabilitado, mostra apenas os valores numéricos',
              value: template.mostrarCifraoPreco,
              onChanged: (value) {
                _atualizarTemplate(template.copyWith(mostrarCifraoPreco: value));
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textoPrecoZeroController,
              decoration: InputDecoration(
                labelText: 'Texto para Preço Zerado',
                hintText: 'Ex: Consulte, A combinar',
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
              onChanged: (value) {
                _atualizarTemplate(template.copyWith(textoPrecoZero: value));
              },
            ),
          ],
          const SizedBox(height: 32),

          // Seção: Rodapé
          _buildSectionHeader(context, 'Rodapé'),
          const SizedBox(height: 16),

          TextField(
            controller: _rodapeController,
            decoration: InputDecoration(
              labelText: 'Mensagem de Rodapé',
              hintText: 'Ex: Peça já! (47) 99999-9999',
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
            maxLines: 3,
            onChanged: (value) {
              _atualizarTemplate(template.copyWith(mensagemRodape: value));
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, ReportTemplate template) {
    final colorScheme = Theme.of(context).colorScheme;

    String previewText;
    if (!_sampleDataLoaded) {
      previewText = 'Carregando dados de exemplo...';
    } else {
      final categorias = SampleDataService.getCategoriasSample(limit: 2);
      final produtos = SampleDataService.getProdutosSample(
        categoriaLimit: 2,
        produtoLimit: 4,
      );

      previewText = _reportGenerator.gerarRelatorio(
        template: template,
        categorias: categorias,
        todosProdutos: produtos,
      );
    }

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            color: colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Pré-visualização',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          
          // Conteúdo
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: !_sampleDataLoaded
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Carregando exemplo...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: WhatsAppFormattedText(
                        text: previewText,
                        fontSize: 14,
                        lineHeight: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ReportTemplate template) {
    final renameController = TextEditingController(text: template.nome);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear Modelo'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(
            labelText: 'Nome do Modelo',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (renameController.text.trim().isNotEmpty) {
                _nomeController.text = renameController.text.trim();
                _atualizarTemplate(template.copyWith(nome: renameController.text.trim()));
                Navigator.pop(context);
                AppSnackbar.showSuccess(
                  context,
                  'Modelo renomeado com sucesso',
                );
              }
            },
            child: const Text('Renomear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ReportTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        content: Padding(
          padding: const EdgeInsets.only(right: 40),
          child: Text(
            'Excluir modelo "${template.nome}"?',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              
              try {
                // Primeiro fecha o diálogo
                navigator.pop();
                
                // Depois deleta o template
                await ref
                    .read(settingsControllerProvider.notifier)
                    .deletarTemplate(template.id);
                
                // Marca que o template foi excluído para evitar salvar novamente no PopScope
                _templateExcluido = true;
                
                // Volta para a lista de modelos
                navigator.pop();
                
                if (!context.mounted) return;
                
                AppSnackbar.show(
                  context,
                  'Modelo "${template.nome}" excluído',
                );
              } catch (e) {
                if (!context.mounted) return;
                
                AppSnackbar.showError(
                  context,
                  'Erro ao excluir: $e',
                );
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  bool _templateFoiModificado(ReportTemplate templateAtual) {
    // Se é um template existente (tem templateId), sempre salva
    if (widget.templateId != null) {
      return true;
    }

    // Se é um novo template, verifica se foi modificado em relação ao original
    if (_templateOriginal == null) {
      return true; // Se não tem original, salva por segurança
    }

    // Compara as propriedades relevantes
    return templateAtual.nome != _templateOriginal!.nome ||
        templateAtual.titulo != _templateOriginal!.titulo ||
        templateAtual.mostrarData != _templateOriginal!.mostrarData ||
        templateAtual.mostrarDiaSemana != _templateOriginal!.mostrarDiaSemana ||
        templateAtual.mensagemRodape != _templateOriginal!.mensagemRodape ||
        templateAtual.agruparPorCategoria != _templateOriginal!.agruparPorCategoria ||
        templateAtual.formatoCategoria != _templateOriginal!.formatoCategoria ||
        templateAtual.emojiCategoria != _templateOriginal!.emojiCategoria ||
        templateAtual.filtroProdutos != _templateOriginal!.filtroProdutos ||
        templateAtual.formatoNomeProduto != _templateOriginal!.formatoNomeProduto ||
        templateAtual.ocultarPrecos != _templateOriginal!.ocultarPrecos ||
        templateAtual.textoPrecoZero != _templateOriginal!.textoPrecoZero ||
        templateAtual.mostrarCifraoPreco != _templateOriginal!.mostrarCifraoPreco;
  }

  void _atualizarTemplate(ReportTemplate template) {
    ref.read(settingsControllerProvider.notifier).atualizarTemplateEmEdicao(template);
  }
}
