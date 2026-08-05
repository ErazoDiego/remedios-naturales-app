import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Servicio para persistir datos del usuario (favoritos, historial, perfil).
///
/// Modo DUAL:
/// - SIN sesión (anónimo): todo se guarda en SharedPreferences (offline-first).
/// - CON sesión (logueado): favoritos/historial van a Supabase, con cache
///   local como fallback cuando no hay conexión.
///
/// La sesión la setea UserProvider cuando escucha onAuthStateChange
/// (setSession). El servicio NO escucha streams — es la capa de datos.
class UserService {
  // Singleton
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String _profileKey = 'user_profile';
  static const String _remoteProfileKey = 'user_profile_remote';

  UserProfile? _currentProfile;

  // ── Estado de sesión (lo maneja UserProvider vía setSession) ──
  String? _sessionUserId;
  String? _sessionEmail;

  /// Cliente Supabase inyectable para tests.
  @visibleForTesting
  SupabaseClient? testClient;

  /// Setea la sesión actual. userId null = anónimo.
  /// Lo llama UserProvider cuando cambia el estado de auth.
  void setSession({String? userId, String? email}) {
    _sessionUserId = userId;
    _sessionEmail = email;
    _currentProfile = null; // Invalidar cache: cambia el dueño de los datos
  }

  bool get _isLoggedIn => _sessionUserId != null;
  String get _userId => _sessionUserId ?? 'anonymous';

  SupabaseClient get _client => testClient ?? Supabase.instance.client;

  /// Obtiene el perfil actual del usuario.
  Future<UserProfile?> getCurrentProfile() async {
    if (_currentProfile != null) return _currentProfile;

    if (_isLoggedIn) {
      _currentProfile = await _loadRemoteProfile();
    } else {
      _currentProfile = await _loadLocalProfile();
    }
    return _currentProfile;
  }

  // ═══════════════════════════════════════════════════════════════════
  // FAVORITOS
  // ═══════════════════════════════════════════════════════════════════

  /// Agrega una receta a favoritos.
  Future<void> addFavorite(String recetaId) async {
    if (_isLoggedIn) {
      // Upsert con ignoreDuplicates: si ya está, no se duplica (UNIQUE).
      await _client.from('favoritos').upsert({
        'usuario_id': _userId,
        'receta_id': recetaId,
      }, onConflict: 'usuario_id,receta_id', ignoreDuplicates: true);
      await _refreshRemoteProfile();
      return;
    }

    final profile = await _loadLocalProfile();
    final newFavoritos = [...profile.favoritos];
    if (!newFavoritos.contains(recetaId)) {
      newFavoritos.add(recetaId);
      await _saveLocalProfile(profile.copyWith(favoritos: newFavoritos));
    }
  }

  /// Elimina una receta de favoritos.
  Future<void> removeFavorite(String recetaId) async {
    if (_isLoggedIn) {
      await _client
          .from('favoritos')
          .delete()
          .eq('usuario_id', _userId)
          .eq('receta_id', recetaId);
      await _refreshRemoteProfile();
      return;
    }

    final profile = await _loadLocalProfile();
    final newFavoritos =
        profile.favoritos.where((id) => id != recetaId).toList();
    await _saveLocalProfile(profile.copyWith(favoritos: newFavoritos));
  }

  /// Verifica si una receta está en favoritos.
  Future<bool> isFavorite(String recetaId) async {
    if (_isLoggedIn) {
      try {
        final data = await _client
            .from('favoritos')
            .select('receta_id')
            .eq('usuario_id', _userId)
            .eq('receta_id', recetaId)
            .limit(1);
        return data.isNotEmpty;
      } catch (_) {
        // Offline: usar cache local
        final profile = await _loadLocalRemoteCache();
        return profile?.favoritos.contains(recetaId) ?? false;
      }
    }

    final profile = await _loadLocalProfile();
    return profile.favoritos.contains(recetaId);
  }

  /// Obtiene la lista de IDs de recetas favoritas.
  Future<List<String>> getFavorites() async {
    if (_isLoggedIn) {
      try {
        final data = await _client
            .from('favoritos')
            .select('receta_id')
            .eq('usuario_id', _userId);
        return data.map((row) => row['receta_id'] as String).toList();
      } catch (_) {
        final profile = await _loadLocalRemoteCache();
        return profile?.favoritos ?? [];
      }
    }

    final profile = await _loadLocalProfile();
    return profile.favoritos;
  }

  // ═══════════════════════════════════════════════════════════════════
  // HISTORIAL
  // ═══════════════════════════════════════════════════════════════════

