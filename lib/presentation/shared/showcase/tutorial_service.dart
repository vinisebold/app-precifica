import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável por gerenciar o estado do tutorial interativo.
class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed';

  /// Verifica se o tutorial já foi completado.
  Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  /// Marca o tutorial como completado.
  Future<void> setTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  /// Reseta o tutorial (útil para testes ou opção de visualizar novamente).
  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompletedKey);
  }
}
