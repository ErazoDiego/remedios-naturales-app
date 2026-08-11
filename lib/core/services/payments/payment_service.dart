import '../../constants/app_constants.dart';

/// Contrato del servicio de pagos (Google Play Billing).
///
/// La UI y los providers NO conocen la implementación concreta: dependen
/// de esta interfaz. Así, en desarrollo y tests se usa [MockPaymentService]
/// (flujo completo de premium, sin plataforma de pago real) y en release
/// [GooglePlayPaymentService] (in_app_purchase nativo).
abstract class PaymentService {
  /// Sincroniza el estado de compras previas (restore implícito).
  /// Devuelve true si el usuario tiene premium activo.
  Future<bool> init();

  /// Inicia el flujo de compra de premium (compra única no consumible).
  /// Devuelve true solo si el pago se completó y confirmó.
  Future<bool> purchasePremium();

  /// Restaura compras previas (reinstalación / nuevo dispositivo).
  /// Devuelve true si hay premium activo tras la restauración.
  Future<bool> restorePurchases();

  /// ¿Premium activo? (fuente de verdad del pago, en memoria)
  bool get isPremium;

  /// ID del producto premium en la tienda (compra única).
  static const String premiumProductId = AppConstants.premiumProductId;
}
