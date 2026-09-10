import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/features/biblioteca/domain/favorito_coleccion.dart';

/// FavoritoColeccion: el ID plano que guarda favoritos para recetas de
/// colección (`col:<coleccionId>:<recetaId>`) y su descomposición.
void main() {
  group('FavoritoColeccion', () {
    test('idDe arma el id compuesto col:coleccion:receta', () {
      expect(
        FavoritoColeccion.idDe('jugos', 'jugos_01'),
        'col:jugos:jugos_01',
      );
    });

    test('round-trip: idDe -> descomponer devuelve colección y receta',
        () {
      final id = FavoritoColeccion.idDe('kefir', 'kefir_07');
      final d = FavoritoColeccion.descomponer(id);

      expect(d, isNotNull);
      expect(d!.$1, 'kefir');
      expect(d.$2, 'kefir_07');
    });

    test('esDeColeccion distingue IDs de colección de catálogo y UUIDs',
        () {
      expect(FavoritoColeccion.esDeColeccion('col:jugos:jugos_01'), isTrue);
      expect(
        FavoritoColeccion.esDeColeccion('digestivo_remedio_x'),
        isFalse,
      );
      expect(
        FavoritoColeccion.esDeColeccion('7f3a9c2e-1b4d-4e8a-9c21-aa55d3e2f0b1'),
        isFalse,
      );
    });

    test('IDs mal formados devuelven null sin petar', () {
      expect(FavoritoColeccion.descomponer('col:'), isNull);
      expect(FavoritoColeccion.descomponer('col:jugos'), isNull);
      expect(FavoritoColeccion.descomponer('col::jugos_01'), isNull);
      expect(FavoritoColeccion.descomponer('col:jugos:'), isNull);
      expect(FavoritoColeccion.descomponer(''), isNull);
    });
  });
}