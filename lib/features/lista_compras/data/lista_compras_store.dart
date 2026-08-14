import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/item_lista.dart';

  /// Persistencia local de la lista de compras (SharedPreferences).
  ///
  /// La lista es LOCAL del dispositivo (mismo espíritu offline-first del
  /// cache de la biblioteca): no depende de sesión ni de red. El formato
  /// JSON lo comparten [ListaComprasStore.guardar] y [ListaComprasStore.cargar].
  ///
  /// Las escrituras se SERIALIZAN ([_ultimaEscritura]): el provider dispara
  /// `guardar` fire-and-forget y, sin la cola, las escrituras concurrentes
  /// completan en orden impredecible y puede persistirse un estado viejo.
  /// Encadenando, la última llamada SIEMPRE es la última en escribir.
  class ListaComprasStore {
    static const String _key = 'lista_compras_v1';

    /// Cadena de escrituras pendientes. Cada [guardar] se encola acá.
    Future<void> _ultimaEscritura = Future<void>.value();

  /// Lista completa ([] si nunca se guardó o si el JSON está corrupto).
  Future<List<ItemLista>> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const [];
      final decoded = json.decode(raw) as List<dynamic>;
      return [
        for (final item in decoded)
          ItemLista.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      // Corrupción de datos: devolvemos lista vacía (best-effort, mismo
      // criterio que el cache de la biblioteca).
      return const [];
    }
  }

  Future<void> guardar(List<ItemLista> items) {
    // Snapshot al momento de la llamada: los ItemLista son inmutables,
    // copiar la lista basta para que cada escritura persista SU versión.
    final snapshot = List<ItemLista>.of(items);
    final escritura = _ultimaEscritura.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _key,
          json.encode([for (final item in snapshot) item.toJson()]),
        );
      } catch (_) {
        // Persistencia best-effort: si falla, la lista sigue en memoria.
      }
    });
    _ultimaEscritura = escritura;
    return escritura;
  }
}
