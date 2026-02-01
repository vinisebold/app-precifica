import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:precifica/domain/entities/produto.dart';
import 'package:precifica/app/core/l10n/app_localizations.dart';
import '../gestao_controller.dart';

import '../../shared/providers/modo_compacto_provider.dart';

import 'package:precifica/app/core/utils/currency_formatter.dart';
import 'package:precifica/app/core/utils/final_cursor_text_input_formatter.dart';

class ItemProduto extends ConsumerStatefulWidget {
  final Produto produto;
  final VoidCallback onDoubleTap;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final TextInputAction textInputAction;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isFirst;
  final bool isLast;

  const ItemProduto({
    required this.produto,
    required this.onDoubleTap,
    required this.onTap,
    required this.onLongPress,
    required this.focusNode,
    required this.onSubmitted,
    required this.textInputAction,
    required this.isSelected,
    required this.isSelectionMode,
    this.isFirst = false,
    this.isLast = false,
    super.key,
  });

  @override
  ConsumerState<ItemProduto> createState() => _ItemProdutoState();
}

class _ItemProdutoState extends ConsumerState<ItemProduto> {
  late final InputCursorFinalController _precoController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final formatter = MoedaFormatter();
    _precoController = InputCursorFinalController(
      text: formatter
          .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
            text: (widget.produto.preco * 100).toInt().toString()),
      )
          .text,
    );
  }

  @override
  void dispose() {
    _precoController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _triggerSelectionAnimation() {
    if (!mounted) return;

    HapticFeedback.lightImpact();
  }

  void _handleLongPress() {
    _triggerSelectionAnimation();
    widget.onLongPress();
  }

  void _handleTap() {
    if (widget.isSelectionMode) {
      _triggerSelectionAnimation();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
    final isAtivo = widget.produto.isAtivo;
    final modoCompacto = ref.watch(modoCompactoProvider);
    final l10n = AppLocalizations.of(context)!;

    // Define os valores de padding e altura baseado no modo compacto
    final double verticalPadding = modoCompacto ? 10.0 : 14.0;
    final double horizontalPadding = modoCompacto ? 12.0 : 16.0;
    final double fontSize = modoCompacto ? 14.0 : 16.0;
    final double inputWidth = modoCompacto ? 100.0 : 120.0;

    // M3 grouped style: cantos externos arredondados, internos levemente arredondados
    // Quando selecionado, todas as bordas ficam com radius maior
    final double outerRadius = modoCompacto ? 12.0 : 16.0;
    final double innerRadius = modoCompacto ? 3.0 : 4.0; // Cantos internos agora levemente arredondados

    // SOLUÇÃO PARA O GLITCH DA BORDA:
    // Usamos BorderRadius.only em ambos os estados para que o Flutter 
    // saiba interpolar os valores sem "se perder" e ficar quadrado no meio.
    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.isSelected || widget.isFirst ? outerRadius : innerRadius),
      topRight: Radius.circular(widget.isSelected || widget.isFirst ? outerRadius : innerRadius),
      bottomLeft: Radius.circular(widget.isSelected || widget.isLast ? outerRadius : innerRadius),
      bottomRight: Radius.circular(widget.isSelected || widget.isLast ? outerRadius : innerRadius),
    );
    
    // Formata o preço para acessibilidade
    final formattedPrice = 'R\$ ${_precoController.text}';
    final statusLabel = isAtivo ? l10n.activeStatus : l10n.inactiveStatus;
    final productSemanticLabel = l10n.productItemLabel(
      widget.produto.nome, 
      formattedPrice, 
      statusLabel,
    );

    // M3 filled list item: container com cor de fundo adaptada ao tema
    // Tema claro: cor mais clara (surfaceContainerLowest)
    // Tema escuro: cor mais escura (surface)
    // Quando selecionado: background um pouco mais claro
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkTheme 
        ? colorScheme.surface
        : colorScheme.surfaceContainerLowest;
    
    final fillColor = widget.isSelected
        ? (isDarkTheme
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainer)
        : baseColor;

    // Conteúdo do item em layout Row para maior controle
    final itemContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        children: [
          // Texto do produto (expandido)
          Expanded(
            child: Text(
              widget.produto.nome,
              style: TextStyle(
                decoration:
                    isAtivo ? TextDecoration.none : TextDecoration.lineThrough,
                color: colorScheme.onSurface,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Campo de preço ou espaço reservado quando selecionado
          SizedBox(
            width: inputWidth,
            child: widget.isSelected
                ? SizedBox(
                    height: modoCompacto ? 40.0 : 48.0,
                  )
                : TextField(
                    controller: _precoController,
                    focusNode: widget.focusNode,
                    textAlign: TextAlign.right,
                    onSubmitted: (_) => widget.onSubmitted(),
                    textInputAction: widget.textInputAction,
                    onChanged: (novoPrecoFormatado) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        gestaoNotifier.atualizarPreco(
                            widget.produto.id, novoPrecoFormatado);
                      });
                    },
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'R\$ ',
                      prefixStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(modoCompacto ? 8.0 : 10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: modoCompacto ? 8.0 : 10.0,
                        vertical: modoCompacto ? 8.0 : 10.0,
                      ),
                      isDense: modoCompacto,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      MoedaFormatter(),
                    ],
                  ),
          ),
        ],
      ),
    );

    // Container com estilo M3: filled + grouped shape + ripple effect
    final rippleColor = colorScheme.surfaceContainer;
    final decoratedContent = SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        // O Clip.antiAlias aqui é o "mestre". Ele corta tudo o que está dentro,
        // incluindo o Sparkle, seguindo a animação da borda em tempo real.
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: borderRadius,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            onLongPress: _handleLongPress,
            onDoubleTap: widget.isSelectionMode ? null : widget.onDoubleTap,
            // REMOVEMOS o borderRadius daqui!
            borderRadius: null,
            splashFactory: InkSparkle.splashFactory,
            splashColor: rippleColor,
            highlightColor: rippleColor,
            hoverColor: rippleColor,
            child: itemContent,
          ),
        ),
      ),
    );

    // O Semantics envolve tudo
    return Semantics(
      label: productSemanticLabel,
      hint: widget.isSelectionMode
          ? 'Toque para selecionar ou desmarcar.'
          : '${l10n.doubleTapToEditHint}. ${l10n.toggleProductStatusHint}',
      enabled: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: isAtivo ? 1.0 : 0.4,
        child: decoratedContent,
      ),
    );
  }
}