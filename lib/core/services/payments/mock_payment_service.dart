import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import 'payment_service.dart';
import 'premium_rules.dart';

/// Implementación falsa de [PaymentService] para desarrollo y tests.
///
/// - `purchaseLifetime()` / `purchaseSubscription()` / `purchasePack()`
///   simulan un pago exitoso inmediato (mensual: +30 días; anual: +365).
/// - Persiste el estado en SharedPreferences: al reiniciar el APK de
///   prueba el usuario sigue con su acceso (mismo comportamiento que el
///   restore real por Google account).
/// - Nunca toca el SDK de pagos → corre en `flutter test` y en
///   dispositivos sin Play Store.
class MockPaymentService implements PaymentService {
  MockPaymentService({bool startLifetime = false, DateTime? premiumUntil})
      : _isLifetime = startLifetime,
        _premiumUntil = premiumUntil;

  static const String _lifetimeKey = 'mock_payment_lifetime';
  static const String _premiumUntilKey = 'mock_payment_premium_until';
  static const String _packsKey = 'mock_payment_packs';

  bool _isLifetime;
  DateTime? _premiumUntil;
  final Set<String> _purchasedPacks = {};
  bool _failPurchases = false;

  @override
  bool get isLifetime => _isLifetime;

  @override
  DateTime? get premiumUntil => _premiumUntil;

  @override
  bool get isPremium =>
      _isLifetime || (_premiumUntil != null && _premiumUntil!.isAfter(DateTime.now()));

  @override
  Set<String> get purchasedPacks => Set.unmodifiable(_purchasedPacks);

  @override
  Future<bool> init() async {
    // Restore: recupera la "compra" guardada en sesiones anteriores.
    final prefs = await SharedPreferences.getInstance();
    _isLifetime = prefs.getBool(_lifetimeKey) ?? _isLifetime;
    final untilMillis = prefs.getInt(_premiumUntilKey);
    _premiumUntil = untilMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(untilMillis)
        : _premiumUntil;
    _purchasedPacks
      ..clear()
      ..addAll(prefs.getStringList(_packsKey) ?? const []);
    return isPremium;
  }

  @override
  Future<bool> purchaseLifetime() async {
    if (_failPurchases) return false;
    _isLifetime = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lifetimeKey, true);
    return true;
  }

  @override
  Future<DateTime?> purchaseSubscription(MembresiaPlan plan) async {
    if (_failPurchases) return null;
    final until = DateTime.now().add(plan.duracion);
    _premiumUntil = until;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _premiumUntilKey,
      until.millisecondsSinceEpoch,
    );
    return until;
  }

  @override
  Future<bool> purchasePack(String sistemaId) async {
    if (_failPurchases) return false;
    final packId = PremiumRules.packIdDeSistema(sistemaId);
    _purchasedPacks.add(packId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_packsKey, _purchasedPacks.toList());
    return true;
  }

  @override
  Future<Map<String, String>> getProducts({List<String>? productIds}) async {
    final ids = productIds ?? _productosConocidos();
    return {
      for (final id in ids) id: _precioDePrueba(id),
    };
  }

  /// IDs conocidos por la app: membresías + lifetime + pack de cada sistema.
  List<String> _productosConocidos() => [
        AppConstants.mensualProductId,
        AppConstants.anualProductId,
        PaymentService.lifetimeProductId,
        for (final sistemaId in AppConstants.sistemasIds)
          AppConstants.packProductId(sistemaId),
      ];

  /// Precios FAKE de desarrollo (en release los define Play Console vía
  /// [GooglePlayPaymentService.getProducts]). Precios 2026-08-15:
  /// mensual USD 4.99, anual USD 11.99, lifetime USD 24.99, packs USD 1.99.
  String _precioDePrueba(String productId) {
    if (productId == AppConstants.mensualProductId) return 'USD 4.99';
    if (productId == AppConstants.anualProductId) return 'USD 11.99';
    if (productId == PaymentService.lifetimeProductId) return 'USD 24.99';
    return 'USD 1.99'; // packs por sistema y por colección
  }

  @override
  Future<bool> restorePurchases() async {
    // Restaura el estado persistido (mismo origen que init).
    return init();
  }

  /// Fuerza que las compras fallen (para simular error/cancelación).
  @visibleForTesting
  void setFailPurchasesForTesting(bool value) => _failPurchases = value;

  /// Simula el vencimiento de la membresía en el DEVICE (lo que Google
  /// reportaría al restaurar): persiste `premiumUntil` vencido para que
  /// un [init] posterior lo lea y `isPremium` dé false.
  @visibleForTesting
  Future<void> expireMembershipForTesting() async {
    final vencida = DateTime.now().subtract(const Duration(days: 1));
    _premiumUntil = vencida;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_premiumUntilKey, vencida.millisecondsSinceEpoch);
  }
}
