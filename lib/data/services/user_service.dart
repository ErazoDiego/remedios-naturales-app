import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Servicio para persistir datos del usuario (favoritos, historial, perfil)
class UserService {
  // Singleton
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String _profileKey = 'user_profile';
  
  UserProfile? _currentProfile;

  /// Obtiene el perfil actual del usuario
  Future<UserProfile?> getCurrentProfile() async {
    if (_currentProfile != null) return _currentProfile;

    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    
    if (profileJson != null) {
      final jsonMap = json.decode(profileJson) as Map<String, dynamic>;
      _currentProfile = UserProfile.fromJson(jsonMap);
      return _currentProfile;
    }

    // Crear perfil por defecto para usuario anónimo
    _currentProfile = UserProfile(
      id: 'anonymous',
      email: '',
      nombre: 'Usuario',
      fechaRegistro: DateTime.now(),
    );
    return _currentProfile;
  }

  /// Agrega una receta a favoritos
  Future<void> addFavorite(String recetaId) async {
    final profile = await getCurrentProfile();
    if (profile == null) return;

    final newFavoritos = [...profile.favoritos];
    if (!newFavoritos.contains(recetaId)) {
      newFavoritos.add(recetaId);
      _currentProfile = profile.copyWith(favoritos: newFavoritos);
      await _saveProfile();
    }
  }

  /// Elimina una receta de favoritos
  Future<void> removeFavorite(String recetaId) async {
    final profile = await getCurrentProfile();
    if (profile == null) return;

    final newFavoritos = profile.favoritos.where((id) => id != recetaId).toList();
    _currentProfile = profile.copyWith(favoritos: newFavoritos);
    await _saveProfile();
  }

  /// Verifica si una receta está en favoritos
  Future<bool> isFavorite(String recetaId) async {
    final profile = await getCurrentProfile();
    return profile?.favoritos.contains(recetaId) ?? false;
  }

  /// Obtiene la lista de IDs de recetas favoritas
  Future<List<String>> getFavorites() async {
    final profile = await getCurrentProfile();
    return profile?.favoritos ?? [];
  }

  /// Agrega una receta al historial de vistas
  Future<void> addToHistory(String recetaId) async {
    final profile = await getCurrentProfile();
    if (profile == null) return;

    final newHistorial = [recetaId, ...profile.historial.where((id) => id != recetaId)];
    // Mantener solo las últimas 50 entradas
    if (newHistorial.length > 50) {
      newHistorial.removeRange(50, newHistorial.length);
    }

    _currentProfile = profile.copyWith(historial: newHistorial);
    await _saveProfile();
  }

  /// Obtiene el historial de recetas vistas
  Future<List<String>> getHistory() async {
    final profile = await getCurrentProfile();
    return profile?.historial ?? [];
  }

  /// Actualiza el nombre del usuario
  Future<void> updateName(String newName) async {
    final profile = await getCurrentProfile();
    if (profile == null) return;

    _currentProfile = profile.copyWith(nombre: newName);
    await _saveProfile();
  }

  /// Limpia todos los datos del usuario
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    _currentProfile = null;
  }

  Future<void> _saveProfile() async {
    if (_currentProfile == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final profileJson = json.encode(_currentProfile!.toJson());
    await prefs.setString(_profileKey, profileJson);
  }
}
