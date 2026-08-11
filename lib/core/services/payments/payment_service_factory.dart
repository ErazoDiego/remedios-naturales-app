import 'package:flutter/foundation.dart';
import 'google_play_payment_service.dart';
import 'mock_payment_service.dart';
import 'payment_service.dart';

/// Fábrica del servicio de pagos según el entorno de build.
///
/// - Debug/profile → [MockPaymentService]: flujo premium completo y
///   testeable sin Play Console ni dinero real.
/// - Release → [GooglePlayPaymentService]: billing real. Sin productos
///   configurados en Play Console devuelve "compra no disponible".
class PaymentServiceFactory {
  PaymentServiceFactory._();

  static PaymentService create() {
    if (kReleaseMode) return GooglePlayPaymentService();
    return MockPaymentService();
  }
}
