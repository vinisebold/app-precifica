import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../configuracoes/settings_controller.dart';

/// Notifier para o modo compacto/densidade
class ModoCompactoNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Carrega o valor inicial das configurações
    final settingsController = ref.read(settingsControllerProvider.notifier);
    return settingsController.getModoCompacto();
  }
  
  Future<void> toggle(bool value) async {
    state = value;
    final settingsController = ref.read(settingsControllerProvider.notifier);
    await settingsController.setModoCompacto(value);
  }
}

/// Provider para o modo compacto/densidade
final modoCompactoProvider = NotifierProvider<ModoCompactoNotifier, bool>(() {
  return ModoCompactoNotifier();
});
