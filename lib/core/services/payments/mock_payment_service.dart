import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import 'payment_service.dart';
import 'premium_rules.dart';

/// Implementación falsa de [PaymentService] para desarrollo y tests.
///
/// - `purchasePremium()` / `purchasePack()` simulan un pago exitoso
///   inmediato.
/// - Persiste el estado en SharedPreferences: al reiniciar el APK de
///   prueba el usuario sigue premium/con sus packs (mismo comportamiento
///   que el restore real por Google account).
/// - Nunca toca el SDK de pagos → corre en `flutter test` y en
///   dispositivos sin Play Store.
class MockPaymentService implements PaymentService {
  MockPaymentService({bool startPremium = false}) : _isPremium = startPremium;

  static const String _premiumKey = 'mock_payment_premium';
  static const String _packsKey = 'mock_payment_packs';

  bool _isPremium;
  final Set<String> _purchasedPacks = {};
  bool _failPurchases = false;

  @override
  bool get isPremium => _isPremium;

  @override
  Set<String> get purchasedPacks => Set.unmodifiable(_purchasedPacks);

  @override
  Future<bool> init() async {
    // Restore: recupera la "compra" guardada en sesiones anteriores.
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? _isPremium;
    _purchasedPacks
      ..clear()
      ..addAll(prefs.getStringList(_packsKey) ?? const []);
    return _isPremium;
  }

  @override
  Future<bool> purchasePremium() async {
    if (_failPurchases) return false;
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, true);
    return true;
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

  /// IDs conocidos por la app: premium + pack de cada sistema.
  List<String> _productosConocidos() => [
        PaymentService.premiumProductId,
        for (final sistemaId in AppConstants.sistemasIds)
          AppConstants.packProductId(sistemaId),
      ];

  /// Precios FAKE de desarrollo (en release los define Play Console vía
  /// [GooglePlayPaymentService.getProducts]).
  String _precioDePrueba(String productId) =>
      productId == PaymentService.premiumProductId ? 'USD 4.99' : 'USD 1.99';

  @override
  Future<bool> restorePurchases() async {
    // Restaura el estado persistido (mismo origen que init).
    return init();
  }

  /// Fuerza que las compras fallen (para simular error/cancelación).
  @visibleForTesting
  void setFailPurchasesForTesting(bool value) => _failPurchases = value;
}
