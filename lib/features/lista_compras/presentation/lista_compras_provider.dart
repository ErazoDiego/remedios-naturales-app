import 'package:flutter/foundation.dart';

import '../../../core/utils/ingrediente_normalizer.dart' show normalizarIngrediente;
import '../data/lista_compras_store.dart';
import '../domain/item_lista.dart';

/// Estado de la LISTA DE COMPRAS: agrega ingredientes desde recetas
/// (núcleo, colecciones y recetas propias) y ítems manuales escritos
/// por el usuario; deduplica por token normalizado; persiste en
/// SharedPreferences; exporta a texto plano para compartir.
///
/// La regla de oro del normalizador: la LLAVE une (agrupar/deduplicar),
/// el DATO no miente (las cantidades se listan tal cual, nunca se suman).
class ListaComprasProvider extends ChangeNotifier {
  ListaComprasProvider({ListaComprasStore? store})
      : _store = store ?? ListaComprasStore();

  final ListaComprasStore _store;

  List<ItemLista> _items = const [];
  bool _cargado = false;

  List<ItemLista> get items => _items;

  /// Ítems agrupados (cajones de la lista) — el contador del home.
  int get totalItems => _items.length;

  /// Total de cantidades listadas (suma real de líneas de compra).
  int get totalCantidades =>
      _items.fold(0, (acc, item) => acc + item.cantidades.length);

  bool get cargado => _cargado;

  /// Carga la lista persistida (una vez).
  Future<void> init() async {
    if (_cargado) return;
    _items = await _store.cargar();
    _cargado = true;
    notifyListeners();
  }

  /// Agrega los ingredientes de una receta. Dedupe por token: si el
  /// ingrediente ya está, se acumula la cantidad y la receta.
  void agregarDesdeReceta(String recetaNombre, List<String> ingredientes) {
    for (final ingrediente in ingredientes) {
      _agregar(ingrediente, deReceta: recetaNombre);
    }
    _persistir();
  }

  /// Agrega un ítem escrito a mano. El texto es EL dato (se muestra tal
  /// cual); la llave normalizada decide si agrupa con algo existente.
  void agregarManual(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;
    _agregar(limpio, esManual: true);
    _persistir();
  }

  void _agregar(String ingrediente, {String? deReceta, bool esManual = false}) {
    final token = normalizarIngrediente(ingrediente);
    final index = _items.indexWhere((item) => item.tokenBase == token);

    if (index >= 0) {
      final actual = _items[index];
      // Ítem existente: agrega cantidad/origen sin duplicar.
      final nuevo = actual.agregar(
        ingrediente,
        deReceta: deReceta,
        esManual: esManual,
      );
      _items = [..._items]..[index] = nuevo;
    } else {
      _items = [
        ..._items,
        ItemLista.desdeIngrediente(
          ingrediente,
          esManual: esManual,
          deReceta: deReceta,
        ),
      ];
    }
    notifyListeners();
  }

  /// Alterna el marcado (comprado en el super) de un ítem por su llave.
  void toggleMarcado(String tokenBase) {
    final index = _items.indexWhere((item) => item.tokenBase == tokenBase);
    if (index < 0) return;
    final actual = _items[index];
    _items = [..._items]..[index] = actual.copiarMarcado(!actual.marcado);
    notifyListeners();
    _persistir();
  }

  /// Borra un ítem completo (todas sus cantidades).
  void quitarItem(String tokenBase) {
    _items = _items
        .where((item) => item.tokenBase != tokenBase)
        .toList(growable: false);
    notifyListeners();
    _persistir();
  }

  /// Vacía la lista completa.
  void vaciar() {
    if (_items.isEmpty) return;
    _items = const [];
    notifyListeners();
    _persistir();
  }

  /// Texto plano para compartir por WhatsApp/correo (share_plus).
  String exportarTexto() {
    if (_items.isEmpty) return 'Mi lista de compras está vacía.';

    final buffer = StringBuffer()
      ..writeln('🛒 Lista de compras — Yuyo')
      ..writeln();

    for (final item in _items) {
      final estado = item.marcado ? '✅' : '☐';
      buffer.writeln('$estado ${item.nombreMostrable}');
      for (final cantidad in item.cantidades) {
        buffer.writeln('   - $cantidad');
      }
      if (item.deRecetas.isNotEmpty) {
        buffer.writeln('   (${item.deRecetas.join(', ')})');
      }
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  Future<void> _persistir() => _store.guardar(_items);
}
