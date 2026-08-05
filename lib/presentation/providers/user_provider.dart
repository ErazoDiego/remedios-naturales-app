import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';

/// Provider para manejar el estado del usuario en la UI.
///
/// Responsabilidades:
/// - Escuchar cambios de sesión (onAuthStateChange) y propagarlos a
///   UserService vía setSession.
/// - Migrar los datos del usuario anónimo local a la nube al loguearse.
/// - Exponer estado de UI (profile, loading, error) al resto de la app.
///
/// Toda la lógica de datos delega en UserService (modo dual local/remoto).
class UserProvider extends ChangeNotifier {
  final UserService _service;
  final AuthService _auth;
  StreamSubscription<AuthState>? _authSub;

  UserProvider({UserService? service, AuthService? auth})
      : _service = service ?? UserService(),
        _auth = auth ?? AuthService();

  // Estado de UI
  UserProfile? _profile;
  bool _isLoading = false;
  bool _isInitializing = false;
  String? _error;

  // Getters públicos (solo lectura)
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isLoggedIn => _auth.isLoggedIn;
  String? get userEmail => _auth.currentUser?.email;

  /// Inicializa el provider: aplica la sesión actual (si la hay, por
  /// ejemplo tras reabrir la app con sesión persistida) y escucha los
  /// cambios de auth en adelante.
  Future<void> init() async {
    if (_authSub != null) return; // Ya inicializado

    _isInitializing = true;
    notifyListeners();

    _applySession(_auth.currentUser);
    _authSub = _auth.onAuthStateChange.listen(_onAuthStateChanged);
    await loadProfile();

    _isInitializing = false;
    notifyListeners();
  }

  /// Carga el perfil del usuario actual.
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

  // ═══════════════════════════════════════════════════════════════════
  // AUTENTICACIÓN
  // ═══════════════════════════════════════════════════════════════════

  /// Registra una cuenta nueva.
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signUp(email: email, password: password);
    if (result.success) {
      await _afterSessionEstablished();
    }
    return result;
  }

  /// Inicia sesión con email y contraseña.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signIn(email: email, password: password);
    if (result.success) {
      await _afterSessionEstablished();
    }
    return result;
  }

  /// Cierra la sesión.
  Future<AuthResult> signOut() async {
    final result = await _auth.signOut();
    if (result.success) {
      _applySession(null);
      _profile = null;
      notifyListeners();
    }
    return result;
  }

  /// Lógica post-login/registro:
  /// - Asegura que la sesión esté aplicada al servicio
  /// - Migra los datos anónimos locales a la nube (si había)
  /// - Carga el perfil fresco
  Future<void> _afterSessionEstablished() async {
    _applySession(_auth.currentUser);
    try {
      await _service.migrateLocalToCloud();
    } catch (e) {
      // Si falla la migración (offline), no bloqueamos el login.
      // Los datos locales quedan y se pueden migrar en el próximo sync.
      debugPrint('Migración local→cloud diferida: $e');
    }
    await loadProfile();
  }

  // ═══════════════════════════════════════════════════════════════════
  // FAVORITOS / HISTORIAL / PERFIL
  // ═══════════════════════════════════════════════════════════════════

  /// Agrega una receta a favoritos.
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

  /// Elimina una receta de favoritos.
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

  /// Verifica si una receta está en favoritos.
  Future<bool> isFavorite(String recetaId) async {
    try {
      return await _service.isFavorite(recetaId);
    } catch (e) {
      return false;
    }
  }

  /// Agrega una receta al historial.
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

  /// Actualiza el nombre del usuario.
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

  /// Limpia todos los datos del usuario.
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

  // ═══════════════════════════════════════════════════════════════════
  // INTERNOS
  // ═══════════════════════════════════════════════════════════════════

  void _onAuthStateChanged(AuthState state) {
    _applySession(state.session?.user);
    loadProfile();
  }

  void _applySession(User? user) {
    if (user != null) {
      _service.setSession(userId: user.id, email: user.email);
    } else {
      _service.setSession(userId: null);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
