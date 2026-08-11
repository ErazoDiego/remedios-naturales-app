import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/core/services/payments/premium_rules.dart';

/// Reglas puras del plan FREE (límite 5 favoritos / 5 recetas propias).
void main() {
  group('PremiumRules.canAddFavorite', () {
    test('premium: siempre puede agregar, sin importar el conteo', () {
      expect(
        PremiumRules.canAddFavorite(isPremium: true, currentFavorites: 99),
        isTrue,
      );
    });

    test('free con menos de 5 favoritos: puede agregar', () {
      for (var i = 0; i < 5; i++) {
        expect(
          PremiumRules.canAddFavorite(isPremium: false, currentFavorites: i),
          isTrue,
          reason: 'con $i favoritos debería poder agregar',
        );
      }
    });

    test('free con 5 favoritos: llega al límite, NO puede agregar', () {
      expect(
        PremiumRules.canAddFavorite(isPremium: false, currentFavorites: 5),
        isFalse,
      );
    });

    test('free con más de 5 favoritos: tampoco puede agregar', () {
      expect(
        PremiumRules.canAddFavorite(isPremium: false, currentFavorites: 7),
        isFalse,
      );
    });
  });

  group('PremiumRules.canCreateReceta', () {
    test('premium: siempre puede crear', () {
      expect(
        PremiumRules.canCreateReceta(isPremium: true, currentRecetas: 50),
        isTrue,
      );
    });

    test('free con menos de 5 recetas: puede crear', () {
      expect(
        PremiumRules.canCreateReceta(isPremium: false, currentRecetas: 4),
        isTrue,
      );
    });

    test('free con 5 recetas: llega al límite, NO puede crear', () {
      expect(
        PremiumRules.canCreateReceta(isPremium: false, currentRecetas: 5),
        isFalse,
      );
    });
  });

  group('PremiumRules.esRecetaGratuita', () {
    test('una receta del muestreo es gratuita', () {
      expect(PremiumRules.esRecetaGratuita('digestivo_03'), isTrue);
    });

    test('una receta fuera del muestreo no es gratuita', () {
      expect(PremiumRules.esRecetaGratuita('digestivo_01'), isFalse);
    });
  });

  group('PremiumRules.puedeAccederAReceta', () {
    test('premium: puede acceder a cualquier receta', () {
      expect(
        PremiumRules.puedeAccederAReceta(
          isPremium: true,
          recipeId: 'digestivo_01',
        ),
        isTrue,
      );
    });

    test('free: puede acceder a las recetas del muestreo', () {
      expect(
        PremiumRules.puedeAccederAReceta(
          isPremium: false,
          recipeId: 'digestivo_03',
        ),
        isTrue,
      );
    });

    test('free: NO puede acceder a recetas fuera del muestreo', () {
      expect(
        PremiumRules.puedeAccederAReceta(
          isPremium: false,
          recipeId: 'digestivo_01',
        ),
        isFalse,
      );
    });
  });

  group('PremiumRules.recetasGratisPorSistema', () {
    test('contiene 50 recetas gratis (5 por cada uno de los 10 sistemas)', () {
      final ids = PremiumRules.recetasGratisPorSistema;
      expect(ids, hasLength(50));

      const sistemas = [
        'digestivo',
        'nervioso',
        'respiratorio',
        'inmunitario',
        'cardiovascular',
        'hormonal',
        'musculoesqueletico',
        'urinario',
        'dermico',
        'sensorial',
      ];
      for (final sistema in sistemas) {
        final porSistema =
            ids.where((id) => id.startsWith('${sistema}_')).toList();
        expect(
          porSistema,
          hasLength(5),
          reason: '$sistema debería tener 5 recetas gratis',
        );
      }
    });

    test('todos los IDs son únicos y siguen el patrón <sistema>_NN', () {
      final ids = PremiumRules.recetasGratisPorSistema;
      expect(ids.toSet(), hasLength(ids.length),
          reason: 'no debería haber IDs repetidos');
      for (final id in ids) {
        expect(RegExp(r'^[a-z]+_\d{2}$').hasMatch(id), isTrue,
            reason: 'ID inválido: $id');
      }
    });
  });
}
