import 'package:flutter/material.dart';

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 56,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nada por aqui ainda',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Em breve você poderá personalizar sua experiência.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
