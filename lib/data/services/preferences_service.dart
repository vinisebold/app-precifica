import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar preferências persistentes do aplicativo.
class PreferencesService {
  static const String _lastCategoryIdKey = 'last_category_id';
  static const String _scrollPositionPrefix = 'scroll_position_';

  /// Salva o ID da última categoria visualizada.
  Future<void> saveLastCategoryId(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCategoryIdKey, categoryId);
  }

  /// Recupera o ID da última categoria visualizada.
  Future<String?> getLastCategoryId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastCategoryIdKey);
  }

  /// Salva a posição de rolagem para uma categoria específica.
  Future<void> saveScrollPosition(String categoryId, double position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_scrollPositionPrefix$categoryId', position);
  }

  /// Recupera a posição de rolagem para uma categoria específica.
  Future<double> getScrollPosition(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_scrollPositionPrefix$categoryId') ?? 0.0;
  }

  /// Limpa a posição de rolagem de uma categoria específica.
  Future<void> clearScrollPosition(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_scrollPositionPrefix$categoryId');
  }

  /// Limpa todas as posições de rolagem salvas.
  Future<void> clearAllScrollPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_scrollPositionPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// Limpa todas as preferências.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