  /// Agrega una receta al historial de vistas.
  Future<void> addToHistory(String recetaId) async {
    if (_isLoggedIn) {
      await _client.from('historial').upsert({
        'usuario_id': _userId,
        'receta_id': recetaId,
        'visto_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'usuario_id,receta_id');
      await _refreshRemoteProfile();
      return;
    }

    final profile = await _loadLocalProfile();
    final newHistorial = [
      recetaId,
      ...profile.historial.where((id) => id != recetaId),
    ];
    if (newHistorial.length > 50) {
      newHistorial.removeRange(50, newHistorial.length);
    }
    await _saveLocalProfile(profile.copyWith(historial: newHistorial));
  }

  /// Obtiene el historial de recetas vistas.
  Future<List<String>> getHistory() async {
    if (_isLoggedIn) {
      try {
        final data = await _client
            .from('historial')
            .select('receta_id')
            .eq('usuario_id', _userId)
            .order('visto_at', ascending: false)
            .limit(50);
        return data.map((row) => row['receta_id'] as String).toList();
      } catch (_) {
        final profile = await _loadLocalRemoteCache();
        return profile?.historial ?? [];
      }
    }

    final profile = await _loadLocalProfile();
    return profile.historial;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PERFIL
  // ═══════════════════════════════════════════════════════════════════

  /// Actualiza el nombre del usuario.
  Future<void> updateName(String newName) async {
    if (_isLoggedIn) {
      await _client.from('perfiles').update({'nombre': newName}).eq('id', _userId);
      await _refreshRemoteProfile();
      return;
    }

    final profile = await _loadLocalProfile();
    await _saveLocalProfile(profile.copyWith(nombre: newName));
  }

  /// Crea el perfil en la tabla `perfiles` (se llama tras el registro).
  Future<void> ensureProfileExists() async {
    if (!_isLoggedIn) return;
    final user = _client.auth.currentUser;
    try {
      await _client.from('perfiles').upsert({
        'id': _userId,
        'nombre': user?.email?.split('@').first ?? 'Usuario',
      }, onConflict: 'id');
    } catch (_) {
      // Si falla (offline), se reintenta en el próximo sync
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MIGRACIÓN ANÓNIMO → CLOUD
  // ═══════════════════════════════════════════════════════════════════

  /// Sube los favoritos/historial del usuario anónimo local a la nube.
  /// Se llama cuando el usuario se registra/inicia sesión con datos locales.
  Future<void> migrateLocalToCloud() async {
    if (!_isLoggedIn) return;

    // Leer el perfil ANÓNIMO guardado en local
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    if (profileJson == null) return;

    final localProfile = UserProfile.fromJson(json.decode(profileJson));

    if (localProfile.favoritos.isNotEmpty) {
      final rows = localProfile.favoritos
          .map((id) => {'usuario_id': _userId, 'receta_id': id})
          .toList();
      await _client.from('favoritos').upsert(
        rows,
        onConflict: 'usuario_id,receta_id',
        ignoreDuplicates: true,
      );
    }

    if (localProfile.historial.isNotEmpty) {
      final rows = localProfile.historial
          .map((id) => {
                'usuario_id': _userId,
                'receta_id': id,
                'visto_at': DateTime.now().toUtc().toIso8601String(),
              })
          .toList();
      await _client.from('historial').upsert(
        rows,
        onConflict: 'usuario_id,receta_id',
      );
    }

    // Limpiar los datos anónimos para que no queden huérfanos
    await prefs.remove(_profileKey);
    _currentProfile = null;
  }

  /// Limpia todos los datos del usuario.
  Future<void> clearAll() async {
    if (_isLoggedIn) {
      try {
        await _client.from('favoritos').delete().eq('usuario_id', _userId);
        await _client.from('historial').delete().eq('usuario_id', _userId);
        await _client.from('perfiles').delete().eq('id', _userId);
      } catch (_) {
        // Offline: no se puede borrar en nube, se ignora
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_remoteProfileKey);
      _currentProfile = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    _currentProfile = null;
  }

  // ═══════════════════════════════════════════════════════════════════
  // INTERNOS
  // ═══════════════════════════════════════════════════════════════════

  /// Perfil anónimo local (SharedPreferences).
  Future<UserProfile> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);

    if (profileJson != null) {
      return UserProfile.fromJson(json.decode(profileJson));
    }
    return UserProfile(
      id: 'anonymous',
      email: '',
      nombre: 'Usuario',
      fechaRegistro: DateTime.now(),
    );
  }

  Future<void> _saveLocalProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, json.encode(profile.toJson()));
  }

  /// Perfil logueado desde Supabase (con cache local como fallback offline).
  Future<UserProfile> _loadRemoteProfile() async {
    try {
      // Datos de la tabla perfiles
      final user = _client.auth.currentUser;
      final perfilRows = await _client
          .from('perfiles')
          .select('nombre, fecha_registro')
          .eq('id', _userId)
          .maybeSingle();

      // Favoritos e historial
      final favRows = await _client
          .from('favoritos')
          .select('receta_id')
          .eq('usuario_id', _userId);
      final histRows = await _client
          .from('historial')
          .select('receta_id')
          .eq('usuario_id', _userId)
          .order('visto_at', ascending: false)
          .limit(50);

      final profile = UserProfile(
        id: _userId,
        email: _sessionEmail ?? user?.email ?? '',
        nombre: (perfilRows?['nombre'] as String?) ?? '',
        fechaRegistro: perfilRows?['fecha_registro'] != null
            ? DateTime.parse(perfilRows!['fecha_registro'].toString())
            : DateTime.now(),
        favoritos: favRows.map((r) => r['receta_id'] as String).toList(),
        historial: histRows.map((r) => r['receta_id'] as String).toList(),
      );

      // Guardar cache local para modo offline
      await _saveRemoteCache(profile);
      return profile;
    } catch (_) {
      // Offline: usar cache local del último perfil logueado
      return await _loadLocalRemoteCache() ??
          UserProfile(
            id: _userId,
            email: _sessionEmail ?? '',
            nombre: 'Usuario',
            fechaRegistro: DateTime.now(),
          );
    }
  }

  Future<void> _refreshRemoteProfile() async {
    _currentProfile = null;
    await _loadRemoteProfile();
    // El cache _currentProfile se actualiza en el próximo getCurrentProfile
  }

  Future<void> _saveRemoteCache(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remoteProfileKey, json.encode(profile.toJson()));
  }

  Future<UserProfile?> _loadLocalRemoteCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_remoteProfileKey);
    if (jsonStr == null) return null;
    return UserProfile.fromJson(json.decode(jsonStr));
  }
}
