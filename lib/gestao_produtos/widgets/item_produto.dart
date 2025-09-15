import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:organiza_ae/data/models/produto.dart';
import 'package:organiza_ae/gestao_produtos/gestao_controller.dart';
// 1. Importar nossos dois widgets customizados
import 'package:organiza_ae/gestao_produtos/widgets/moeda_formatter.dart';
import 'package:organiza_ae/gestao_produtos/widgets/texto_cursor_final_controller.dart';

class ItemProduto extends ConsumerStatefulWidget {
  final Produto produto;
  const ItemProduto({required this.produto, super.key});

  @override
  ConsumerState<ItemProduto> createState() => _ItemProdutoState();
}

class _ItemProdutoState extends ConsumerState<ItemProduto> {
  // 2. Trocamos o controlador padrão pelo nosso controlador customizado.
  late final AlwaysEndCursorTextEditingController _precoController;

  @override
  void initState() {
    super.initState();
    final formatter = CurrencyPtBrInputFormatter();

    // 3. Instanciamos nosso novo controlador.
    _precoController = AlwaysEndCursorTextEditingController(
      text: formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: (widget.produto.preco * 100).toInt().toString()),
      ).text,
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
          controller: _precoController, // O TextField agora usa o controlador inteligente
          textAlign: TextAlign.right,
          onChanged: (novoPrecoFormatado) {
            ref.read(gestaoControllerProvider.notifier).atualizarPreco(widget.produto.id, novoPrecoFormatado);
          },
          decoration: const InputDecoration(
            prefixText: 'R\$ ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyPtBrInputFormatter(),
          ],
        ),
      ),
    );
  }
}

