import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de una operación de autenticación.
class AuthResult {
  final bool success;
  final String? error;
  final bool emailConfirmationRequired;

  const AuthResult({
    required this.success,
    this.error,
    this.emailConfirmationRequired = false,
  });
}

/// Servicio de autenticación contra Supabase Auth.
///
/// Responsabilidades:
/// - Sign up / sign in / sign out
/// - Exponer la sesión actual
/// - Notificar cambios de sesión (login/logout) vía stream
///
/// No maneja datos de perfil ni favoritos — eso es de UserService.
class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Cliente Supabase (inyectable para tests).
  ///
  /// Lazy: instanciar AuthService NO toca Supabase.instance. Solo se accede
  /// a `client` cuando se usa de verdad (login, logout, etc.), así los tests
  /// que nunca tocan auth no necesitan inicializar Supabase.
  SupabaseClient? _clientOverride;

  @visibleForTesting
  set client(SupabaseClient value) => _clientOverride = value;

  SupabaseClient get client => _clientOverride ?? Supabase.instance.client;

  /// Stream de cambios de sesión — la UI escucha esto para reaccionar
  Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  /// Usuario autenticado actualmente (null si es anónimo)
  User? get currentUser => client.auth.currentUser;

  /// ¿Hay una sesión activa?
  bool get isLoggedIn => currentUser != null;

  /// Registro con email y contraseña.
  ///
  /// Si el proyecto tiene "Confirm email" habilitado, el usuario queda
  /// pendiente de confirmación y no obtiene sesión hasta confirmar.
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      // Si el backend pidió confirmación de email, no hay sesión aún
      if (response.session == null) {
        return const AuthResult(
          success: true,
          emailConfirmationRequired: true,
        );
      }
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: _humanizeAuthError(e.message));
    } catch (e) {
      return AuthResult(success: false, error: 'Error inesperado: $e');
    }
  }

  /// Login con email y contraseña.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: _humanizeAuthError(e.message));
    } catch (e) {
      return AuthResult(success: false, error: 'Error inesperado: $e');
    }
  }

  /// Cierra la sesión actual.
  Future<AuthResult> signOut() async {
    try {
      await client.auth.signOut();
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: _humanizeAuthError(e.message));
    } catch (e) {
      return AuthResult(success: false, error: 'Error inesperado: $e');
    }
  }

  /// Traduce mensajes crudos de Supabase a algo legible.
  String _humanizeAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos';
    }
    if (message.contains('User already registered')) {
      return 'Ya existe una cuenta con ese email';
    }
    if (message.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirmá tu email antes de iniciar sesión';
    }
    if (message.contains('rate limit')) {
      return 'Demasiados intentos. Esperá unos minutos y probá de nuevo';
    }
    if (message.contains('Unable to validate email')) {
      return 'El formato del email no es válido';
    }
    return message;
  }
}
