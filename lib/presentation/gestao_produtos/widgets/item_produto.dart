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
    super.key,
  });

  @override
  ConsumerState<ItemProduto> createState() => _ItemProdutoState();
}

class _ItemProdutoState extends ConsumerState<ItemProduto> {
  late final InputCursorFinalController _precoController;
  Timer? _debounce;
  bool _showPopAnimation = false;
  bool _showPressAnimation = false;

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

    setState(() {
      _showPressAnimation = true;
    });
    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      setState(() {
        _showPressAnimation = false;
        _showPopAnimation = true;
      });

      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) {
          setState(() => _showPopAnimation = false);
        }
      });
    });
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
    final double verticalPadding = modoCompacto ? 4.0 : 8.0;
    final double horizontalPadding = modoCompacto ? 8.0 : 12.0;
    final double fontSize = modoCompacto ? 14.0 : 16.0;
    final double inputWidth = modoCompacto ? 100.0 : 120.0;
    
    // Formata o preço para acessibilidade
    final formattedPrice = 'R\$ ${_precoController.text}';
    final statusLabel = isAtivo ? l10n.activeStatus : l10n.inactiveStatus;
    final productSemanticLabel = l10n.productItemLabel(
      widget.produto.nome, 
      formattedPrice, 
      statusLabel,
    );

    // A construção do conteúdo do item (ListTile)
    final itemContent = ListTile(
      dense: modoCompacto,
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding * 0.5,
      ),
      title: Text(
        widget.produto.nome,
        style: TextStyle(
          decoration:
          isAtivo ? TextDecoration.none : TextDecoration.lineThrough,
          color: isAtivo ? null : colorScheme.outline,
          fontSize: fontSize,
        ),
      ),
      trailing: SizedBox(
        width: inputWidth,
        child: widget.isSelected
            ? const SizedBox.shrink()
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
                style: TextStyle(fontSize: fontSize),
                decoration: InputDecoration(
                  prefixText: 'R\$',
                  prefixStyle: TextStyle(fontSize: fontSize),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(modoCompacto ? 8.0 : 12.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: modoCompacto ? 6.0 : 8.0,
                    vertical: modoCompacto ? 6.0 : 8.0,
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
    );

    final borderColor = widget.isSelected
        ? colorScheme.primary.withValues(alpha: 0.55)
        : Colors.transparent;

    final decoratedContent = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(modoCompacto ? 10.0 : 12.0),
        border: Border.all(
          color: borderColor,
          width: widget.isSelected ? 2.0 : 0.0,
        ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: itemContent,
    );

    // O GestureDetector para onTap (reativar) agora envolve tudo.
    return Semantics(
      label: productSemanticLabel,
      hint: widget.isSelectionMode
          ? 'Toque para selecionar ou desmarcar.'
          : '${l10n.doubleTapToEditHint}. ${l10n.toggleProductStatusHint}',
      enabled: true,
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        behavior: HitTestBehavior.translucent,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isAtivo ? 1.0 : 0.4,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: _showPopAnimation 
                ? 1.03 
                : (_showPressAnimation ? 0.97 : 1.0),
            curve: Curves.easeOutBack,
            child: IgnorePointer(
              ignoring: !isAtivo || widget.isSelectionMode,
              child: GestureDetector(
                onDoubleTap: widget.onDoubleTap,
                child: decoratedContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}