import 'package:flutter/material.dart';
import '../../core/services/payments/premium_rules.dart';
import '../../features/biblioteca/data/biblioteca_repository.dart';
import '../../features/biblioteca/domain/coleccion.dart';
import 'premium_provider.dart';

/// Provider del módulo Biblioteca de Colecciones (catálogo + tienda).
///
/// - Catálogo: viene de [BibliotecaRepository] (Supabase público, con
///   cache offline). El contenido es SOLO LECTURA.
/// - Gating: delega en [PremiumProvider] — premium incluye todas las
///   colecciones (presentes y futuras); si no, se necesita el pack de
///   la colección ('yuyo_pack_<coleccionId>').
/// - Precios: se consultan al [PremiumProvider] (fetchProductsFor) y
///   quedan en `productPrices` — una sola fuente para toda la app.
class BibliotecaProvider extends ChangeNotifier {
  final PremiumProvider _premium;
  final BibliotecaRepository _repo;

  BibliotecaProvider({PremiumProvider? premium, BibliotecaRepository? repo})
      : _premium = premium ?? PremiumProvider(),
        _repo = repo ?? BibliotecaRepository() {
    // Los packs/premium cambian afuera (compra directa, restore):
    // re-notificar para que tienda y biblioteca rebuilden.
    _premium.addListener(_onPremiumChanged);
  }

  @override
  void dispose() {
    _premium.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() => notifyListeners();

  List<Coleccion> _catalogo = [];
  bool _isLoading = false;
  String? _error;

  /// Catálogo completo de colecciones activas (orden de la tienda).
  List<Coleccion> get catalogo => List.unmodifiable(_catalogo);

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Ids de colecciones del catálogo que el usuario POSEE
  /// (pack en el perfil/device, o premium: incluye TODAS las colecciones
  /// presentes y futuras). Son las "descargadas" en la biblioteca.
  Set<String> get coleccionesDescargadas => {
        for (final c in _catalogo)
          if (_premium.isPremium ||
              _premium.packs.contains(PremiumRules.packIdDeSistema(c.id)))
            c.id,
      };

  /// ¿Puede el usuario abrir esta colección? (premium o pack propio)
  bool puedeAcceder(String coleccionId) =>
      PremiumRules.puedeAccederRecetaColeccion(
        coleccionId: coleccionId,
        isPremium: _premium.isPremium,
        packs: _premium.packs,
      );

  /// ¿El PACK de esta colección está comprado? (descarga real; NO se
  /// activa con premium). Distingue "Descargada" de "Incluida en Premium".
  bool tienePack(String coleccionId) =>
      _premium.packs.contains(PremiumRules.packIdDeSistema(coleccionId));

  /// Precio formateado del pack de la colección, o null si la tienda
  /// no lo devolvió (vive en el mapa global de precios del premium).
  String? precio(String coleccionId) =>
      _premium.priceFor(PremiumRules.packIdDeSistema(coleccionId));

  /// Carga el catálogo y los precios de los packs de colecciones.
  /// Se llama desde main.dart (junto al resto de los providers).
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _catalogo = await _repo.getCatalogo();
      // Precios de los packs de colecciones (suman al mapa global).
      await _premium.fetchProductsFor([
        for (final c in _catalogo) PremiumRules.packIdDeSistema(c.id),
      ]);
    } catch (e) {
      _error = 'Error al cargar la biblioteca: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Compra el pack de la colección (delega en premium: mismo flujo
  /// IAP que los packs por sistema). Devuelve true si se completó.
  Future<bool> comprar(String coleccionId) =>
      _premium.purchasePack(coleccionId);

  /// Receta de una colección por id (null si no existe).
  RecetaColeccion? recetaDe(String coleccionId, String recetaId) {
    for (final c in _catalogo) {
      if (c.id == coleccionId) return c.recetaPorId(recetaId);
    }
    return null;
  }
}
