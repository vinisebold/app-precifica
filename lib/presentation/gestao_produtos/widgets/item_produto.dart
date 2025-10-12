import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:precificador/domain/entities/produto.dart';

import '../gestao_controller.dart';
import '../../shared/providers/modo_compacto_provider.dart';

import 'package:precificador/app/core/utils/currency_formatter.dart';
import 'package:precificador/app/core/utils/final_cursor_text_input_formatter.dart';

class ItemProduto extends ConsumerStatefulWidget {
  final Produto produto;
  final VoidCallback onDoubleTap;
  final VoidCallback onTap;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final TextInputAction textInputAction;

  const ItemProduto({
    required this.produto,
    required this.onDoubleTap,
    required this.onTap,
    required this.focusNode,
    required this.onSubmitted,
    required this.textInputAction,
    super.key,
  });

  @override
  ConsumerState<ItemProduto> createState() => _ItemProdutoState();
}

class _ItemProdutoState extends ConsumerState<ItemProduto> {
  late final InputCursorFinalController _precoController;
  Timer? _debounce;
  OverlayEntry? _revertingOverlayEntry;
  bool _isReverting = false;

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
    _revertingOverlayEntry?.remove();
    super.dispose();
  }

  void _revertDragAnimation(Offset dragEndOffset, Widget feedback) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final Offset targetPosition = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    bool isAnimationStarted = false;

    _revertingOverlayEntry?.remove();
    _revertingOverlayEntry = null;

    _revertingOverlayEntry = OverlayEntry(builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!isAnimationStarted) {
              setState(() => isAnimationStarted = true);
            }
          });

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            top: isAnimationStarted ? targetPosition.dy : dragEndOffset.dy,
            left: isAnimationStarted ? targetPosition.dx : dragEndOffset.dx,
            width: size.width,
            height: size.height,
            onEnd: () {
              if (mounted) {
                _revertingOverlayEntry?.remove();
                _revertingOverlayEntry = null;
                this.setState(() => _isReverting = false);
                ref
                    .read(gestaoControllerProvider.notifier)
                    .setDraggingProduto(false);
              }
            },
            child: feedback,
          );
        },
      );
    });

    setState(() => _isReverting = true);
    Overlay.of(context).insert(_revertingOverlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);
    final isAtivo = widget.produto.isAtivo;
    final modoCompacto = ref.watch(modoCompactoProvider);

    // Define os valores de padding e altura baseado no modo compacto
    final double verticalPadding = modoCompacto ? 4.0 : 8.0;
    final double horizontalPadding = modoCompacto ? 8.0 : 12.0;
    final double fontSize = modoCompacto ? 14.0 : 16.0;
    final double inputWidth = modoCompacto ? 100.0 : 120.0;

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
        child: TextField(
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
            prefixText: 'R\$ ',
            prefixStyle: TextStyle(fontSize: fontSize),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(modoCompacto ? 8.0 : 12.0),
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

    final feedbackWidget = Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        width: MediaQuery.of(context).size.width - 16,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: itemContent,
      ),
    );

    // O GestureDetector para onTap (reativar) agora envolve tudo.
    return GestureDetector(
      onTap: widget.onTap,
      // Passa o comportamento de toque para os filhos se não houver conflito.
      behavior: HitTestBehavior.translucent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isAtivo ? 1.0 : 0.4,
        child: IgnorePointer(
          ignoring: !isAtivo,
          child: Opacity(
            opacity: _isReverting ? 0.0 : 1.0,
            child: LongPressDraggable<Produto>(
              data: widget.produto,
              onDragStarted: () {
                HapticFeedback.lightImpact();
                gestaoNotifier.setDraggingProduto(true);
              },
              onDragEnd: (details) {
                if (!details.wasAccepted && !_isReverting) {
                  gestaoNotifier.setDraggingProduto(false);
                }
              },
              onDraggableCanceled: (velocity, offset) {
                _revertDragAnimation(offset, feedbackWidget);
              },
              feedback: feedbackWidget,
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: itemContent,
              ),
              // O GestureDetector interno agora só lida com o doubleTap.
              child: GestureDetector(
                onDoubleTap: widget.onDoubleTap,
                child: itemContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}