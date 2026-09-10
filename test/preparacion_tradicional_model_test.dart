import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/data/models/preparacion_tradicional.dart';

void main() {
  group('PreparacionTradicional', () {
    test('fromJson parsea todos los campos', () {
      final p = PreparacionTradicional.fromJson({
        'id': 'higuera',
        'parte': 'Hojas, brotes',
        'texto': 'Infusión de hojas para uso hipoglucemiante',
        'modos': ['Infusión', 'Decocción'],
        'dosis': 'Antes de las comidas',
        'advertencia': 'Contraindicada en embarazo',
      });

      expect(p.id, 'higuera');
      expect(p.parte, 'Hojas, brotes');
      expect(p.texto, 'Infusión de hojas para uso hipoglucemiante');
      expect(p.modos, ['Infusión', 'Decocción']);
      expect(p.dosis, 'Antes de las comidas');
      expect(p.advertencia, 'Contraindicada en embarazo');
    });

    test('fromJson usa defaults para campos faltantes', () {
      final p = PreparacionTradicional.fromJson({
        'id': 'x',
        'parte': 'Raíz',
        'texto': 'Decocción',
        'modos': ['Decocción'],
      });

      expect(p.dosis, '');
      expect(p.advertencia, '');
    });

    test('toJson round-trip', () {
      final p = PreparacionTradicional(
        id: 'ajenjo',
        parte: 'Hojas',
        texto: 'Infusión amarga',
        modos: ['Infusión'],
        dosis: 'Después de las comidas',
      );

      final json = p.toJson();
      final p2 = PreparacionTradicional.fromJson(json);
      expect(p2.id, p.id);
      expect(p2.modos, p.modos);
      expect(p2.dosis, p.dosis);
    });
  });
}