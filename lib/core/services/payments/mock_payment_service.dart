import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_service.dart';

/// Implementación falsa de [PaymentService] para desarrollo y tests.
///
/// - `purchasePremium()` simula un pago exitoso inmediato.
/// - Persiste el flag en SharedPreferences: al reiniciar el APK de
///   prueba el usuario sigue premium (mismo comportamiento que el
///   restore real por Google account).
/// - Nunca toca el SDK de pagos → corre en `flutter test` y en
///   dispositivos sin Play Store.
class MockPaymentService implements PaymentService {
  MockPaymentService({bool startPremium = false}) : _isPremium = startPremium;

  static const String _premiumKey = 'mock_payment_premium';

  bool _isPremium;
  bool _failPurchases = false;

  @override
  bool get isPremium => _isPremium;

  @override
  Future<bool> init() async {
    // Restore: recupera la "compra" guardada en sesiones anteriores.
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? _isPremium;
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
  Future<bool> restorePurchases() => Future.value(_isPremium);

  /// Fuerza que las compras fallen (para simular error/cancelación).
  @visibleForTesting
  void setFailPurchasesForTesting(bool value) => _failPurchases = value;
}
