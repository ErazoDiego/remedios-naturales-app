import '../../core/utils/text_normalizer.dart';
import '../models/receta.dart';
import '../models/sistema_corporal.dart';
import '../repositories/recetas_repository.dart';
import 'search_index.dart';

/// Servicio de lógica de negocio para recetas
/// Contiene la lógica de búsqueda, filtrado y reglas de negocio
class RecetasService {
  final RecetasRepository _repository;

  RecetasService({RecetasRepository? repository})
      : _repository = repository ?? RecetasRepository();

  /// Obtiene todos los sistemas corporales
  Future<List<SistemaCorporal>> getSistemas() async {
    return _repository.getSistemas();
  }

  /// Obtiene un sistema por ID
  Future<SistemaCorporal?> getSistemaById(String id) async {
    return _repository.getSistemaById(id);
  }

  /// Obtiene una receta por ID
  Future<Receta?> getRecetaById(String id) async {
    return _repository.getRecetaById(id);
  }

  /// Busca recetas por texto (nombre, descripción, ingredientes, condiciones
  /// y keywords del índice [SearchIndex]).
  ///
  /// Motor de búsqueda:
  /// 1. Normaliza la query (minúsculas, sin tildes, ñ→n) y la descompone
  ///    en términos (sin stopwords): "Dolor de cabeza" → [dolor, cabeza].
  /// 2. Cada término se expande con sinónimos ([SearchIndex.sinonimosDe]).
  /// 3. Score ponderado por campo: nombre > keywords > idealPara >
  ///    ingredientes > descripción. Suma por término.
  /// Retorna resultados ordenados por relevancia.
  Future<List<RecetaResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final sistemas = await _repository.getSistemas();
    final terminos = SearchIndex.terminosDe(query);
    if (terminos.isEmpty) return [];

    List<RecetaResult> resultados = [];

    for (final sistema in sistemas) {
      // Buscar en nombre del sistema
      final nombreSistema = normalizarTexto(sistema.nombre);
      final idSistema = normalizarTexto(sistema.id);
      final scoreSistema = _calcularScoreCampos(
        terminos,
        [nombreSistema],
        camposLigeros: [idSistema],
      );
      if (scoreSistema > 0) {
        resultados.add(RecetaResult(
          id: sistema.id,
          title: '${sistema.emoji} ${sistema.nombre}',
          subtitle: '${sistema.totalRecetas} recetas',
          type: ResultType.sistema,
          sistemaId: sistema.id,
          score: scoreSistema,
        ));
      }

      // Buscar en recetas
      for (final receta in sistema.recetas) {
        final matchScore = _calculateMatchScore(receta, terminos);
        if (matchScore > 0) {
          resultados.add(RecetaResult(
            id: receta.id,
            title: receta.nombre,
            subtitle: 'Ideal para: ${receta.idealPara.join(", ")}',
            type: ResultType.receta,
            sistemaId: sistema.id,
            score: matchScore,
          ));
        }
      }
    }

    // Ordenar por relevancia (score descendente)
    resultados.sort((a, b) => b.score.compareTo(a.score));
    return resultados.take(10).toList();
  }

  /// Busca recetas por condición/síntoma específico
  Future<List<Receta>> searchByCondition(String condition) async {
    return _repository.getRecetasByCondicion(condition);
  }

  /// Obtiene todas las recetas de un sistema
  Future<List<Receta>> getRecetasBySistema(String sistemaId) async {
    return _repository.getRecetasBySistema(sistemaId);
  }

  /// Resuelve una lista de IDs a un mapa de id → nombre
  Future<Map<String, String>> getRecetasNamesByIds(List<String> ids) async {
    final sistemas = await _repository.getSistemas();
    final idsSet = ids.toSet();
    final Map<String, String> names = {};
    for (final sistema in sistemas) {
      for (final receta in sistema.recetas) {
        if (idsSet.contains(receta.id)) {
          names[receta.id] = receta.nombre;
        }
      }
    }
    return names;
  }

  /// Obtiene recetas completas por una lista de IDs
  Future<List<Receta>> getRecetasByIds(List<String> ids) async {
    final sistemas = await _repository.getSistemas();
    final idsSet = ids.toSet();
    final List<Receta> recetas = [];
    for (final sistema in sistemas) {
      for (final receta in sistema.recetas) {
        if (idsSet.contains(receta.id)) {
          recetas.add(receta);
        }
      }
    }
    // Mantener el orden original de los IDs
    final recetasMap = {for (var r in recetas) r.id: r};
    return ids.where((id) => recetasMap.containsKey(id)).map((id) => recetasMap[id]!).toList();
  }

  /// Calcula el score de coincidencia de una receta con los términos.
  /// 0 = no coincide, Mayor = mejor coincidencia.
  ///
  /// Cada término suma el mejor score del campo donde matcheó:
  /// nombre(10) > keywords(8) > idealPara(5) > ingredientes(2) >
  /// descripción(1). Sinónimos: un término matchea si CUALQUIERA de sus
  /// variantes aparece en algún campo.
  int _calculateMatchScore(Receta receta, List<String> terminos) {
    final nombre = normalizarTexto(receta.nombre);
    final descripcion = normalizarTexto(receta.descripcion);
    final idealPara = receta.idealPara.map(normalizarTexto).toList();
    final ingredientes = receta.ingredientes.map(normalizarTexto).toList();
    final keywords = SearchIndex.keywordsDe(receta.id);

    int score = 0;
    for (final termino in terminos) {
      final variantes = SearchIndex.sinonimosDe(termino);
      int mejorPorTermino = 0;

      for (final variante in variantes) {
        if (nombre.contains(variante)) mejorPorTermino = _max(mejorPorTermino, 10);
        if (keywords.any((k) => k.contains(variante)) &&
            variante.length > 1) {
          mejorPorTermino = _max(mejorPorTermino, 8);
        }
        if (idealPara.any((c) => c.contains(variante)) &&
            variante.length > 1) {
          mejorPorTermino = _max(mejorPorTermino, 5);
        }
        if (ingredientes.any((i) => i.contains(variante)) &&
            variante.length > 1) {
          mejorPorTermino = _max(mejorPorTermino, 2);
        }
        if (descripcion.contains(variante) && variante.length > 1) {
          mejorPorTermino = _max(mejorPorTermino, 1);
        }
      }

      score += mejorPorTermino;
    }
    return score;
  }

  /// Score genérico para campos de texto (usa el mismo esquema ponderado).
  int _calcularScoreCampos(
    List<String> terminos,
    List<String> camposPesados, {
    List<String> camposLigeros = const [],
  }) {
    int score = 0;
    for (final termino in terminos) {
      final variantes = SearchIndex.sinonimosDe(termino);
      int mejorPorTermino = 0;
      for (final variante in variantes) {
        for (final campo in camposPesados) {
          if (campo.contains(variante)) mejorPorTermino = _max(mejorPorTermino, 10);
        }
        for (final campo in camposLigeros) {
          if (campo.contains(variante)) mejorPorTermino = _max(mejorPorTermino, 2);
        }
      }
      score += mejorPorTermino;
    }
    return score;
  }

  int _max(int a, int b) => a > b ? a : b;
}

/// Tipo de resultado de búsqueda
enum ResultType {
  sistema,
  receta,
}

/// Modelo de resultado de búsqueda
class RecetaResult {
  final String id;
  final String title;
  final String subtitle;
  final ResultType type;
  final String sistemaId;
  final int score;

  RecetaResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.sistemaId,
    this.score = 0,
  });
}
