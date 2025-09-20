import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Um [TextInputFormatter] que formata a entrada de texto como moeda no padrão
/// brasileiro (pt_BR), por exemplo, "1.234,56".
///
/// A lógica trata a entrada de dígitos como centavos e os formata
/// dinamicamente, movendo a vírgula da direita para a esquerda.
class MoedaFormatter extends TextInputFormatter {
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Se não houver dígitos retorna o valor padrão "0,00".
    if (digitsOnly.isEmpty) {
      digitsOnly = '0';
    }

    // Ex: "123" se torna 1.23
    final number = double.parse(digitsOnly) / 100;

    // .trim() remove espaços extras que o formatter pode adicionar.
    final newString = _formatter.format(number).trim();

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
