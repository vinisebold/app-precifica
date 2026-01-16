import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../configuracoes/settings_controller.dart';

/// Notifier para controlar o auto-hide da barra de categorias ao rolar
class AutoHideCategoryBarNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Carrega o valor inicial das configurações
    final settingsController = ref.read(settingsControllerProvider.notifier);
    return settingsController.getAutoHideCategoryBar();
  }
  
  Future<void> toggle(bool value) async {
    state = value;
    final settingsController = ref.read(settingsControllerProvider.notifier);
    await settingsController.setAutoHideCategoryBar(value);
  }
}

/// Provider para controlar o auto-hide da barra de categorias
final autoHideCategoryBarProvider = NotifierProvider<AutoHideCategoryBarNotifier, bool>(() {
  return AutoHideCategoryBarNotifier();
});

