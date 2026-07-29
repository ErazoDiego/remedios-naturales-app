import 'package:flutter/material.dart';
import '../../data/models/receta.dart';
import '../../data/models/sistema_corporal.dart';
import '../../data/services/recetas_service.dart';

/// Provider para manejar el estado de las recetas en la UI
/// Responsabilidades: solo estado de UI, delega lógica al servicio
class RecetasProvider extends ChangeNotifier {
  final RecetasService _service;

  RecetasProvider({RecetasService? service}) : _service = service ?? RecetasService();

  // Estado de UI
  List<SistemaCorporal> _sistemas = [];
  SistemaCorporal? _currentSistema;
  Receta? _currentReceta;
  List<RecetaResult> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  // Getters públicos (solo lectura)
  List<SistemaCorporal> get sistemas => _sistemas;
  SistemaCorporal? get currentSistema => _currentSistema;
  Receta? get currentReceta => _currentReceta;
  List<RecetaResult> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga todos los sistemas corporales
  Future<void> loadSistemas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sistemas = await _service.getSistemas();
    } catch (e) {
      _error = 'Error al cargar los sistemas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga un sistema específico por ID
  Future<void> loadSistema(String sistemaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSistema = await _service.getSistemaById(sistemaId);
      if (_currentSistema == null) {
        _error = 'Sistema no encontrado: $sistemaId';
      }
    } catch (e) {
      _error = 'Error al cargar el sistema: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga una receta específica por ID
  Future<void> loadReceta(String recetaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentReceta = await _service.getRecetaById(recetaId);
      if (_currentReceta == null) {
        _error = 'Receta no encontrada: $recetaId';
      }
    } catch (e) {
      _error = 'Error al cargar la receta: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca recetas por texto
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _service.search(query);
    } catch (e) {
      _error = 'Error en la búsqueda: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia los resultados de búsqueda
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  /// Resuelve una lista de IDs a un mapa de id → nombre
  Future<Map<String, String>> getRecetasNamesByIds(List<String> ids) async {
    return _service.getRecetasNamesByIds(ids);
  }

  /// Obtiene recetas completas por una lista de IDs
  Future<List<Receta>> getRecetasByIds(List<String> ids) async {
    return _service.getRecetasByIds(ids);
  }
}
