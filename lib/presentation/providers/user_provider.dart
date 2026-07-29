import 'package:flutter/material.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/user_service.dart';

/// Provider para manejar el estado del usuario en la UI
/// Responsabilidades: solo estado de UI, delega lógica al servicio
class UserProvider extends ChangeNotifier {
  final UserService _service;

  UserProvider({UserService? service}) : _service = service ?? UserService();

  // Estado de UI
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  // Getters públicos (solo lectura)
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _profile != null && _profile!.email.isNotEmpty;

  /// Carga el perfil del usuario actual
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _service.getCurrentProfile();
    } catch (e) {
      _error = 'Error al cargar el perfil: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega una receta a favoritos
  Future<void> addFavorite(String recetaId) async {
    try {
      await _service.addFavorite(recetaId);
      _profile = await _service.getCurrentProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Error al agregar a favoritos: $e';
      notifyListeners();
    }
  }

  /// Elimina una receta de favoritos
  Future<void> removeFavorite(String recetaId) async {
    try {
      await _service.removeFavorite(recetaId);
      _profile = await _service.getCurrentProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar de favoritos: $e';
      notifyListeners();
    }
  }

  /// Verifica si una receta está en favoritos
  Future<bool> isFavorite(String recetaId) async {
    try {
      return await _service.isFavorite(recetaId);
    } catch (e) {
      return false;
    }
  }

  /// Agrega una receta al historial
  Future<void> addToHistory(String recetaId) async {
    try {
      await _service.addToHistory(recetaId);
      _profile = await _service.getCurrentProfile();
      notifyListeners();
    } catch (e) {
      // No notificar error al usuario por historial
      debugPrint('Error al agregar al historial: $e');
    }
  }

  /// Actualiza el nombre del usuario
  Future<void> updateName(String newName) async {
    try {
      await _service.updateName(newName);
      _profile = await _service.getCurrentProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar el nombre: $e';
      notifyListeners();
    }
  }

  /// Limpia todos los datos del usuario
  Future<void> clearAll() async {
    try {
      await _service.clearAll();
      _profile = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al limpiar datos: $e';
      notifyListeners();
    }
  }
}
