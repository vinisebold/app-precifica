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
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            MoedaFormatter(),
          ],
        ),
      ),
    );

    return LongPressDraggable<Produto>(
      data: widget.produto, // O dado que será arrastado
      onDragStarted: () {
        HapticFeedback.lightImpact();
        gestaoNotifier.setDraggingProduto(true); // Avisa que o arraste começou
      },
      onDragEnd: (details) {
        gestaoNotifier.setDraggingProduto(false); // Avisa que o arraste terminou
      },
      onDraggableCanceled: (velocity, offset) {
        gestaoNotifier.setDraggingProduto(false); // Avisa que o arraste foi cancelado
      },
      // O visual do item enquanto está a ser arrastado
      feedback: Material(
        elevation: 4.0,
        child: Container(
          width: MediaQuery.of(context).size.width - 16, // Para encaixar na tela
          color: colorScheme.surfaceContainerHighest,
          child: itemContent,
        ),
      ),
      // O visual do item no lugar original enquanto está a ser arrastado
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: itemContent,
      ),
      // O item normal, quando não está a ser arrastado
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        child: itemContent,
      ),
    );
  }
}