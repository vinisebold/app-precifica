import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/data/models/produto.dart';
import 'package:organiza_ae/gestao_produtos/gestao_controller.dart';
import 'package:organiza_ae/gestao_produtos/widgets/moeda_formatter.dart';
import 'package:organiza_ae/gestao_produtos/widgets/input_cursor_final_controller.dart';

/// Um widget que representa um único item na lista de produtos.
///
/// É um `ConsumerStatefulWidget` porque precisa gerenciar o estado do
/// `TextEditingController` do campo de preço.
class ItemProduto extends ConsumerStatefulWidget {
  final Produto produto;

  const ItemProduto({required this.produto, super.key});

  @override
  ConsumerState<ItemProduto> createState() => _ItemProdutoState();
}

class _ItemProdutoState extends ConsumerState<ItemProduto> {
  late final InputCursorFinalController _precoController;

  @override
  void initState() {
    super.initState();
    final formatter = MoedaFormatter();

    // Instancia o controlador.
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.produto.nome),
      trailing: SizedBox(
        width: 100,
        child: TextField(
          controller: _precoController,
          textAlign: TextAlign.right,
          // Cada alteração no texto, chama o métod* `atualizarPreco` no controller principal.
          onChanged: (novoPrecoFormatado) {
            ref
                .read(gestaoControllerProvider.notifier)
                .atualizarPreco(widget.produto.id, novoPrecoFormatado);
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
    );
  }
}
