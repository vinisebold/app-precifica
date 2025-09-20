import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:precifica/data/models/produto.dart';
import 'package:precifica/gestao_produtos/gestao_controller.dart';
import 'package:precifica/gestao_produtos/widgets/moeda_formatter.dart';
import 'package:precifica/gestao_produtos/widgets/input_cursor_final_controller.dart';

class ItemProduto extends ConsumerStatefulWidget {
  final Produto produto;
  final VoidCallback onDoubleTap;

  const ItemProduto({
    required this.produto,
    required this.onDoubleTap,
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

  // MÉTODO DE ANIMAÇÃO OTIMIZADO
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
            child: feedback, // Reutiliza o widget de feedback
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

    final itemContent = ListTile(
      title: Text(widget.produto.nome),
      trailing: SizedBox(
        width: 120,
        child: TextField(
          controller: _precoController,
          textAlign: TextAlign.right,
          onChanged: (novoPrecoFormatado) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              gestaoNotifier.atualizarPreco(
                  widget.produto.id, novoPrecoFormatado);
            });
          },
          decoration: InputDecoration(
            prefixText: 'R\$ ',
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            MoedaFormatter(),
          ],
        ),
      ),
    );

    // OTIMIZAÇÃO: Construir o feedback uma única vez.
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

    return Opacity(
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
        child: GestureDetector(
          onDoubleTap: widget.onDoubleTap,
          child: itemContent,
        ),
      ),
    );
  }
}