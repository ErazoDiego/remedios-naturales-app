import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/data/models/receta.dart';
import 'package:remedios_naturales_app/data/models/sistema_corporal.dart';
import 'package:remedios_naturales_app/data/repositories/recetas_repository.dart';
import 'package:remedios_naturales_app/data/services/recetas_service.dart';

/// Implementación de RecetasRepository con datos en memoria para tests
class InMemoryRecetasRepository implements RecetasRepository {
  final List<SistemaCorporal> _sistemas;

  InMemoryRecetasRepository(this._sistemas);

  @override
  Future<List<SistemaCorporal>> getSistemas() async => _sistemas;

  @override
  Future<SistemaCorporal?> getSistemaById(String id) async {
    try {
      return _sistemas.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Receta?> getRecetaById(String id) async {
    for (final sistema in _sistemas) {
      for (final receta in sistema.recetas) {
        if (receta.id == id) return receta;
      }
    }
    return null;
  }

  @override
  Future<List<Receta>> getRecetasBySistema(String sistemaId) async {
    final sistema = await getSistemaById(sistemaId);
    return sistema?.recetas ?? [];
  }

  @override
  Future<List<Receta>> getRecetasByCondicion(String condicion) async {
    final condicionLower = condicion.toLowerCase();
    List<Receta> resultados = [];
    for (final sistema in _sistemas) {
      for (final receta in sistema.recetas) {
        if (receta.idealPara.any((c) => c.toLowerCase().contains(condicionLower))) {
          resultados.add(receta);
        }
      }
    }
    return resultados;
  }

  @override
  Future<List<Receta>> buscarRecetas(String query) async {
    if (query.trim().isEmpty) return [];
    final queryLower = query.toLowerCase();
    List<Receta> resultados = [];
    for (final sistema in _sistemas) {
      for (final receta in sistema.recetas) {
        if (receta.nombre.toLowerCase().contains(queryLower) ||
            receta.descripcion.toLowerCase().contains(queryLower) ||
            receta.idealPara.any((c) => c.toLowerCase().contains(queryLower)) ||
            receta.ingredientes.any((i) => i.toLowerCase().contains(queryLower))) {
          resultados.add(receta);
        }
      }
    }
    return resultados;
  }

  @override
  Future<Set<String>> getCondicionesIndex() async => {};

  @override
  Future<List<Receta>> searchByCondition(String condition) async {
    return getRecetasByCondicion(condition);
  }
}

/// Helper para crear datos de prueba
Receta _createReceta({
  required String id,
  required String nombre,
  String? descripcion,
  List<String>? idealPara,
  List<String>? ingredientes,
}) {
  return Receta(
    id: id,
    nombre: nombre,
    descripcion: descripcion ?? '',
    idealPara: idealPara ?? [],
    tipo: 'interno',
    tipoPreparacion: 'infusión',
    precaucion: '',
    ingredientes: ingredientes ?? [],
    preparacion: [],
    dosis: '',
    almacenamiento: '',
  );
}

SistemaCorporal _createSistema({
  required String id,
  required String nombre,
  required List<Receta> recetas,
}) {
  return SistemaCorporal(
    id: id,
    nombre: nombre,
    emoji: '🧪',
    totalRecetas: recetas.length,
    recetas: recetas,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<SistemaCorporal> testSistemas;
  late RecetasService service;

  setUp(() {
    testSistemas = [
      _createSistema(
        id: 'digestivo',
        nombre: 'Sistema Digestivo',
        recetas: [
          _createReceta(
            id: 'digestivo_01',
            nombre: 'Infusión de manzanilla',
            descripcion: 'Infusión suave para la digestión',
            idealPara: ['pesadez', 'gases', 'digestión pesada'],
            ingredientes: ['manzanilla', 'agua hirviendo'],
          ),
          _createReceta(
            id: 'digestivo_02',
            nombre: 'Té de jengibre',
            descripcion: 'Té caliente para el estómago',
            idealPara: ['náuseas', 'malestar estomacal'],
            ingredientes: ['jengibre fresco', 'agua'],
          ),
        ],
      ),
      _createSistema(
        id: 'nervioso',
        nombre: 'Sistema Nervioso',
        recetas: [
          _createReceta(
            id: 'nervioso_01',
            nombre: 'Infusión de valeriana',
            descripcion: 'Infusión para relajarse',
            idealPara: ['insomnio', 'ansiedad', 'estrés'],
            ingredientes: ['valeriana', 'agua'],
          ),
          _createReceta(
            id: 'nervioso_02',
            nombre: 'Aceite de lavanda',
            descripcion: 'Aceite esencial para masajes',
            idealPara: ['tensión', 'dolor de cabeza'],
            ingredientes: ['aceite de lavanda'],
          ),
        ],
      ),
      _createSistema(
        id: 'respiratorio',
        nombre: 'Sistema Respiratorio',
        recetas: [
          _createReceta(
            id: 'respiratorio_01',
            nombre: 'Vapor de eucalipto',
            descripcion: 'Inhalación para congestión',
            idealPara: ['congestión', 'resfriado'],
            ingredientes: ['eucalipto', 'agua caliente'],
          ),
        ],
      ),
    ];

    final mockRepository = InMemoryRecetasRepository(testSistemas);
    service = RecetasService(repository: mockRepository);
  });

  // ═══════════════════════════════════════════════════════════════════
  // BÚSQUEDA POR TEXTO
  // ═══════════════════════════════════════════════════════════════════
  group('search', () {
    test('returns empty list for empty query', () async {
      final results = await service.search('');
      expect(results, isEmpty);
    });

    test('returns empty list for whitespace-only query', () async {
      final results = await service.search('   ');
      expect(results, isEmpty);
    });

    test('returns empty list when no matches found', () async {
      final results = await service.search('xyz123');
      expect(results, isEmpty);
    });

    test('finds recipe by name', () async {
      final results = await service.search('manzanilla');

      expect(results.length, 1);
      expect(results.first.id, 'digestivo_01');
      expect(results.first.title, 'Infusión de manzanilla');
      expect(results.first.score, greaterThan(0));
    });

    test('finds recipe by condition', () async {
      final results = await service.search('insomnio');

      expect(results.length, 1);
      expect(results.first.id, 'nervioso_01');
    });

    test('finds recipe by ingredient', () async {
      final results = await service.search('lavanda');

      expect(results.length, 1);
      expect(results.first.id, 'nervioso_02');
    });

    test('finds recipe by description', () async {
      final results = await service.search('congestión');

      expect(results.length, 1);
      expect(results.first.id, 'respiratorio_01');
    });

    test('finds sistema by name', () async {
      final results = await service.search('digestivo');

      expect(results.isNotEmpty, true);
      final sistemaResult = results.firstWhere(
        (r) => r.type == ResultType.sistema,
        orElse: () => results.first,
      );
      expect(sistemaResult.id, 'digestivo');
    });

    test('returns results sorted by score', () async {
      final results = await service.search('manzanilla');

      expect(results.length, greaterThanOrEqualTo(1));
      final nameMatch = results.firstWhere((r) => r.id == 'digestivo_01');
      expect(nameMatch.score, greaterThanOrEqualTo(10));
    });

    test('limits results to 10', () async {
      final results = await service.search('e');
      expect(results.length, lessThanOrEqualTo(10));
    });

    test('case-insensitive search', () async {
      final results1 = await service.search('Manzanilla');
      final results2 = await service.search('MANZANILLA');
      final results3 = await service.search('manzanilla');

      expect(results1.length, results2.length);
      expect(results2.length, results3.length);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // OBTENER RECETA POR ID
  // ═══════════════════════════════════════════════════════════════════
  group('getRecetaById', () {
    test('returns receta when found', () async {
      final receta = await service.getRecetaById('digestivo_01');

      expect(receta, isNotNull);
      expect(receta!.id, 'digestivo_01');
      expect(receta.nombre, 'Infusión de manzanilla');
    });

    test('returns null when not found', () async {
      final receta = await service.getRecetaById('nonexistent_01');
      expect(receta, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // OBTENER SISTEMA POR ID
  // ═══════════════════════════════════════════════════════════════════
  group('getSistemaById', () {
    test('returns sistema when found', () async {
      final sistema = await service.getSistemaById('digestivo');

      expect(sistema, isNotNull);
      expect(sistema!.id, 'digestivo');
      expect(sistema.recetas.length, 2);
    });

    test('returns null when not found', () async {
      final sistema = await service.getSistemaById('nonexistent');
      expect(sistema, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // OBTENER RECETAS POR SISTEMA
  // ═══════════════════════════════════════════════════════════════════
  group('getRecetasBySistema', () {
    test('returns recetas for valid sistema', () async {
      final recetas = await service.getRecetasBySistema('digestivo');

      expect(recetas.length, 2);
      expect(recetas[0].id, 'digestivo_01');
      expect(recetas[1].id, 'digestivo_02');
    });

    test('returns empty list for invalid sistema', () async {
      final recetas = await service.getRecetasBySistema('nonexistent');
      expect(recetas, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // RESOLVER IDs A NOMBRES
  // ═══════════════════════════════════════════════════════════════════
  group('getRecetasNamesByIds', () {
    test('resolves valid IDs to names', () async {
      final ids = ['digestivo_01', 'nervioso_02'];
      final names = await service.getRecetasNamesByIds(ids);

      expect(names.length, 2);
      expect(names['digestivo_01'], 'Infusión de manzanilla');
      expect(names['nervioso_02'], 'Aceite de lavanda');
    });

    test('skips invalid IDs', () async {
      final ids = ['digestivo_01', 'nonexistent_01'];
      final names = await service.getRecetasNamesByIds(ids);

      expect(names.length, 1);
      expect(names.containsKey('digestivo_01'), true);
      expect(names.containsKey('nonexistent_01'), false);
    });

    test('returns empty map for empty list', () async {
      final names = await service.getRecetasNamesByIds([]);
      expect(names, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // BÚSQUEDA POR CONDICIÓN
  // ═══════════════════════════════════════════════════════════════════
  group('searchByCondition', () {
    test('returns recetas matching condition in idealPara', () async {
      final results = await service.searchByCondition('gases');

      expect(results.isNotEmpty, true);
      final manzanilla = results.firstWhere((r) => r.id == 'digestivo_01');
      expect(manzanilla.idealPara, contains('gases'));
    });

    test('returns empty for non-matching condition', () async {
      final results = await service.searchByCondition('xyz123');
      expect(results, isEmpty);
    });
  });
}
