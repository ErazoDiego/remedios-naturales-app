import 'package:flutter/material.dart';
import '../../data/models/receta_usuario.dart';
import '../../data/services/recetas_usuario_service.dart';

/// Provider del estado de "Mis Recetas" (recetas propias del usuario).
///
/// Delega toda la lógica de datos en RecetasUsuarioService y expone
/// estado de UI: lista, loading, error y estado de guardado.
class MisRecetasProvider extends ChangeNotifier {
  final RecetasUsuarioService _service;

  MisRecetasProvider({RecetasUsuarioService? service})
      : _service = service ?? RecetasUsuarioService();

  List<RecetaUsuario> _recetas = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Getters públicos (solo lectura)
  List<RecetaUsuario> get recetas => List.unmodifiable(_recetas);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get isLoggedIn => _service.isLoggedIn;

  /// Carga la lista de recetas propias (usa el cache del servicio si
  /// ya fue cargada en esta sesión).
  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recetas = await _service.getMisRecetas();
    } catch (e) {
      _error = 'No se pudieron cargar tus recetas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea una receta nueva. Devuelve true si fue exitoso.
  Future<bool> crear(RecetaUsuario draft) async {
    _error = null;
    _isSaving = true;
    notifyListeners();

    try {
      final creada = await _service.crear(draft);
      _recetas = [creada, ..._recetas];
      return true;
    } catch (e) {
      _error = 'No se pudo guardar la receta: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Actualiza una receta existente. Devuelve true si fue exitoso.
  Future<bool> actualizar(RecetaUsuario receta) async {
    _error = null;
    _isSaving = true;
    notifyListeners();

    try {
      await _service.actualizar(receta);
      final index = _recetas.indexWhere((r) => r.id == receta.id);
      if (index >= 0) {
        final updated = [..._recetas];
        updated[index] = receta;
        _recetas = updated;
      }
      return true;
    } catch (e) {
      _error = 'No se pudo actualizar la receta: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Elimina una receta. Devuelve true si fue exitoso.
  Future<bool> eliminar(String id) async {
    _error = null;
    notifyListeners();

    try {
      await _service.eliminar(id);
      _recetas = _recetas.where((r) => r.id != id).toList();
      return true;
    } catch (e) {
      _error = 'No se pudo eliminar la receta: $e';
      notifyListeners();
      return false;
    }
  }

  /// Limpia el estado (al cerrar sesión / cambiar de usuario).
  void clear() {
    _recetas = [];
    _error = null;
    _isLoading = false;
    _isSaving = false;
    _service.invalidateCache();
    notifyListeners();
  }
}
