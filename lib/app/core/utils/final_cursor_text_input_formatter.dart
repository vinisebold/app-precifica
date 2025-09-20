import 'package:flutter/widgets.dart';

/// Um [TextEditingController] customizado que garante que o cursor de seleção
/// esteja sempre posicionado no final do texto, independentemente de onde
/// o usuário toque no campo.
///
/// Isso é útil para campos de entrada formatados, como moeda, onde a edição
/// no meio do texto não é desejada.
class InputCursorFinalController extends TextEditingController {
  InputCursorFinalController({super.text});

  @override
  set value(TextEditingValue newValue) {
    // Sempre que um novo valor for definido,
    // nós o modificamos para forçar a seleção a ficar no final do texto.

    super.value = newValue.copyWith(
      selection: TextSelection.collapsed(offset: newValue.text.length),
    );
  }
}
