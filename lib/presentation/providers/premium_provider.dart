import 'package:flutter/material.dart';
import '../../data/services/user_service.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/payments/payment_service.dart';
import '../../core/services/payments/payment_service_factory.dart';
import '../../core/services/payments/premium_rules.dart';

/// Provider del estado premium (membresías + lifetime) y packs por
/// sistema/colección (compras únicas).
///
/// Fuente de verdad = [PaymentService] (Google Play Billing / Mock),
/// reconciliado con el perfil persistido en Supabase/local para
/// restaurar la compra en otro dispositivo o tras reinstalar.
///
/// - Acceso total (`isPremium`): DERIVADO de lifetime O membresía
///   vigente (`premiumUntil > now`), combinando dispositivo y perfil.
/// - Packs: UNIÓN entre packs del dispositivo y packs del perfil
///   (cada sistema/colección es un producto distinto). Las compras
///   individuales son PARA SIEMPRE: no se pierden al vencer la membresía.
///
/// Al cambiar el estado, sincroniza [AdsService.setPremium] en un solo
/// lugar: la membresía (mensual/anual) y el lifetime apagan anuncios.
/// Los packs NO apagan anuncios (regla de producto).
class PremiumProvider extends ChangeNotifier {
  final PaymentService _payment;
  final UserService _userService;

  PremiumProvider({PaymentService? payment, UserService? userService})
      : _payment = payment ?? PaymentServiceFactory.create(),
        _userService = userService ?? UserService();

  bool _isLifetime = false;
  DateTime? _premiumUntil;
  bool _isLoading = false;
  String? _error;
  final List<String> _packs = [];
  Map<String, String> _productPrices = {};

  /// ¿Acceso total activo? DERIVADO: lifetime o membresía vigente.
  bool get isPremium =>
      PremiumRules.esPremiumActivo(
        lifetime: _isLifetime,
        premiumUntil: _premiumUntil,
        now: DateTime.now(),
      );

  /// ¿Compra lifetime activa?
  bool get isLifetime => _isLifetime;

  /// Vencimiento de la membresía vigente (null si no hay suscripción).
  DateTime? get premiumUntil => _premiumUntil;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Packs poseídos (device + perfil), ej: ['yuyo_pack_digestivo'].
  List<String> get packs => List.unmodifiable(_packs);

  /// Precios de la tienda: productId → precio formateado (ej: 'USD 4.99').
  /// Vacío si la tienda no tiene configurados los productos.
  Map<String, String> get productPrices => Map.unmodifiable(_productPrices);

  /// Precio formateado de un producto, o null si la tienda no lo tiene.
  String? priceFor(String productId) => _productPrices[productId];

  /// Precio del lifetime (atajo para la UI).
  String? get lifetimePrice => priceFor(PaymentService.lifetimeProductId);

  /// Precio de una membresía (atajo para la UI).
  String? membershipPrice(MembresiaPlan plan) => priceFor(plan.productId);

  /// Consulta precios adicionales (ej: packs de colecciones de la
  /// tienda) y los SUMA al mapa de precios existente.
  Future<void> fetchProductsFor(List<String> productIds) async {
    if (productIds.isEmpty) return;
    final nuevos = await _payment.getProducts(productIds: productIds);
    _productPrices = {..._productPrices, ...nuevos};
    notifyListeners();
  }

  /// ¿Tiene acceso a la receta? (premium, muestreo gratis o pack del sistema)
  bool puedeAccederAReceta(String recipeId) =>
      PremiumRules.puedeAccederAReceta(
        isPremium: isPremium,
        recipeId: recipeId,
        packs: _packs,
      );

  /// Inicializa: restaura compras del dispositivo + perfil persistido
  /// y sincroniza anuncios. Se llama desde main.dart.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _payment.init();
      final devicePacks = _payment.purchasedPacks;
      final profile = await _userService.getCurrentProfile();
      final profileLifetime = profile?.lifetime ?? false;
      final profileUntil = profile?.premiumUntil;
      final profilePacks = profile?.packs ?? const [];

      // Acceso total: OR entre dispositivo y perfil.
      _isLifetime = _payment.isLifetime || profileLifetime;
      final deviceUntil = _payment.premiumUntil;
      _premiumUntil = _maxDate(deviceUntil, profileUntil);

      // Packs: unión (device + perfil).
      _packs
        ..clear()
        ..addAll(devicePacks)
        ..addAll(profilePacks.where((p) => !_packs.contains(p)));

      _syncAds();
      await _persistNuevos(
        deviceLifetime: _payment.isLifetime,
        profileLifetime: profileLifetime,
        deviceUntil: deviceUntil,
        profileUntil: profileUntil,
        devicePacks: devicePacks,
        profilePacks: profilePacks,
      );

