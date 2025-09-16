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

    return Dismissible(
      key: ValueKey(widget.produto.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        gestaoNotifier.deletarProduto(widget.produto.id);
      },
      background: Container(
        color: colorScheme.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.delete,
          color: colorScheme.onErrorContainer,
        ),
      ),
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        child: ListTile(
          title: Text(widget.produto.nome),
          trailing: SizedBox(
            width: 100,
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
              decoration: const InputDecoration(
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                MoedaFormatter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
