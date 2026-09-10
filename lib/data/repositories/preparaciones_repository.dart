import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/preparacion_tradicional.dart';

/// Abstracción de la fuente de preparaciones tradicionales.
/// Permite inyectar fakes en tests (mismo patrón DIP que HierbasRepository
/// y RecetasRepository).
abstract class PreparacionesDataSource {
  Future<List<PreparacionTradicional>> getPreparaciones();
}

/// Repositorio que carga las preparaciones tradicionales desde el asset
class PreparacionesRepository implements PreparacionesDataSource {
  // Singleton
  static final PreparacionesRepository _instance =
      PreparacionesRepository._internal();
  factory PreparacionesRepository() => _instance;
  PreparacionesRepository._internal();

  // Cache de datos cargados
  List<PreparacionTradicional>? _preparaciones;

  @override
  Future<List<PreparacionTradicional>> getPreparaciones() async {
    if (_preparaciones != null) return _preparaciones!;

    final jsonStr = await rootBundle
        .loadString('assets/data/preparaciones_tradicionales.json');
    final jsonList = json.decode(jsonStr) as List<dynamic>;

    _preparaciones = jsonList
        .map((json) => PreparacionTradicional.fromJson(json as Map<String, dynamic>))
        .toList();

    return _preparaciones!;
  }
}