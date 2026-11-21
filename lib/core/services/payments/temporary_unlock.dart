import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Desbloqueos temporales obtenidos a cambio de anuncios rewarded.
///
/// Es estado LOCAL del dispositivo y NO forma parte del perfil de pago:
/// se guarda en una key propia para no mezclarse con `mock_payment_*`
/// ni con `user_profile`. Cada entrada es `recipeId → vencimiento`.
///
/// El reloj es inyectable para poder probar el vencimiento a las 24 h
/// sin dormir el test. Las escrituras se serializan (mismo criterio que
/// `ListaComprasStore`) para que la última llamada siempre gane.
class TemporaryUnlockStore {
  static const String key = 'yuyo_unlocks_temporales_v1';
  static const Duration duracion = Duration(hours: 24);
  static const int maxUnlocksActivos = 3;

  TemporaryUnlockStore({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, DateTime> _unlocks = {};
  Future<void> _ultimaEscritura = Future<void>.value();

  /// Carga lo persistido y descarta lo que ya venció.
  Future<void> init() async {
    _unlocks.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw != null) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final vencimiento = DateTime.tryParse(entry.value.toString());
          if (vencimiento != null) {
            _unlocks[entry.key] = vencimiento;
          }
        }
      }
    } catch (_) {
      // JSON corrupto: arrancamos vacío (best-effort, igual que el cache).
      _unlocks.clear();
    }
    _purge();
    await _persist();
  }

  /// IDs con acceso vigente.
  Set<String> get activos {
    _purge();
    return _unlocks.keys.toSet();
  }

  /// ¿Esta receta sigue desbloqueada?
  bool tieneAcceso(String recipeId) {
    _purge();
    final vencimiento = _unlocks[recipeId];
    return vencimiento != null && vencimiento.isAfter(_now());
  }

  /// ¿Se puede registrar esta receta como unlock NUEVO sin pasar el cap?
  ///
  /// Devuelve `false` si ya está activa o si se alcanzó
  /// [maxUnlocksActivos]. Se consulta ANTES de mostrar anuncios para no
  /// quemar 2 ads cuando el usuario ya está en el límite.
  bool puedeRegistrar(String recipeId) {
    _purge();
    return !_unlocks.containsKey(recipeId) &&
        _unlocks.length < maxUnlocksActivos;
  }

  /// Registra un desbloqueo de 24 h.
  ///
  /// Devuelve `false` si se alcanzó [maxUnlocksActivos]. Si la receta ya
  /// estaba activa es idempotente: no extiende el vencimiento ni cuenta
  /// como un unlock nuevo.
  Future<bool> registrar(
    String recipeId, {
    Duration vigencia = TemporaryUnlockStore.duracion,
  }) async {
    _purge();
    if (_unlocks.containsKey(recipeId)) return true;
    if (_unlocks.length >= maxUnlocksActivos) return false;

    _unlocks[recipeId] = _now().add(vigencia);
    await _persist();
    return true;
  }

  /// Limpia todo el estado (se usa al cerrar sesión).
  Future<void> clear() async {
    _unlocks.clear();
    await _persist();
  }

  void _purge() {
    final ahora = _now();
    _unlocks.removeWhere((_, vencimiento) => !vencimiento.isAfter(ahora));
  }

  Future<void> _persist() {
    final snapshot = Map<String, DateTime>.from(_unlocks);
    final escritura = _ultimaEscritura.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          key,
          json.encode({
            for (final entry in snapshot.entries)
              entry.key: entry.value.toIso8601String(),
          }),
        );
      } catch (_) {
        // Persistencia best-effort: el estado sigue vivo en memoria.
      }
    });
    _ultimaEscritura = escritura;
    return escritura;
  }
}
