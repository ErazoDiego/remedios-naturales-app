import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/core/services/payments/premium_rules.dart';
import 'package:remedios_naturales_app/core/utils/text_normalizer.dart';
import 'package:remedios_naturales_app/data/services/search_index.dart';

/// Tests del índice de búsqueda: normalización, descomposición de términos,
/// sinónimos y coherencia con las recetas gratis del plan FREE.
void main() {
  group('normalizarTexto', () {
    test('quita tildes y convierte a minúsculas', () {
      expect(normalizarTexto('Estrés'), 'estres');
      expect(normalizarTexto('Náuseas'), 'nauseas');
      expect(normalizarTexto('INFUSIÓN'), 'infusion');
    });

    test('convierte ñ en n (típico error de búsqueda móvil)', () {
      expect(normalizarTexto('Estómago'), 'estomago');
      expect(normalizarTexto('Riñones'), 'rinones');
      expect(normalizarTexto('Espinillas'), 'espinillas');
    });
  });

  group('SearchIndex.terminosDe', () {
    test('descompone en términos y filtra stopwords', () {
      expect(
        SearchIndex.terminosDe('dolor de cabeza'),
        containsAll(['dolor', 'cabeza']),
      );
    });

    test('normaliza tildes de la query', () {
      expect(
        SearchIndex.terminosDe('estrés'),
        contains('estres'),
      );
    });

    test('elimina duplicados', () {
      final terminos = SearchIndex.terminosDe('tos tos tos');
      expect(terminos, ['tos']);
    });

    test('query solo con stopwords no produce términos', () {
      expect(SearchIndex.terminosDe('de la el'), isEmpty);
    });
  });

  group('SearchIndex.sinonimosDe', () {
    test('expande al grupo completo', () {
      final sinonimos = SearchIndex.sinonimosDe('cefalea');
      expect(sinonimos,
          containsAll(['cefalea', 'dolor de cabeza', 'migrana']));
    });

    test('término sin grupo: se devuelve a sí mismo', () {
      expect(SearchIndex.sinonimosDe('manzanilla'), ['manzanilla']);
    });
  });

  group('SearchIndex.keywordsDe', () {
    test('normaliza las keywords', () {
      final keywords = SearchIndex.keywordsDe('digestivo_03');
      expect(keywords, contains('acidez'));
      expect(keywords, contains('acidez de estomago'));
    });

    test('receta sin keywords devuelve lista vacía', () {
      expect(SearchIndex.keywordsDe('no_existe'), isEmpty);
    });
  });

  group('Coherencia con el plan FREE', () {
    test('las 50 recetas gratis del muestreo tienen keywords de búsqueda',
        () {
      for (final id in PremiumRules.recetasGratisPorSistema) {
        expect(
          SearchIndex.keywordsPorReceta.containsKey(id),
          isTrue,
          reason: '$id (receta gratis) debería tener keywords en el índice',
        );
      }
    });

    test('los IDs con keywords existen en el formato <sistema>_NN', () {
      for (final id in SearchIndex.keywordsPorReceta.keys) {
        expect(RegExp(r'^[a-z]+_\d{2}$').hasMatch(id), isTrue,
            reason: 'ID inválido en el índice: $id');
      }
    });
  });
}
