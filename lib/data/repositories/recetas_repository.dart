import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/receta.dart';
import '../models/sistema_corporal.dart';

/// Repositorio de datos que carga las recetas desde los archivos JSON
class RecetasRepository {
  // Singleton
  static final RecetasRepository _instance = RecetasRepository._internal();
  factory RecetasRepository() => _instance;
  RecetasRepository._internal();

  // Cache de datos cargados
  List<SistemaCorporal>? _sistemas;
  Set<String>? _condicionesIndex;

  /// IDs de los sistemas corporales
  static const List<String> sistemasIds = [
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

  /// Carga todos los sistemas corporales desde los assets
  Future<List<SistemaCorporal>> getSistemas() async {
    if (_sistemas != null) return _sistemas!;

    List<SistemaCorporal> sistemas = [];

    for (final sistemaId in sistemasIds) {
      final jsonStr = await rootBundle.loadString('assets/data/$sistemaId.json');
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      sistemas.add(SistemaCorporal.fromJson(jsonMap));
    }

    _sistemas = sistemas;
    return sistemas;
  }

  /// Obtiene un sistema corporal por su ID
  Future<SistemaCorporal?> getSistemaById(String id) async {
    final sistemas = await getSistemas();
    try {
      return sistemas.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Obtiene una receta por su ID (formato: sistema_numero)
  Future<Receta?> getRecetaById(String id) async {
    final sistemas = await getSistemas();
    for (final sistema in sistemas) {
      try {
        return sistema.recetas.firstWhere((r) => r.id == id);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Busca recetas por nombre o contenido
  Future<List<Receta>> buscarRecetas(String query) async {
    if (query.trim().isEmpty) return [];

    final sistemas = await getSistemas();
    final queryLower = query.toLowerCase();
    List<Receta> resultados = [];

    for (final sistema in sistemas) {
      for (final receta in sistema.recetas) {
        if (_matchesQuery(receta, queryLower)) {
          resultados.add(receta);
        }
      }
    }

    return resultados;
  }

  /// Busca recetas por condición/síntoma
  Future<List<Receta>> getRecetasByCondicion(String condicion) async {
    final sistemas = await getSistemas();
    final condicionLower = condicion.toLowerCase();
    List<Receta> resultados = [];

    for (final sistema in sistemas) {
      for (final receta in sistema.recetas) {
        if (receta.idealPara.any((c) => c.toLowerCase().contains(condicionLower))) {
          resultados.add(receta);
        }
      }
    }

    return resultados;
  }

  /// Obtiene todas las recetas de un sistema específico
  Future<List<Receta>> getRecetasBySistema(String sistemaId) async {
    final sistema = await getSistemaById(sistemaId);
    return sistema?.recetas ?? [];
  }

  /// Carga el índice de condiciones para búsqueda rápida
  Future<Set<String>> getCondicionesIndex() async {
    if (_condicionesIndex != null) return _condicionesIndex!;

    final jsonStr = await rootBundle.loadString('assets/data/condiciones_index.json');
    final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
    final condicionesList = jsonMap['condiciones'] as List<dynamic>;

    final condiciones = condicionesList
        .map((c) => (c as String).toLowerCase())
        .toSet();

    _condicionesIndex = condiciones;
    return condiciones;
  }

  /// Busca recetas por condición usando el índice predefinido
  Future<List<Receta>> searchByCondition(String condition) async {
    final index = await getCondicionesIndex();
    final conditionLower = condition.toLowerCase();

    // Verificar que la condición existe en el índice
    final matchedCondition = index.contains(conditionLower)
        ? conditionLower
        : index.where((c) => c.contains(conditionLower)).firstOrNull;

    // Buscar recetas que contengan esa condición en idealPara
    final searchQuery = matchedCondition ?? conditionLower;
    final sistemas = await getSistemas();
    List<Receta> resultados = [];

    for (final sistema in sistemas) {
      for (final receta in sistema.recetas) {
        if (receta.idealPara.any((c) => c.toLowerCase().contains(searchQuery))) {
          resultados.add(receta);
        }
      }
    }

    return resultados;
  }

  bool _matchesQuery(Receta receta, String queryLower) {
    return receta.nombre.toLowerCase().contains(queryLower) ||
           receta.descripcion.toLowerCase().contains(queryLower) ||
           receta.idealPara.any((c) => c.toLowerCase().contains(queryLower)) ||
           receta.ingredientes.any((i) => i.toLowerCase().contains(queryLower));
  }
}
