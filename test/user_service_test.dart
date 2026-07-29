import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserService service;

  setUp(() async {
    // Limpiar SharedPreferences antes de cada test
    SharedPreferences.setMockInitialValues({});
    service = UserService();
    // Resetear el singleton para tests aislados
    await service.clearAll();
  });

  tearDown(() async {
    await service.clearAll();
  });

  // ═══════════════════════════════════════════════════════════════════
  // PERFIL DE USUARIO
  // ═══════════════════════════════════════════════════════════════════
  group('UserProfile', () {
    test('getCurrentProfile returns default anonymous profile', () async {
      final profile = await service.getCurrentProfile();

      expect(profile, isNotNull);
      expect(profile!.id, 'anonymous');
      expect(profile.email, '');
      expect(profile.nombre, 'Usuario');
      expect(profile.favoritos, isEmpty);
      expect(profile.historial, isEmpty);
    });

    test('getCurrentProfile returns same instance on repeated calls', () async {
      final profile1 = await service.getCurrentProfile();
      final profile2 = await service.getCurrentProfile();

      // Sin mutaciones, debería devolver la misma instancia (caché)
      expect(identical(profile1, profile2), true);
    });

    test('updateName changes user name', () async {
      await service.updateName('Juan Pérez');
      final profile = await service.getCurrentProfile();

      expect(profile!.nombre, 'Juan Pérez');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // FAVORITOS
  // ═══════════════════════════════════════════════════════════════════
  group('Favorites', () {
    test('addFavorite adds receta to favorites', () async {
      await service.addFavorite('digestivo_01');

      final isFav = await service.isFavorite('digestivo_01');
      expect(isFav, true);
    });

    test('addFavorite does not add duplicate', () async {
      await service.addFavorite('digestivo_01');
      await service.addFavorite('digestivo_01');

      final favorites = await service.getFavorites();
      expect(favorites.length, 1);
    });

    test('removeFavorite removes receta from favorites', () async {
      await service.addFavorite('digestivo_01');
      await service.removeFavorite('digestivo_01');

      final isFav = await service.isFavorite('digestivo_01');
      expect(isFav, false);
    });

    test('removeFavorite is safe for non-existent receta', () async {
      await service.removeFavorite('nonexistent_01');

      final favorites = await service.getFavorites();
      expect(favorites, isEmpty);
    });

    test('isFavorite returns false for non-existent receta', () async {
      final isFav = await service.isFavorite('nonexistent_01');
      expect(isFav, false);
    });

    test('getFavorites returns all favorite IDs', () async {
      await service.addFavorite('digestivo_01');
      await service.addFavorite('nervioso_02');

      final favorites = await service.getFavorites();

      expect(favorites.length, 2);
      expect(favorites, contains('digestivo_01'));
      expect(favorites, contains('nervioso_02'));
    });

    test('favorites persist after service reload', () async {
      await service.addFavorite('digestivo_01');

      // Crear nuevo servicio (simula reinicio de app)
      final newService = UserService();
      final isFav = await newService.isFavorite('digestivo_01');

      expect(isFav, true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // HISTORIAL
  // ═══════════════════════════════════════════════════════════════════
  group('History', () {
    test('addToHistory adds receta to history', () async {
      await service.addToHistory('digestivo_01');

      final history = await service.getHistory();
      expect(history, contains('digestivo_01'));
    });

    test('addToHistory puts most recent first', () async {
      await service.addToHistory('digestivo_01');
      await service.addToHistory('nervioso_01');

      final history = await service.getHistory();

      expect(history.first, 'nervioso_01');
      expect(history.last, 'digestivo_01');
    });

    test('addToHistory moves existing receta to front', () async {
      await service.addToHistory('digestivo_01');
      await service.addToHistory('nervioso_01');
      await service.addToHistory('digestivo_01'); // Mover al frente

      final history = await service.getHistory();

      expect(history.first, 'digestivo_01');
      expect(history.length, 2); // No duplicado
    });

    test('addToHistory limits to 50 entries', () async {
      // Agregar 55 entradas
      for (var i = 0; i < 55; i++) {
        await service.addToHistory('receta_$i');
      }

      final history = await service.getHistory();

      expect(history.length, 50);
      // La más reciente debe ser la primera
      expect(history.first, 'receta_54');
      // La más antigua (5) debe haber sido eliminada
      expect(history.contains('receta_0'), false);
    });

    test('getHistory returns empty list initially', () async {
      final history = await service.getHistory();
      expect(history, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // LIMPIAR DATOS
  // ═══════════════════════════════════════════════════════════════════
  group('clearAll', () {
    test('clearAll removes all data', () async {
      await service.addFavorite('digestivo_01');
      await service.addToHistory('nervioso_01');
      await service.updateName('Test User');

      await service.clearAll();

      // Después de clearAll, debería crear perfil anónimo nuevo
      final profile = await service.getCurrentProfile();
      expect(profile!.nombre, 'Usuario');
      expect(profile.favoritos, isEmpty);
      expect(profile.historial, isEmpty);
    });
  });
}
