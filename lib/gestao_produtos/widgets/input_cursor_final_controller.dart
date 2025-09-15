import 'package:flutter/widgets.dart';

class InputCursorFinalController extends TextEditingController {
  InputCursorFinalController({super.text});

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
