// lib/gestao_produtos/widgets/item_produto.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/data/models/produto.dart';
import 'package:organiza_ae/gestao_produtos/gestao_controller.dart';
import 'package:organiza_ae/gestao_produtos/widgets/moeda_formatter.dart';
import 'package:organiza_ae/gestao_produtos/widgets/input_cursor_final_controller.dart';

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

class _ItemProdutoState extends ConsumerState<ItemProduto>
    with TickerProviderStateMixin {
  late final InputCursorFinalController _precoController;
  Timer? _debounce;
  OverlayEntry? _revertingOverlayEntry;
  AnimationController? _revertAnimationController;
  Animation<Offset>? _revertAnimation;
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
    _revertAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completeRevertAnimation();
        }
      });
  }

  void _completeRevertAnimation() {
    _revertingOverlayEntry?.remove();
    _revertingOverlayEntry = null;
    if (mounted) {
      setState(() {
        _isReverting = false;
      });
    }
    ref.read(gestaoControllerProvider.notifier).setDraggingProduto(false);
  }

  @override
  void dispose() {
    _precoController.dispose();
    _debounce?.cancel();
    _revertAnimationController?.dispose();
    _revertingOverlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gestaoNotifier = ref.read(gestaoControllerProvider.notifier);

    // O conteúdo visual do nosso item
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

    return Opacity(
      opacity: _isReverting ? 0.0 : 1.0,
      child: LongPressDraggable<Produto>(
        data: widget.produto,
        onDragStarted: () {
          HapticFeedback.lightImpact();
          gestaoNotifier.setDraggingProduto(true);
        },
        onDragEnd: (details) {
          if (!details.wasAccepted) {
            gestaoNotifier.setDraggingProduto(false);
          }
        },
        onDraggableCanceled: (velocity, offset) {
          setState(() {
            _isReverting = true;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              _completeRevertAnimation();
              return;
            }

            final RenderBox? renderBox =
                context.findRenderObject() as RenderBox?;
            if (renderBox == null || !renderBox.attached) {
              _completeRevertAnimation();
              return;
            }
            final Offset targetPosition = renderBox.localToGlobal(Offset.zero);

            _revertAnimation = Tween<Offset>(begin: offset, end: targetPosition)
                .animate(CurvedAnimation(
              parent: _revertAnimationController!,
              curve: Curves.easeOutCubic,
            ));

            _revertingOverlayEntry?.remove();
            _revertingOverlayEntry = OverlayEntry(builder: (context) {
              return AnimatedBuilder(
                animation: _revertAnimation!,
                builder: (context, child) {
                  return Positioned(
                    left: _revertAnimation!.value.dx,
                    top: _revertAnimation!.value.dy,
                    child: child!,
                  );
                },
                child: Material(
                  elevation: 4.0,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 16,
                    color: colorScheme.surfaceContainerHighest,
                    child: itemContent,
                  ),
                ),
              );
            });

            Overlay.of(context).insert(_revertingOverlayEntry!);
            _revertAnimationController!.forward(from: 0.0);
          });
        },
        feedback: Material(
          elevation: 4.0,
          child: Container(
            width: MediaQuery.of(context).size.width - 16,
            color: colorScheme.surfaceContainerHighest,
            child: itemContent,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
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
