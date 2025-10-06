import 'package:flutter/material.dart';

class WhatsAppFormattedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double lineHeight;

  const WhatsAppFormattedText({
    super.key,
    required this.text,
    this.fontSize = 13,
    this.lineHeight = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _parseText(text),
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        height: lineHeight,
      ),
    );
  }

  TextSpan _parseText(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*([^*]+)\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Adiciona o texto antes do match (normal)
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
        ));
      }

      // Adiciona o texto em negrito (sem os asteriscos)
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));

      lastIndex = match.end;
    }

    // Adiciona o restante do texto
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
      ));
    }

    return TextSpan(children: spans);
  }
}
