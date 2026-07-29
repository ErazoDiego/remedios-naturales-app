import '../models/receta.dart';
import '../models/sistema_corporal.dart';
import '../repositories/recetas_repository.dart';

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

  /// Busca recetas por texto (nombre, descripción, ingredientes, condiciones)
  /// Retorna resultados ordenados por relevancia
  Future<List<RecetaResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final sistemas = await _repository.getSistemas();
    final queryLower = query.toLowerCase().trim();
    List<RecetaResult> resultados = [];

    for (final sistema in sistemas) {
      // Buscar en nombre del sistema
      if (sistema.nombre.toLowerCase().contains(queryLower) ||
          sistema.id.toLowerCase().contains(queryLower)) {
        resultados.add(RecetaResult(
          id: sistema.id,
          title: '${sistema.emoji} ${sistema.nombre}',
          subtitle: '${sistema.totalRecetas} recetas',
          type: ResultType.sistema,
          sistemaId: sistema.id,
        ));
      }

      // Buscar en recetas
      for (final receta in sistema.recetas) {
        final matchScore = _calculateMatchScore(receta, queryLower);
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

  /// Calcula el score de coincidencia de una receta con un query
  /// 0 = no coincide, Mayor = mejor coincidencia
  int _calculateMatchScore(Receta receta, String queryLower) {
    int score = 0;

    // Coincidencia en nombre (mayor peso)
    if (receta.nombre.toLowerCase().contains(queryLower)) {
      score += 10;
    }

    // Coincidencia en condiciones (medio peso)
    if (receta.idealPara.any((c) => c.toLowerCase().contains(queryLower))) {
      score += 5;
    }

    // Coincidencia en ingredientes (menor peso)
    if (receta.ingredientes.any((i) => i.toLowerCase().contains(queryLower))) {
      score += 2;
    }

    // Coincidencia en descripción (menor peso)
    if (receta.descripcion.toLowerCase().contains(queryLower)) {
      score += 1;
    }

    return score;
  }
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
