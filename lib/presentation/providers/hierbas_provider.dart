import 'package:flutter/material.dart';
import '../../data/models/hierba.dart';
import '../../data/services/hierbas_service.dart';

/// Provider para manejar el estado del herbolario en la UI
/// Responsabilidades: solo estado de UI, delega lógica al servicio
class HierbasProvider extends ChangeNotifier {
  final HierbasService _service;

  HierbasProvider({HierbasService? service})
      : _service = service ?? HierbasService();

  // Estado de UI
  List<Hierba> _hierbas = [];
  List<Hierba> _resultados = [];
  List<String> _tagsPopulares = [];
  List<Map<String, dynamic>> _recetasConHierba = [];
  String _busqueda = '';
  String? _tagSeleccionado;
  bool _isLoading = false;
  String? _error;

  // Getters públicos (solo lectura)
  List<Hierba> get hierbas => _hierbas;
  List<Hierba> get resultados => _resultados;
  List<String> get tagsPopulares => _tagsPopulares;
  List<Map<String, dynamic>> get recetasConHierba => _recetasConHierba;
  String get busqueda => _busqueda;
  String? get tagSeleccionado => _tagSeleccionado;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga todas las hierbas y los tags populares
  Future<void> loadHierbas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _hierbas = await _service.getHierbas();
      _tagsPopulares = await _service.getTagsPopulares();
      _resultados = List.of(_hierbas);
    } catch (e) {
      _error = 'Error al cargar el herbolario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aplica búsqueda por texto + filtro por tag
  Future<void> aplicarFiltros({
    String? busqueda,
    String? tag,
  }) async {
    if (busqueda != null) _busqueda = busqueda;
    if (tag != null) _tagSeleccionado = tag;

    final query = _busqueda.trim();
    List<Hierba> base;

    // Si hay tag seleccionado, filtrar primero por tag
    if (_tagSeleccionado != null && _tagSeleccionado!.isNotEmpty) {
      base = await _service.getHierbasByTag(_tagSeleccionado!);
    } else {
      base = List.of(_hierbas);
    }

    // Luego aplicar búsqueda por texto si existe
    if (query.isNotEmpty) {
      base = base.where((h) {
        final queryLower = query.toLowerCase();
        return h.nombre.toLowerCase().contains(queryLower) ||
            h.propiedades.toLowerCase().contains(queryLower) ||
            h.tags.any((t) => t.toLowerCase().contains(queryLower));
      }).toList();
    }

    _resultados = base;
    notifyListeners();
  }

  /// Limpia la búsqueda y el filtro de tag
  Future<void> limpiarFiltros() async {
    _busqueda = '';
    _tagSeleccionado = null;
    _resultados = List.of(_hierbas);
    notifyListeners();
  }

  /// Obtiene las recetas que contienen una hierba
  Future<void> loadRecetasConHierba(String hierbaNombre) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recetasConHierba = await _service.getRecetasConHierba(hierbaNombre);
    } catch (e) {
      _error = 'Error al cargar recetas con la hierba: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resuelve la etiqueta legible de un tag
  String tagLabel(String tag) => _service.tagLabel(tag);
}
