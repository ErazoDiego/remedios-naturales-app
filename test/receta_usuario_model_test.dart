import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/data/models/receta_usuario.dart';

void main() {
  group('RecetaUsuario.fromJson', () {
    test('mapea snake_case de PostgREST a camelCase', () {
      final json = {
        'id': '11111111-2222-3333-4444-555555555555',
        'usuario_id': 'user-123',
        'nombre': 'Jarabe de jengibre',
        'descripcion': 'Para la garganta',
        'ideal_para': ['tos', 'garganta'],
        'tipo': 'remedio casero',
        'tipo_preparacion': 'jarabe',
        'cuando_usar': 'Ante los primeros síntomas',
        'precaucion': 'No en embarazadas',
        'ingredientes': ['jengibre', 'miel'],
        'preparacion': ['Rallar', 'Mezclar'],
        'dosis': '1 cucharada',
        'almacenamiento': 'Frasco cerrado',
        'imagen': null,
        'imagen_placeholder': null,
        'creado_at': '2026-08-07T12:00:00.000Z',
        'actualizado_at': '2026-08-07T13:30:00.000Z',
      };

      final receta = RecetaUsuario.fromJson(json);

      expect(receta.id, json['id']);
      expect(receta.usuarioId, 'user-123');
      expect(receta.nombre, 'Jarabe de jengibre');
      expect(receta.idealPara, ['tos', 'garganta']);
      expect(receta.tipoPreparacion, 'jarabe');
      expect(receta.cuandoUsar, 'Ante los primeros síntomas');
      expect(receta.ingredientes, ['jengibre', 'miel']);
      expect(receta.preparacion, ['Rallar', 'Mezclar']);
      expect(receta.creadoAt, DateTime.parse('2026-08-07T12:00:00.000Z'));
      expect(receta.actualizadoAt, DateTime.parse('2026-08-07T13:30:00.000Z'));
    });

    test('tolera valores nulos y arrays vacíos', () {
      final receta = RecetaUsuario.fromJson({
        'id': 'x',
        'usuario_id': 'user-1',
        'nombre': 'Solo nombre',
        'creado_at': null,
        'actualizado_at': null,
      });

      expect(receta.descripcion, '');
      expect(receta.idealPara, isEmpty);
      expect(receta.cuandoUsar, isNull);
      expect(receta.precaucion, '');
      expect(receta.ingredientes, isEmpty);
      expect(receta.preparacion, isEmpty);
      expect(receta.dosis, '');
      expect(receta.almacenamiento, '');
      expect(receta.imagen, isNull);
      expect(receta.imagenPlaceholder, isNull);
      expect(receta.creadoAt, isNull);
      expect(receta.actualizadoAt, isNull);
    });
  });

  group('RecetaUsuario.toJson', () {
    test('mapea a snake_case y EXCLUYE id, usuario_id y fechas (los genera la DB)',
        () {
      final receta = RecetaUsuario(
        id: '11111111-2222-3333-4444-555555555555',
        usuarioId: 'user-123',
        nombre: 'Infusión de manzanilla',
        descripcion: 'Relajante',
        idealPara: ['insomnio'],
        tipo: 'té',
        tipoPreparacion: 'infusión',
        cuandoUsar: 'Antes de dormir',
        precaucion: 'No combinar con sedantes',
        ingredientes: ['manzanilla', 'agua'],
        preparacion: ['Hervir', 'Reposar'],
        dosis: '1 taza',
        almacenamiento: 'Consumir al momento',
        creadoAt: DateTime.parse('2026-08-07T12:00:00.000Z'),
        actualizadoAt: DateTime.parse('2026-08-07T13:30:00.000Z'),
      );

      final json = receta.toJson();

      expect(json['nombre'], 'Infusión de manzanilla');
      expect(json['ideal_para'], ['insomnio']);
      expect(json['tipo_preparacion'], 'infusión');
      expect(json['cuando_usar'], 'Antes de dormir');
      expect(json['ingredientes'], ['manzanilla', 'agua']);
      expect(json['preparacion'], ['Hervir', 'Reposar']);
      // Excluidos: la DB los genera / los maneja el servicio
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('usuario_id'), isFalse);
      expect(json.containsKey('creado_at'), isFalse);
      expect(json.containsKey('actualizado_at'), isFalse);
    });
  });

  group('RecetaUsuario.copyWith', () {
    test('modifica solo los campos indicados', () {
      final base = RecetaUsuario(nombre: 'Original', dosis: '1 cucharada');
      final editada = base.copyWith(nombre: 'Nuevo nombre');

      expect(editada.nombre, 'Nuevo nombre');
      expect(editada.dosis, '1 cucharada');
      expect(editada.id, base.id);
      expect(editada.idealPara, isEmpty);
    });

    test('permite reemplazar listas completas', () {
      final base = RecetaUsuario(
        nombre: 'Base',
        ingredientes: ['a'],
        preparacion: ['1'],
      );
      final editada = base.copyWith(
        ingredientes: ['b', 'c'],
        preparacion: ['2', '3'],
      );

      expect(editada.ingredientes, ['b', 'c']);
      expect(editada.preparacion, ['2', '3']);
    });
  });
}
