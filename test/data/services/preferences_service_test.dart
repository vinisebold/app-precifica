import 'package:flutter_test/flutter_test.dart';
import 'package:precificador/data/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PreferencesService', () {
    late PreferencesService preferencesService;

    setUp(() async {
      // Limpa as preferências antes de cada teste
      SharedPreferences.setMockInitialValues({});
      preferencesService = PreferencesService();
    });

    test('deve salvar e recuperar o ID da última categoria', () async {
      const categoryId = 'categoria-123';
      
      // Salva
      await preferencesService.saveLastCategoryId(categoryId);
      
      // Recupera
      final savedId = await preferencesService.getLastCategoryId();
      
      expect(savedId, equals(categoryId));
    });

    test('deve retornar null quando não há categoria salva', () async {
      final savedId = await preferencesService.getLastCategoryId();
      
      expect(savedId, isNull);
    });

    test('deve salvar e recuperar a posição de scroll', () async {
      const categoryId = 'categoria-123';
      const scrollPosition = 150.5;
      
      // Salva
      await preferencesService.saveScrollPosition(categoryId, scrollPosition);
      
      // Recupera
      final savedPosition = await preferencesService.getScrollPosition(categoryId);
      
      expect(savedPosition, equals(scrollPosition));
    });

    test('deve retornar 0.0 quando não há posição de scroll salva', () async {
      const categoryId = 'categoria-nao-existe';
      
      final position = await preferencesService.getScrollPosition(categoryId);
      
      expect(position, equals(0.0));
    });

    test('deve manter posições de scroll diferentes para categorias diferentes', () async {
      const category1 = 'categoria-1';
      const category2 = 'categoria-2';
      const position1 = 100.0;
      const position2 = 200.0;
      
      // Salva posições diferentes
      await preferencesService.saveScrollPosition(category1, position1);
      await preferencesService.saveScrollPosition(category2, position2);
      
      // Verifica que cada categoria mantém sua posição
      final savedPosition1 = await preferencesService.getScrollPosition(category1);
      final savedPosition2 = await preferencesService.getScrollPosition(category2);
      
      expect(savedPosition1, equals(position1));
      expect(savedPosition2, equals(position2));
    });

    test('deve limpar a posição de scroll de uma categoria específica', () async {
      const categoryId = 'categoria-123';
      const scrollPosition = 150.5;
      
      // Salva
      await preferencesService.saveScrollPosition(categoryId, scrollPosition);
      
      // Limpa
      await preferencesService.clearScrollPosition(categoryId);
      
      // Verifica que foi limpo
      final position = await preferencesService.getScrollPosition(categoryId);
      expect(position, equals(0.0));
    });

    test('deve limpar todas as posições de scroll', () async {
      const category1 = 'categoria-1';
      const category2 = 'categoria-2';
      
      // Salva posições
      await preferencesService.saveScrollPosition(category1, 100.0);
      await preferencesService.saveScrollPosition(category2, 200.0);
      
      // Limpa todas
      await preferencesService.clearAllScrollPositions();
      
      // Verifica que todas foram limpas
      final position1 = await preferencesService.getScrollPosition(category1);
      final position2 = await preferencesService.getScrollPosition(category2);
      
      expect(position1, equals(0.0));
      expect(position2, equals(0.0));
    });

    test('deve limpar todas as preferências incluindo categoria e scroll', () async {
      const categoryId = 'categoria-123';
      const scrollPosition = 150.5;
      
      // Salva categoria e scroll
      await preferencesService.saveLastCategoryId(categoryId);
      await preferencesService.saveScrollPosition(categoryId, scrollPosition);
      
      // Limpa tudo
      await preferencesService.clearAll();
      
      // Verifica que tudo foi limpo
      final savedId = await preferencesService.getLastCategoryId();
      final position = await preferencesService.getScrollPosition(categoryId);
      
      expect(savedId, isNull);
      expect(position, equals(0.0));
    });
  });
}