      // Precios de la tienda (para mostrar en PremiumScreen y diálogos).
      _productPrices = await _payment.getProducts();
    } catch (e) {
      _error = 'Error al inicializar premium: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Compra LIFETIME (acceso permanente). Devuelve true si se completó.
  Future<bool> purchaseLifetime() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final ok = await _payment.purchaseLifetime();
    if (ok) {
      _isLifetime = true;
      _syncAds();
      try {
        await _userService.setLifetime(true);
      } catch (e) {
        debugPrint('No se pudo persistir lifetime: $e');
      }
    } else {
      _error = 'La compra se canceló o no está disponible';
    }

    _isLoading = false;
    notifyListeners();
    return ok;
  }

  /// Contrata una membresía (mensual/anual). Devuelve true si se completó.
  Future<bool> purchaseSubscription(MembresiaPlan plan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final until = await _payment.purchaseSubscription(plan);
    if (until != null) {
      _premiumUntil = _maxDate(_premiumUntil, until);
      _syncAds();
      try {
        await _userService.setPremiumUntil(_premiumUntil);
      } catch (e) {
        debugPrint('No se pudo persistir premium_until: $e');
      }
    } else {
      _error = 'La compra se canceló o no está disponible';
    }

    _isLoading = false;
    notifyListeners();
    return until != null;
  }

  /// Inicia la compra del pack de un sistema o colección (ej: 'digestivo'
  /// o 'coleccion-id'). Los packs son PARA SIEMPRE. Devuelve true si el
  /// pago se completó y confirmó.
  Future<bool> purchasePack(String sistemaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final ok = await _payment.purchasePack(sistemaId);
    if (ok) {
      final packId = PremiumRules.packIdDeSistema(sistemaId);
      if (!_packs.contains(packId)) {
        _packs.add(packId);
      }
      // Los packs NO apagan anuncios: solo la membresía y el lifetime.
      // _syncAds() no hace falta, pero notificamos para actualizar la UI.
      try {
        await _userService.setPackOwned(packId);
      } catch (e) {
        debugPrint('No se pudo persistir pack $packId: $e');
      }
    } else {
      _error = 'La compra del pack se canceló o no está disponible';
    }

    _isLoading = false;
    notifyListeners();
    return ok;
  }

  /// Restaura compras previas (reinstalación / nuevo dispositivo):
  /// membresías, lifetime y packs del dispositivo, persistidos al perfil.
  Future<bool> restorePurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _payment.restorePurchases();
      final devicePacks = _payment.purchasedPacks;
      final deviceLifetime = _payment.isLifetime;
      final deviceUntil = _payment.premiumUntil;

      final restoredAcceso = deviceLifetime || deviceUntil != null;

      if (deviceLifetime) {
        _isLifetime = true;
        try {
          await _userService.setLifetime(true);
        } catch (e) {
          debugPrint('No se pudo persistir lifetime: $e');
        }
      }
      if (deviceUntil != null) {
        _premiumUntil = _maxDate(_premiumUntil, deviceUntil);
        try {
          await _userService.setPremiumUntil(_premiumUntil);
        } catch (e) {
          debugPrint('No se pudo persistir premium_until: $e');
        }
      }
      _syncAds();

      for (final packId in devicePacks) {
        if (_packs.contains(packId)) continue;
        _packs.add(packId);
        try {
          await _userService.setPackOwned(packId);
        } catch (e) {
          debugPrint('No se pudo persistir pack $packId: $e');
        }
      }

      if (!restoredAcceso && devicePacks.isEmpty) {
        _error = 'No se encontraron compras para restaurar';
      }
      return restoredAcceso || devicePacks.isNotEmpty;
    } catch (e) {
      _error = 'Error al restaurar compras: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Internos ────────────────────────────────────────────────────────

  void _syncAds() {
    AdsService.instance.setPremium(isPremium);
  }

  /// Máxima de dos fechas (null-safe).
  DateTime? _maxDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  /// Persiste lo que está en el device pero aún no en el perfil
  /// (idempotente en UserService) para el restore multi-dispositivo.
  Future<void> _persistNuevos({
    required bool deviceLifetime,
    required bool profileLifetime,
    required DateTime? deviceUntil,
    required DateTime? profileUntil,
    required Set<String> devicePacks,
    required List<String> profilePacks,
  }) async {
    if (deviceLifetime && !profileLifetime) {
      try {
        await _userService.setLifetime(true);
      } catch (e) {
        debugPrint('No se pudo persistir lifetime: $e');
      }
    }
    if (deviceUntil != null &&
        (profileUntil == null || deviceUntil.isAfter(profileUntil))) {
      try {
        await _userService.setPremiumUntil(deviceUntil);
      } catch (e) {
        debugPrint('No se pudo persistir premium_until: $e');
      }
    }
    for (final packId in devicePacks) {
      if (profilePacks.contains(packId)) continue;
      try {
        await _userService.setPackOwned(packId);
      } catch (e) {
        debugPrint('No se pudo persistir pack $packId: $e');
      }
    }
  }
}
