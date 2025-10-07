import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/report_template.dart';
import '../../domain/services/report_generator_service.dart';
import '../../domain/services/sample_data_service.dart';
import 'settings_controller.dart';
import 'widgets/whatsapp_formatted_text.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSampleData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.templateId != null) {
        _carregarTemplate();
      } else {
        ref.read(settingsControllerProvider.notifier).iniciarEdicao(null);
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
        appBar: AppBar(title: const Text('Personalizar Relatório')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _atualizarControllers(template);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar Relatório'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              ref.read(settingsControllerProvider.notifier).salvarTemplate();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Painel de configurações (metade superior)
              SizedBox(
                height: constraints.maxHeight * _topFlex,
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
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Pré-visualização (metade inferior)
              SizedBox(
                height: constraints.maxHeight * (1 - _topFlex) - 12,
                child: _buildPreview(context, template),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfigPanel(BuildContext context, ReportTemplate template) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Nome do modelo
        TextField(
          controller: _nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome do Modelo',
          ),
          onChanged: (value) {
            _atualizarTemplate(template.copyWith(nome: value));
          },
        ),
        const SizedBox(height: 24),

        // Seção: Cabeçalho
        Text('CABEÇALHO', style: Theme.of(context).textTheme.titleSmall),
        const Divider(),
        const SizedBox(height: 8),
        
        TextField(
          controller: _tituloController,
          decoration: const InputDecoration(
            labelText: 'Título do Relatório',
            hintText: 'Ex: Preços, Ofertas da Semana',
          ),
          onChanged: (value) {
            _atualizarTemplate(template.copyWith(titulo: value));
          },
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          title: const Text('Mostrar Dia da Semana'),
          value: template.mostrarDiaSemana,
          onChanged: (value) {
            _atualizarTemplate(template.copyWith(mostrarDiaSemana: value));
          },
        ),

        SwitchListTile(
          title: const Text('Mostrar Data'),
          value: template.mostrarData,
          onChanged: (value) {
            _atualizarTemplate(template.copyWith(mostrarData: value));
          },
        ),
        const SizedBox(height: 24),

        // Seção: Categorias
        Text('CATEGORIAS', style: Theme.of(context).textTheme.titleSmall),
        const Divider(),
        const SizedBox(height: 8),

        SwitchListTile(
          title: const Text('Agrupar por Categoria'),
          value: template.agruparPorCategoria,
          onChanged: (value) {
            _atualizarTemplate(template.copyWith(agruparPorCategoria: value));
          },
        ),

        if (template.agruparPorCategoria) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<CategoryFormatting>(
            value: template.formatoCategoria,
            decoration: const InputDecoration(
              labelText: 'Formato do Nome',
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
            decoration: const InputDecoration(
              labelText: 'Emoji da Categoria',
              hintText: 'Ex: ⬇️, 🔽, ou deixe vazio',
            ),
            onChanged: (value) {
              _atualizarTemplate(template.copyWith(emojiCategoria: value));
            },
          ),
        ],
        const SizedBox(height: 24),

        // Seção: Produtos
        Text('PRODUTOS', style: Theme.of(context).textTheme.titleSmall),
        const Divider(),
        const SizedBox(height: 8),

        DropdownButtonFormField<ProductFilter>(
          value: template.filtroProdutos,
          decoration: const InputDecoration(
            labelText: 'Produtos a Incluir',
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
          value: template.formatoNomeProduto,
          decoration: const InputDecoration(
            labelText: 'Formato do Nome do Produto',
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

        SwitchListTile(
          title: const Text('Ocultar Preços'),
          subtitle: const Text('Útil para listas de conferência'),
          value: template.ocultarPrecos,
          onChanged: (value) {
            _atualizarTemplate(template.copyWith(ocultarPrecos: value));
          },
        ),

        if (!template.ocultarPrecos) ...[
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Mostrar "R\$" nos Preços'),
            subtitle: const Text('Se desabilitado, mostra apenas os valores numéricos'),
            value: template.mostrarCifraoPreco,
            onChanged: (value) {
              _atualizarTemplate(template.copyWith(mostrarCifraoPreco: value));
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textoPrecoZeroController,
            decoration: const InputDecoration(
              labelText: 'Texto para Preço Zerado',
              hintText: 'Ex: Consulte, A combinar',
            ),
            onChanged: (value) {
              _atualizarTemplate(template.copyWith(textoPrecoZero: value));
            },
          ),
        ],
        const SizedBox(height: 24),

        // Seção: Rodapé
        Text('RODAPÉ', style: Theme.of(context).textTheme.titleSmall),
        const Divider(),
        const SizedBox(height: 8),

        TextField(
          controller: _rodapeController,
          decoration: const InputDecoration(
            labelText: 'Mensagem de Rodapé',
            hintText: 'Ex: Peça já! (47) 99999-9999',
          ),
          maxLines: 3,
          onChanged: (value) {
            _atualizarTemplate(template.copyWith(mensagemRodape: value));
          },
        ),
      ],
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

    return Material(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com mesma cor do divisor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
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
          
          // Conteúdo com Card Material 3
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 0,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
            ),
          ),
        ],
      ),
    );
  }

  void _atualizarTemplate(ReportTemplate template) {
    ref.read(settingsControllerProvider.notifier).atualizarTemplateEmEdicao(template);
  }
}
