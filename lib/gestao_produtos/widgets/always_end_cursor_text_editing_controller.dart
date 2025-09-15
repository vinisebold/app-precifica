import 'package:flutter/widgets.dart';

/// Um [TextEditingController] customizado que garante que o cursor de seleção
/// esteja sempre posicionado no final do texto.
///
/// Isso é útil para campos de entrada formatados, como moeda, onde a edição
/// no meio do texto não é desejada.
class AlwaysEndCursorTextEditingController extends TextEditingController {
  AlwaysEndCursorTextEditingController({super.text});

  // Sobrescrevemos o 'setter' do valor do controlador.
  @override
  set value(TextEditingValue newValue) {
    // Sempre que um novo valor (texto ou seleção) for definido,
    // nós o modificamos para forçar a seleção a ficar no final do texto.
    super.value = newValue.copyWith(
      selection: TextSelection.collapsed(offset: newValue.text.length),
    );
  }
}
