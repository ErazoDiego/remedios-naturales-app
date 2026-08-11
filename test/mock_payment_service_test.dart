import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MockPaymentService: flujo premium completo sin plataforma de pago.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('init: arranca sin premium', () async {
    final payment = MockPaymentService();

    expect(await payment.init(), isFalse);
    expect(payment.isPremium, isFalse);
  });

  test('purchasePremium: simula compra exitosa', () async {
    final payment = MockPaymentService();
    await payment.init();

    final ok = await payment.purchasePremium();

    expect(ok, isTrue);
    expect(payment.isPremium, isTrue);
  });

  test('init: restaura la "compra" persistida entre sesiones', () async {
    final payment = MockPaymentService();
    await payment.init();
    await payment.purchasePremium();

    // Nueva instancia (simula reinicio de la app): lee prefs
    final reinicio = MockPaymentService();
    expect(await reinicio.init(), isTrue);
    expect(reinicio.isPremium, isTrue);
  });

  test('restorePurchases devuelve el estado actual', () async {
    final payment = MockPaymentService();
    await payment.init();
    expect(await payment.restorePurchases(), isFalse);

    await payment.purchasePremium();
    expect(await payment.restorePurchases(), isTrue);
  });

  test('con fallo forzado: la compra devuelve false y NO activa premium',
      () async {
    final payment = MockPaymentService();
    await payment.init();
    payment.setFailPurchasesForTesting(true);

    final ok = await payment.purchasePremium();

    expect(ok, isFalse);
    expect(payment.isPremium, isFalse);
  });
}
