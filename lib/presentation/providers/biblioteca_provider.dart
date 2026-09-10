import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
///   la colección ('yuyo_pack_<coleccionId>'). Las colecciones GRATIS
///   (flag `gratis` del catálogo) están abiertas para todos, y el
///   botón "Gratis" de la tienda las marca como reclamadas (persistidas
///   localmente, sin pack ni compra).
/// - Precios: se consultan al [PremiumProvider] (fetchProductsFor) y
///   quedan en `productPrices` — una sola fuente para toda la app.
class BibliotecaProvider extends ChangeNotifier {
  final PremiumProvider _premium;
  final BibliotecaRepository _repo;

  /// Cache local de colecciones gratis RECLAMADAS (botón "Gratis" de
  /// la tienda). No es una compra: la persistencia local alcanza porque
  /// la colección ya es accesible por sí sola; el reclamo solo la
  /// muestra en "Mis colecciones" (mismo estado que una descarga).
  static const String _gratisKey = 'biblioteca_gratis_reclamadas';
  final Set<String> _gratisReclamadas = {};

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

  /// Colecciones que se muestran en la TIENDA: solo las que el usuario
  /// NO posee. "Poseer" = pack comprado, gratis reclamada, o Premium
  /// (que ya incluye todo el catálogo, presente y futuro). Así la tienda
  /// queda como "lo nuevo que te falta", sin repetir lo adquirido.
  List<Coleccion> get tiendaVisible => [
        for (final c in _catalogo)
          if (!_premium.isPremium &&
              !tienePack(c.id) &&
              !(c.gratis && esGratisReclamada(c.id)))
            c,
      ];

  /// ¿El acceso total de Premium está activo? (Usado por la tienda para
  /// elegir el mensaje cuando no hay nada nuevo que mostrar.)
  bool get esPremium => _premium.isPremium;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Ids de colecciones del catálogo que el usuario POSEE
  /// (pack en el perfil/device, gratis reclamada, o premium: incluye
  /// TODAS las colecciones presentes y futuras). Son las "descargadas"
  /// en la biblioteca.
  Set<String> get coleccionesDescargadas => {
        for (final c in _catalogo)
          if (_premium.isPremium ||
              _premium.packs.contains(PremiumRules.packIdDeSistema(c.id)) ||
              (c.gratis && _gratisReclamadas.contains(c.id)))
            c.id,
      };

  /// ¿Puede el usuario abrir esta colección? (premium, pack propio,
  /// o colección GRATIS — abierta para todos, sin compra).
  bool puedeAcceder(String coleccionId) {
    var esGratis = false;
    for (final c in _catalogo) {
      if (c.id == coleccionId) {
        esGratis = c.gratis;
        break;
      }
    }
    return PremiumRules.puedeAccederRecetaColeccion(
      coleccionId: coleccionId,
      isPremium: _premium.isPremium,
      packs: _premium.packs,
      gratis: esGratis,
    );
  }

  /// ¿La colección gratis ya fue reclamada (botón "Gratis" de la tienda)?
  bool esGratisReclamada(String coleccionId) =>
      _gratisReclamadas.contains(coleccionId);

  /// "Reclama" una colección gratis: la marca como descargada (mismo
  /// estado que una compra, pero sin IAP) y la persiste localmente.
  /// No-op si ya estaba reclamada.
  Future<void> reclamarGratis(String coleccionId) async {
    if (_gratisReclamadas.contains(coleccionId)) return;
    _gratisReclamadas.add(coleccionId);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _gratisKey,
        json.encode(_gratisReclamadas.toList()),
      );
    } catch (_) {
      // Best-effort: si falla la persistencia, el reclamo sigue en
      // memoria esta sesión (la colección es gratis igualmente).
    }
  }

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
      await _cargarGratisReclamadas();
      _catalogo = await _repo.getCatalogo();
      // Precios de los packs de colecciones (suman al mapa global).
      // Las colecciones GRATIS no tienen producto IAP: no se consultan.
      await _premium.fetchProductsFor([
        for (final c in _catalogo)
          if (!c.gratis) PremiumRules.packIdDeSistema(c.id),
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

  /// Carga del cache local las colecciones gratis reclamadas.
  Future<void> _cargarGratisReclamadas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_gratisKey);
      if (raw == null) return;
      final decoded = json.decode(raw) as List<dynamic>;
      _gratisReclamadas
        ..clear()
        ..addAll(decoded.cast<String>());
    } catch (_) {
      // Best-effort: catálogo en línea sin reclamos previos.
    }
  }
}
