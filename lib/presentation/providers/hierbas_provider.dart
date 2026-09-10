import 'package:flutter/material.dart';
import '../../core/utils/text_normalizer.dart';
import '../../data/models/hierba.dart';
import '../../data/models/preparacion_tradicional.dart';
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
  Map<String, PreparacionTradicional> _preparaciones = {};
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

  /// Preparación tradicional de una hierba (null si no tiene)
  PreparacionTradicional? preparacionDe(String id) => _preparaciones[id];

  /// Carga todas las hierbas, tags y preparaciones tradicionales
  Future<void> loadHierbas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _hierbas = await _service.getHierbas();
      _tagsPopulares = await _service.getTagsPopulares();
      _resultados = List.of(_hierbas);
      await loadPreparaciones();
    } catch (e) {
      _error = 'Error al cargar el herbolario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las preparaciones tradicionales en el mapa por ID de hierba
  Future<void> loadPreparaciones() async {
    final lista = await _service.getPreparaciones();
    _preparaciones = {for (final p in lista) p.id: p};
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
      // Mismo criterio que el repo: normaliza tildes/ñ y matchea sobre
      // textoBusqueda (nombre + alias + tags + científico + familia +
      // uso tradicional + precauciones…). "diente de león" encuentra
      // "Amargón (Diente de león)" por alias.
      final q = normalizarTexto(query);
      base = base.where((h) {
        return normalizarTexto(h.textoBusqueda).contains(q);
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

  /// Obtiene las recetas que contienen una hierba (por nombre + alias)
  Future<void> loadRecetasConHierba(Hierba hierba) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recetasConHierba =
          await _service.getRecetasConHierba(hierba.nombre, aliases: hierba.alias);
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
