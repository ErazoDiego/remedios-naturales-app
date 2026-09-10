import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/data/models/hierba.dart';
import 'package:remedios_naturales_app/data/models/preparacion_tradicional.dart';
import 'package:remedios_naturales_app/data/models/receta.dart';
import 'package:remedios_naturales_app/data/models/sistema_corporal.dart';
import 'package:remedios_naturales_app/data/repositories/hierbas_repository.dart';
import 'package:remedios_naturales_app/data/repositories/preparaciones_repository.dart';
import 'package:remedios_naturales_app/data/repositories/recetas_repository.dart';
import 'package:remedios_naturales_app/data/services/hierbas_service.dart';
import 'package:remedios_naturales_app/data/services/recetas_service.dart';

/// Implementación de HierbasRepository con datos en memoria para tests
class InMemoryHierbasRepository implements HierbasRepository {
  final List<Hierba> _hierbas;

  InMemoryHierbasRepository(this._hierbas);

  @override
  Future<List<Hierba>> getHierbas() async => _hierbas;

  @override
  Future<Hierba?> getHierbaById(String id) async {
    try {
      return _hierbas.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Hierba>> buscarHierbas(String query) async {
    if (query.trim().isEmpty) return [];
    final queryLower = query.toLowerCase().trim();
    return _hierbas
        .where((h) =>
            h.nombre.toLowerCase().contains(queryLower) ||
            h.textoBusqueda.toLowerCase().contains(queryLower) ||
            h.tags.any((t) => t.toLowerCase().contains(queryLower)))
        .toList();
  }

  @override
  Future<List<Hierba>> getHierbasByTag(String tag) async {
    return _hierbas.where((h) => h.tags.contains(tag)).toList();
  }

  @override
  Future<List<String>> getTagsPopulares() async {
    final Map<String, int> tagCount = {};
    for (final h in _hierbas) {
      for (final tag in h.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    final sorted = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }
}

/// Implementación de PreparacionesRepository con datos en memoria para tests
class InMemoryPreparacionesRepo implements PreparacionesRepository {
  final List<PreparacionTradicional> _preparaciones;

  InMemoryPreparacionesRepo(this._preparaciones);

  @override
  Future<List<PreparacionTradicional>> getPreparaciones() async =>
      _preparaciones;
}

/// Implementación de RecetasRepository con datos en memoria para tests
class InMemoryRecetasRepo implements RecetasRepository {
  final List<SistemaCorporal> _sistemas;

  InMemoryRecetasRepo(this._sistemas);

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
        if (receta.idealPara
            .any((c) => c.toLowerCase().contains(condicionLower))) {
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
            receta.idealPara
                .any((c) => c.toLowerCase().contains(queryLower))) {
          resultados.add(receta);
        }
      }
    }
    return resultados;
  }

  @override
  Future<Set<String>> getCondicionesIndex() async => <String>{};

  @override
  Future<List<Receta>> searchByCondition(String condition) async {
    return getRecetasByCondicion(condition);
  }
}

void main() {
  final hierbas = [
    const Hierba(
      id: 'manzanilla',
      nombre: 'Manzanilla',
      usoTradicional: 'Digestiva, sedante, antiinflamatoria',
      tags: ['digestivo', 'sedante'],
    ),
    const Hierba(
      id: 'ortiga',
      nombre: 'Ortiga',
      usoTradicional: 'Diurética, depurativa',
      tags: ['diuretico', 'depurativo'],
    ),
    const Hierba(
      id: 'ginkgo',
      nombre: 'Ginkgo',
      usoTradicional: 'Estimula la circulación cerebral, memoria',
      tags: ['circulacion', 'memoria'],
    ),
    const Hierba(
      id: 'valeriana',
      nombre: 'Valeriana',
      usoTradicional: 'Sedante, para el insomnio',
      tags: ['sedante'],
    ),
  ];

  final recetas = [
    Receta(
      id: 'digestivo_1',
      nombre: 'Infusión de manzanilla',
      descripcion: 'Té digestivo',
      idealPara: ['Dolor de estómago'],
      tipo: 'interno',
      tipoPreparacion: 'infusión',
      precaucion: '',
      ingredientes: ['Manzanilla', 'Menta'],
      preparacion: ['Hervir agua'],
      dosis: '1 taza',
      almacenamiento: '',
    ),
    Receta(
      id: 'respiratorio_1',
      nombre: 'Jarabe de eucalipto',
      descripcion: 'Para la tos',
      idealPara: ['Tos'],
      tipo: 'interno',
      tipoPreparacion: 'jarabe',
      precaucion: '',
      ingredientes: ['Eucalipto', 'Miel'],
      preparacion: ['Mezclar'],
      dosis: '1 cucharada',
      almacenamiento: '',
    ),
  ];

  final sistema = SistemaCorporal(
    id: 'digestivo',
    nombre: 'Sistema Digestivo',
    emoji: '🍃',
    recetas: recetas,
    totalRecetas: recetas.length,
  );

  final sistemaRespiratorio = SistemaCorporal(
    id: 'respiratorio',
    nombre: 'Sistema Respiratorio',
    emoji: '🌿',
    recetas: [recetas[1]],
    totalRecetas: 1,
  );

  group('HierbasService', () {
    late HierbasService service;

    setUp(() {
      service = HierbasService(
        repository: InMemoryHierbasRepository(hierbas),
        recetasService: RecetasService(
          repository: InMemoryRecetasRepo([sistema, sistemaRespiratorio]),
        ),
      );
    });

    test('getHierbas devuelve todas las hierbas ordenadas alfabéticamente',
        () async {
      final result = await service.getHierbas();
      expect(result.length, 4);
      // Orden alfabético: Ginkgo, Manzanilla, Ortiga, Valeriana
      expect(result[0].nombre, 'Ginkgo');
      expect(result[3].nombre, 'Valeriana');
    });

    test('getHierbaById devuelve la hierba correcta', () async {
      final result = await service.getHierbaById('manzanilla');
      expect(result?.nombre, 'Manzanilla');
      expect(result?.tags, contains('digestivo'));
    });

    test('getHierbaById devuelve null si no existe', () async {
      final result = await service.getHierbaById('no_existe');
      expect(result, isNull);
    });

    test('buscarHierbas por nombre', () async {
      final result = await service.buscarHierbas('manzanilla');
      expect(result.length, 1);
      expect(result.first.nombre, 'Manzanilla');
    });

    test('buscarHierbas por propiedad', () async {
      final result = await service.buscarHierbas('diurética');
      expect(result.length, 1);
      expect(result.first.nombre, 'Ortiga');
    });

    test('buscarHierbas con query vacío devuelve todas', () async {
      final result = await service.buscarHierbas('');
      expect(result.length, 4);
    });

    test('buscarHierbas sin coincidencias devuelve lista vacía', () async {
      final result = await service.buscarHierbas('xyzabc');
      expect(result, isEmpty);
    });

    test('getHierbasByTag filtra por propiedad', () async {
      final sedantes = await service.getHierbasByTag('sedante');
      expect(sedantes.length, 2);
      expect(sedantes.map((h) => h.nombre), containsAll(['Manzanilla', 'Valeriana']));
    });

    test('getTagsPopulares ordena por frecuencia', () async {
      final tags = await service.getTagsPopulares();
      // sedante aparece 2 veces → primero
      expect(tags.first, 'sedante');
    });

    test('getRecetasConHierba encuentra recetas por ingrediente', () async {
      final result = await service.getRecetasConHierba('Manzanilla');
      expect(result.length, 1);
      expect(result.first['sistemaId'], 'digestivo');
      expect((result.first['receta'] as Receta).id, 'digestivo_1');
    });

    test('getRecetasConHierba con hierba no usada devuelve vacío', () async {
      final result = await service.getRecetasConHierba('Ginkgo');
      expect(result, isEmpty);
    });

    test('getRecetasConHierba con query vacío devuelve vacío', () async {
      final result = await service.getRecetasConHierba('');
      expect(result, isEmpty);
    });

    test('tagLabel devuelve etiqueta legible', () {
      expect(service.tagLabel('diuretico'), 'Diurético');
      expect(service.tagLabel('desconocido'), 'desconocido');
    });
  });

  group('HierbasService con alias (unificación amargón/diente de león)', () {
    late HierbasService service;

    setUp(() {
      // Replica el caso real: hierba unificada con nombre compuesto + alias
      const hierbaAmargon = Hierba(
        id: 'amargon',
        nombre: 'Amargón (Diente de león)',
        alias: ['Amargón', 'Diente de león'],
        usoTradicional: 'Pérdida de apetito, hepático, flatulencia, digestivo',
        tags: ['depurativo', 'digestivo'],
      );

      final recetaConDiente = Receta(
        id: 'digestivo_diente',
        nombre: 'Infusión hepatoprotectora',
        descripcion: 'Ayuda al hígado',
        idealPara: ['Hígado'],
        tipo: 'interno',
        tipoPreparacion: 'infusión',
        precaucion: '',
        ingredientes: [
          '1 taza de agua',
          '1 cucharadita de hojas de diente de león',
        ],
        preparacion: ['Hervir el agua'],
        dosis: '1 taza',
        almacenamiento: '',
      );

      final recetaConAmargon = Receta(
        id: 'digestivo_amargon',
        nombre: 'Amargón digestivo',
        descripcion: 'Para la digestión',
        idealPara: ['Digestión'],
        tipo: 'interno',
        tipoPreparacion: 'infusión',
        precaucion: '',
        ingredientes: ['Amargón', 'Agua'],
        preparacion: ['Hervir el agua'],
        dosis: '1 taza',
        almacenamiento: '',
      );

      final sistema = SistemaCorporal(
        id: 'digestivo',
        nombre: 'Sistema Digestivo',
        emoji: '🍃',
        recetas: [recetaConDiente, recetaConAmargon],
        totalRecetas: 2,
      );

      service = HierbasService(
        repository: InMemoryHierbasRepository([hierbaAmargon]),
        recetasService: RecetasService(
          repository: InMemoryRecetasRepo([sistema]),
        ),
      );
    });

    test('getRecetasConHierba encuentra recetas por el alias', () async {
      // Replica el flujo del provider: pasa la Hierba completa (nombre + alias).
      const hierba = Hierba(
        id: 'amargon',
        nombre: 'Amargón (Diente de león)',
        alias: ['Amargón', 'Diente de león'],
        usoTradicional: '',
        tags: [],
      );
      final result = await service
          .getRecetasConHierba(hierba.nombre, aliases: hierba.alias);
      // Encuentra la receta cuyo ingrediente dice "diente de león" (alias)
      // y la que dice "Amargón" (alias / nombre corto).
      expect(result.length, 2);
      final ids = result.map((r) => (r['receta'] as Receta).id).toSet();
      expect(ids, containsAll(['digestivo_diente', 'digestivo_amargon']));
    });

    test('getRecetasConHierba sin aliases no encuentra recetas del alias',
        () async {
      // Si alguien llamara sin pasar el alias, solo matchea "amargón (diente
      // de león)" completo dentro de ingredientes → la receta de "diente de
      // león" no matchea y la de "Amargón" tampoco (no contiene el nombre
      // completo). Este test fija el comportamiento: SIEMPRE hay que pasar
      // la Hierba completa (el provider lo hace).
      final result = await service.getRecetasConHierba('Amargón (Diente de león)');
      expect(result, isEmpty);
    });

    test('buscarHierbas encuentra por el nombre compuesto', () async {
      final result = await service.buscarHierbas('diente de león');
      expect(result.length, 1);
      expect(result.first.id, 'amargon');
    });

    test('buscarHierbas encuentra por el alias', () async {
      final result = await service.buscarHierbas('diente');
      expect(result.length, 1);
      expect(result.first.id, 'amargon');
    });
  });

  group('HierbasService con preparaciones tradicionales', () {
    late HierbasService service;

    setUp(() {
      service = HierbasService(
        repository: InMemoryHierbasRepository(const []),
        recetasService: RecetasService(
          repository: InMemoryRecetasRepo(const []),
        ),
        preparacionesRepository: InMemoryPreparacionesRepo(const [
          PreparacionTradicional(
            id: 'higuera',
            parte: 'Hojas, brotes',
            texto: 'Infusión de hojas para uso hipoglucemiante',
            modos: ['Infusión'],
          ),
        ]),
      );
    });

    test('getPreparaciones devuelve las preparaciones del repo', () async {
      final result = await service.getPreparaciones();
      expect(result.length, 1);
      expect(result.first.id, 'higuera');
      expect(result.first.modos, ['Infusión']);
    });

    test('getPreparaciones con repo vacío devuelve lista vacía', () async {
      final vacio = HierbasService(
        repository: InMemoryHierbasRepository(const []),
        recetasService: RecetasService(
          repository: InMemoryRecetasRepo(const []),
        ),
        preparacionesRepository: InMemoryPreparacionesRepo(const []),
      );
      final result = await vacio.getPreparaciones();
      expect(result, isEmpty);
    });
  });
}
