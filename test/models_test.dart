import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/data/models/receta.dart';
import 'package:remedios_naturales_app/data/models/sistema_corporal.dart';
import 'package:remedios_naturales_app/data/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════════
  // REETA MODEL
  // ═══════════════════════════════════════════════════════════════════
  group('Receta', () {
    test('fromJson creates Receta correctly', () {
      final json = {
        'id': 'digestivo_01',
        'nombre': 'Infusión de manzanilla',
        'descripcion': 'Infusión suave para la digestión',
        'idealPara': ['pesadez', 'gases'],
        'tipo': 'interno',
        'tipoPreparacion': 'infusión',
        'cuandoUsar': 'después de comer',
        'precaucion': 'evitar con gastritis',
        'ingredientes': ['manzanilla', 'agua'],
        'preparacion': ['Hervir agua', 'Agregar manzanilla'],
        'dosis': '1 taza',
        'almacenamiento': 'preparar fresca',
        'imagen': 'assets/images/recetas/digestivo_01.webp',
        'imagenPlaceholder': 'assets/images/recetas/digestivo_01_placeholder.webp',
      };

      final receta = Receta.fromJson(json);

      expect(receta.id, 'digestivo_01');
      expect(receta.nombre, 'Infusión de manzanilla');
      expect(receta.descripcion, 'Infusión suave para la digestión');
      expect(receta.idealPara, ['pesadez', 'gases']);
      expect(receta.tipo, 'interno');
      expect(receta.tipoPreparacion, 'infusión');
      expect(receta.cuandoUsar, 'después de comer');
      expect(receta.precaucion, 'evitar con gastritis');
      expect(receta.ingredientes, ['manzanilla', 'agua']);
      expect(receta.preparacion, ['Hervir agua', 'Agregar manzanilla']);
      expect(receta.dosis, '1 taza');
      expect(receta.almacenamiento, 'preparar fresca');
      expect(receta.imagen, 'assets/images/recetas/digestivo_01.webp');
      expect(receta.imagenPlaceholder, 'assets/images/recetas/digestivo_01_placeholder.webp');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'test_02',
        'nombre': 'Test',
        'descripcion': 'Test',
        'idealPara': [],
        'tipo': 'interno',
        'tipoPreparacion': 'infusión',
        'precaucion': 'test',
        'ingredientes': [],
        'preparacion': [],
        'dosis': 'test',
        'almacenamiento': 'test',
      };

      final receta = Receta.fromJson(json);

      expect(receta.cuandoUsar, isNull);
      expect(receta.imagen, isNull);
      expect(receta.imagenPlaceholder, isNull);
      expect(receta.idealPara, isEmpty);
      expect(receta.ingredientes, isEmpty);
    });

    test('toJson creates correct JSON', () {
      final receta = Receta(
        id: 'test_01',
        nombre: 'Test',
        descripcion: 'Test description',
        idealPara: ['test'],
        tipo: 'interno',
        tipoPreparacion: 'infusión',
        precaucion: 'test caution',
        ingredientes: ['test'],
        preparacion: ['test'],
        dosis: 'test',
        almacenamiento: 'test',
        imagen: 'assets/images/recetas/test_01.webp',
      );

      final json = receta.toJson();

      expect(json['id'], 'test_01');
      expect(json['nombre'], 'Test');
      expect(json['idealPara'], ['test']);
      expect(json['tipo'], 'interno');
      expect(json['imagen'], 'assets/images/recetas/test_01.webp');
    });

    test('toString returns readable string', () {
      final receta = Receta(
        id: 'digestivo_01',
        nombre: 'Infusión de manzanilla',
        descripcion: 'Test',
        idealPara: [],
        tipo: 'interno',
        tipoPreparacion: 'infusión',
        precaucion: 'test',
        ingredientes: [],
        preparacion: [],
        dosis: 'test',
        almacenamiento: 'test',
      );

      expect(receta.toString(), 'Receta(id: digestivo_01, nombre: Infusión de manzanilla)');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // SISTEMA CORPORAL MODEL
  // ═══════════════════════════════════════════════════════════════════
  group('SistemaCorporal', () {
    test('fromJson creates SistemaCorporal correctly', () {
      final json = {
        'id': 'digestivo',
        'sistema': 'Sistema Digestivo',
        'emoji': '🫁',
        'totalRecetas': 16,
        'recetas': [
          {
            'id': 'digestivo_01',
            'nombre': 'Test Receta',
            'descripcion': 'Test',
            'idealPara': ['test'],
            'tipo': 'interno',
            'tipoPreparacion': 'infusión',
            'precaucion': 'test',
            'ingredientes': ['test'],
            'preparacion': ['test'],
            'dosis': 'test',
            'almacenamiento': 'test',
          }
        ],
      };

      final sistema = SistemaCorporal.fromJson(json);

      expect(sistema.id, 'digestivo');
      expect(sistema.nombre, 'Sistema Digestivo');
      expect(sistema.emoji, '🫁');
      expect(sistema.totalRecetas, 16);
      expect(sistema.recetas.length, 1);
      expect(sistema.recetas.first.id, 'digestivo_01');
      expect(sistema.recetas.first.nombre, 'Test Receta');
    });

    test('fromJson handles empty recetas list', () {
      final json = {
        'id': 'test',
        'sistema': 'Test',
        'emoji': '🧪',
        'totalRecetas': 0,
        'recetas': [],
      };

      final sistema = SistemaCorporal.fromJson(json);

      expect(sistema.recetas, isEmpty);
      expect(sistema.totalRecetas, 0);
    });

    test('fromJson handles null recetas', () {
      final json = {
        'id': 'test',
        'sistema': 'Test',
        'emoji': '🧪',
        'totalRecetas': 0,
      };

      final sistema = SistemaCorporal.fromJson(json);

      expect(sistema.recetas, isEmpty);
    });

    test('fromJson parses multiple recetas', () {
      final json = {
        'id': 'nervioso',
        'sistema': 'Sistema Nervioso',
        'emoji': '🧠',
        'totalRecetas': 3,
        'recetas': [
          {
            'id': 'nervioso_01',
            'nombre': 'Receta 1',
            'descripcion': 'Desc 1',
            'idealPara': [],
            'tipo': 'interno',
            'tipoPreparacion': 'infusión',
            'precaucion': '',
            'ingredientes': [],
            'preparacion': [],
            'dosis': '',
            'almacenamiento': '',
          },
          {
            'id': 'nervioso_02',
            'nombre': 'Receta 2',
            'descripcion': 'Desc 2',
            'idealPara': [],
            'tipo': 'interno',
            'tipoPreparacion': 'tónico',
            'precaucion': '',
            'ingredientes': [],
            'preparacion': [],
            'dosis': '',
            'almacenamiento': '',
          },
        ],
      };

      final sistema = SistemaCorporal.fromJson(json);

      expect(sistema.recetas.length, 2);
      expect(sistema.recetas[0].id, 'nervioso_01');
      expect(sistema.recetas[1].id, 'nervioso_02');
      expect(sistema.recetas[1].tipoPreparacion, 'tónico');
    });

    test('toString returns readable string', () {
      final sistema = SistemaCorporal(
        id: 'digestivo',
        nombre: 'Sistema Digestivo',
        emoji: '🫁',
        totalRecetas: 16,
        recetas: [],
      );

      expect(sistema.toString(), 'SistemaCorporal(id: digestivo, nombre: Sistema Digestivo, total: 16)');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // USER PROFILE MODEL
  // ═══════════════════════════════════════════════════════════════════
  group('UserProfile', () {
    test('fromJson creates UserProfile correctly', () {
      final json = {
        'id': 'user123',
        'email': 'test@example.com',
        'nombre': 'Test User',
        'fechaRegistro': '2024-01-15T10:30:00.000',
        'favoritos': ['digestivo_01', 'nervioso_03'],
        'historial': ['digestivo_01', 'cardiovascular_02'],
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'user123');
      expect(profile.email, 'test@example.com');
      expect(profile.nombre, 'Test User');
      expect(profile.favoritos, ['digestivo_01', 'nervioso_03']);
      expect(profile.historial, ['digestivo_01', 'cardiovascular_02']);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'user123',
        'email': '',
        'nombre': 'Test',
        'fechaRegistro': '2024-01-15T10:30:00.000',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.favoritos, isEmpty);
      expect(profile.historial, isEmpty);
    });

    test('toJson creates correct JSON', () {
      final profile = UserProfile(
        id: 'user123',
        email: 'test@example.com',
        nombre: 'Test User',
        fechaRegistro: DateTime(2024, 1, 15, 10, 30, 0),
        favoritos: ['digestivo_01'],
        historial: ['nervioso_01'],
      );

      final json = profile.toJson();

      expect(json['id'], 'user123');
      expect(json['email'], 'test@example.com');
      expect(json['nombre'], 'Test User');
      expect(json['favoritos'], ['digestivo_01']);
      expect(json['historial'], ['nervioso_01']);
    });

    test('copyWith preserves unchanged fields', () {
      final profile = UserProfile(
        id: 'user123',
        email: 'test@example.com',
        nombre: 'Old Name',
        fechaRegistro: DateTime(2024, 1, 15),
        favoritos: ['digestivo_01'],
        historial: ['nervioso_01'],
      );

      final updated = profile.copyWith(nombre: 'New Name');

      expect(updated.id, 'user123');
      expect(updated.email, 'test@example.com');
      expect(updated.nombre, 'New Name');
      expect(updated.favoritos, ['digestivo_01']);
      expect(updated.historial, ['nervioso_01']);
    });

    test('copyWith updates favoritos', () {
      final profile = UserProfile(
        id: 'user123',
        email: 'test@example.com',
        nombre: 'Test',
        fechaRegistro: DateTime(2024, 1, 15),
        favoritos: ['digestivo_01'],
        historial: [],
      );

      final updated = profile.copyWith(favoritos: ['digestivo_01', 'nervioso_02']);

      expect(updated.favoritos, ['digestivo_01', 'nervioso_02']);
    });

    test('toString returns readable string', () {
      final profile = UserProfile(
        id: 'user123',
        email: 'test@example.com',
        nombre: 'Test User',
        fechaRegistro: DateTime(2024, 1, 15),
      );

      expect(profile.toString(), 'UserProfile(id: user123, email: test@example.com, nombre: Test User)');
    });
  });
}
