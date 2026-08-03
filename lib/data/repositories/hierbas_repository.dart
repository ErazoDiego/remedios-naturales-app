import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hierba.dart';

/// Repositorio de datos que carga las hierbas desde el archivo JSON
class HierbasRepository {
  // Singleton
  static final HierbasRepository _instance = HierbasRepository._internal();
  factory HierbasRepository() => _instance;
  HierbasRepository._internal();

  // Cache de datos cargados
  List<Hierba>? _hierbas;

  /// Carga todas las hierbas del herbolario desde el asset
  Future<List<Hierba>> getHierbas() async {
    if (_hierbas != null) return _hierbas!;

    final jsonStr = await rootBundle.loadString('assets/data/hierbas.json');
    final jsonList = json.decode(jsonStr) as List<dynamic>;

    _hierbas = jsonList
        .map((json) => Hierba.fromJson(json as Map<String, dynamic>))
        .toList();

    return _hierbas!;
  }

  /// Obtiene una hierba por su ID
  Future<Hierba?> getHierbaById(String id) async {
    final hierbas = await getHierbas();
    try {
      return hierbas.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Busca hierbas por nombre o por tag (propiedad)
  Future<List<Hierba>> buscarHierbas(String query) async {
    if (query.trim().isEmpty) return [];

    final hierbas = await getHierbas();
    final queryLower = query.toLowerCase().trim();

    return hierbas.where((h) {
      final nombreMatch = h.nombre.toLowerCase().contains(queryLower);
      final tagMatch = h.tags.any((t) => t.toLowerCase().contains(queryLower));
      final propiedadesMatch =
          h.propiedades.toLowerCase().contains(queryLower);
      return nombreMatch || tagMatch || propiedadesMatch;
    }).toList();
  }

  /// Filtra hierbas por una propiedad (tag) específica
  Future<List<Hierba>> getHierbasByTag(String tag) async {
    final hierbas = await getHierbas();
    return hierbas.where((h) => h.tags.contains(tag)).toList();
  }

  /// Devuelve todos los tags únicos ordenados por frecuencia de uso
  Future<List<String>> getTagsPopulares() async {
    final hierbas = await getHierbas();

    final Map<String, int> tagCount = {};
    for (final h in hierbas) {
      for (final tag in h.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }

    final sorted = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }
}
