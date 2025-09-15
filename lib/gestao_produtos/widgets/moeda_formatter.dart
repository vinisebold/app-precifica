import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MoedaFormatter extends TextInputFormatter {
  // Define o formato de moeda para o padrão pt_BR (ex: 1.234,56)
  // O símbolo é opcional, então o removemos para um visual mais limpo no TextField.
  final NumberFormat _formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // 1. Pega apenas os dígitos do texto que o usuário digitou.
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Se não houver dígitos, retorna o valor padrão "0,00".
    if (digitsOnly.isEmpty) {
      digitsOnly = '0';
    }

    // 2. Converte a string de dígitos para um número, tratando-a como centavos.
    // Ex: "123" se torna 1.23
    final number = double.parse(digitsOnly) / 100;

    // 3. Formata o número para a string de moeda (ex: "1,23").
    // .trim() remove espaços extras que o formatter pode adicionar.
    final newString = _formatter.format(number).trim();

    // 4. Retorna o novo valor formatado, com o cursor sempre no final.
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}