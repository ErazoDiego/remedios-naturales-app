import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receta_usuario.dart';
import 'auth_service.dart';

/// Servicio CRUD de recetas propias del usuario (feature premium).
///
/// A diferencia de UserService (modo dual local/remoto), las recetas propias
/// EXISTEN SOLO en la nube: la tabla `recetas_usuario` tiene RLS con
/// auth.uid() — un usuario solo ve/modifica sus propias recetas.
///
/// Requiere sesión iniciada: sin sesión las operaciones lanzan StateError.
///
/// Cache en memoria sincronizado (lección del bug de favoritos): cada
/// mutación actualiza/invalida el cache para que la UI siempre lea el
/// estado fresco.
class RecetasUsuarioService {
  // Singleton
  static final RecetasUsuarioService _instance =
      RecetasUsuarioService._internal();
  factory RecetasUsuarioService() => _instance;
  RecetasUsuarioService._internal();

  /// Cliente Supabase inyectable para tests.
  @visibleForTesting
  SupabaseClient? testClient;

  /// ID de usuario inyectable para tests (evita tocar Supabase.instance).
  @visibleForTesting
  String? testUserId;

  /// Cache en memoria: la lista de "mis recetas" ya cargada.
  List<RecetaUsuario>? _cache;

  SupabaseClient get _client => testClient ?? Supabase.instance.client;

  String get _userId => testUserId ?? AuthService().currentUser?.id ?? '';

  bool get isLoggedIn => _userId.isNotEmpty;

  /// Regex de UUID v4 (formato 8-4-4-4-12 hex).
  /// Los IDs de recetas propias son UUIDs que genera la DB; los del
  /// catálogo son legibles ("digestivo_remedio_x"). Esto permite
  /// distinguir en Favoritos qué id resolver dónde.
  static final RegExp _uuidRegex =
      RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
          r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  /// True si el id corresponde a una receta propia (formato UUID).
  static bool isRecetaPropiaId(String id) => _uuidRegex.hasMatch(id);

  /// Invalida el cache (logout / cambio de usuario).
  void invalidateCache() {
    _cache = null;
  }

  // ═══════════════════════════════════════════════════════════════════
  // READ
  // ═══════════════════════════════════════════════════════════════════

  /// Obtiene las recetas del usuario, ordenadas por última actualización.
  ///
  /// La RLS filtra por auth.uid(): no hace falta un `.eq('usuario_id', ...)`
  /// explícito — la base es la autoridad.
  Future<List<RecetaUsuario>> getMisRecetas() async {
    _requireSession();
    if (_cache != null) return _cache!;

    final data = await _client
        .from('recetas_usuario')
        .select()
        .order('actualizado_at', ascending: false);

    _cache = data.map(RecetaUsuario.fromJson).toList();
    return _cache!;
  }

  /// Obtiene una receta por id (la RLS garantiza que sea del usuario).
  Future<RecetaUsuario> getReceta(String id) async {
    _requireSession();
    final data = await _client
        .from('recetas_usuario')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) {
      throw StateError('La receta no existe o fue eliminada');
    }
    return RecetaUsuario.fromJson(data);
  }

  // ═══════════════════════════════════════════════════════════════════
  // WRITE
  // ═══════════════════════════════════════════════════════════════════

  /// Crea una receta nueva. La DB genera id/creado_at y la política RLS
  /// valida el dueño (auth.uid() = usuario_id).
  Future<RecetaUsuario> crear(RecetaUsuario draft) async {
    _requireSession();

    final data = await _client
        .from('recetas_usuario')
        .insert({
          ...draft.toJson(),
          'usuario_id': _userId,
        })
        .select()
        .single();

    final creada = RecetaUsuario.fromJson(data);
    // Mantener el cache sincronizado: la receta nueva va al frente
    // (es la más reciente).
    _cache = [creada, ...?_cache];
    return creada;
  }

  /// Actualiza una receta existente (by id). La RLS impide editar ajenas.
  ///
  /// Nota: la tabla no tiene trigger de updated_at, así que el servicio
  /// setea `actualizado_at` explícitamente para que el orden
  /// "más recientes primero" siga siendo correcto tras editar.
  Future<void> actualizar(RecetaUsuario receta) async {
    _requireSession();
    if (receta.id.isEmpty) {
      throw StateError('La receta no tiene id');
    }

    await _client.from('recetas_usuario').update({
      ...receta.toJson(),
      'actualizado_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', receta.id);

    // Actualizar el cache en memoria con la versión editada
    final index = _cache?.indexWhere((r) => r.id == receta.id) ?? -1;
    if (index >= 0) {
      _cache![index] = receta;
    }
  }

  /// Elimina una receta por id.
  Future<void> eliminar(String id) async {
    _requireSession();
    if (id.isEmpty) {
      throw StateError('La receta no tiene id');
    }

    await _client.from('recetas_usuario').delete().eq('id', id);

    _cache?.removeWhere((r) => r.id == id);
  }

  // ═══════════════════════════════════════════════════════════════════
  // INTERNOS
  // ═══════════════════════════════════════════════════════════════════

  void _requireSession() {
    if (!isLoggedIn) {
      throw StateError(
        'Necesitás iniciar sesión para usar tus recetas propias',
      );
    }
  }
}
