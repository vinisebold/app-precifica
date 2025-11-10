import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável por gerenciar o estado da tela de introdução (IntroductionScreen).
/// Diferente do tutorial showcase que é interativo, a introdução é exibida apenas uma vez.
class IntroductionService {
  static const String _introductionCompletedKey = 'introduction_completed';

  /// Verifica se a introdução já foi exibida.
  Future<bool> isIntroductionCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introductionCompletedKey) ?? false;
  }

  /// Marca a introdução como completada.
  Future<void> setIntroductionCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introductionCompletedKey, true);
  }

  /// Reseta a introdução (útil para testes ou se o usuário quiser ver novamente).
  Future<void> resetIntroduction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_introductionCompletedKey);
  }
}
