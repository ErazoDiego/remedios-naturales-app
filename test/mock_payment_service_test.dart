import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/core/constants/app_constants.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/core/services/payments/payment_service.dart';
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

  group('packs por sistema', () {
    test('purchasePack: simula compra del pack y lo expone', () async {
      final payment = MockPaymentService();
      await payment.init();

      final ok = await payment.purchasePack('digestivo');

      expect(ok, isTrue);
      expect(payment.purchasedPacks, contains('yuyo_pack_digestivo'));
      // Comprar un pack NO activa premium (son productos distintos).
      expect(payment.isPremium, isFalse);
    });

    test('init: restaura packs persistidos entre sesiones', () async {
      final payment = MockPaymentService();
      await payment.init();
      await payment.purchasePack('digestivo');
      await payment.purchasePack('urinario');

      final reinicio = MockPaymentService();
      await reinicio.init();

      expect(reinicio.purchasedPacks,
          containsAll(['yuyo_pack_digestivo', 'yuyo_pack_urinario']));
      expect(reinicio.isPremium, isFalse);
    });

    test('restorePurchases restaura premium y packs persistidos', () async {
      final payment = MockPaymentService();
      await payment.init();
      await payment.purchasePremium();
      await payment.purchasePack('sensorial');

      final reinicio = MockPaymentService();
      await reinicio.init();
      expect(await reinicio.restorePurchases(), isTrue);
      expect(reinicio.isPremium, isTrue);
      expect(reinicio.purchasedPacks, contains('yuyo_pack_sensorial'));
    });

    test('packs y premium se restauran juntos', () async {
      final payment = MockPaymentService();
      await payment.init();
      await payment.purchasePack('dermico');
      await payment.purchasePremium();

      expect(payment.isPremium, isTrue);
      expect(payment.purchasedPacks, contains('yuyo_pack_dermico'));
    });

    test('con fallo forzado: la compra del pack devuelve false', () async {
      final payment = MockPaymentService();
      await payment.init();
      payment.setFailPurchasesForTesting(true);

      expect(await payment.purchasePack('digestivo'), isFalse);
      expect(payment.purchasedPacks, isEmpty);
    });
  });

  group('getProducts (precios)', () {
    test('devuelve precios fake para premium y packs de sistemas', () async {
      final payment = MockPaymentService();
      await payment.init();

      final products = await payment.getProducts();

      expect(products[PaymentService.premiumProductId], 'USD 4.99');
      expect(products['yuyo_pack_digestivo'], 'USD 1.99');
      // Sin args NO incluye packs de colecciones (la tienda los consulta
      // con productIds explícitos, ver test siguiente).
      expect(products.containsKey('yuyo_pack_jugos'), isFalse);
      // Debe incluir premium + un pack por sistema del núcleo.
      expect(products.length, AppConstants.sistemasIds.length + 1);
    });

    test('con ids específicos devuelve solo esos', () async {
      final payment = MockPaymentService();
      await payment.init();

      final products =
          await payment.getProducts(productIds: ['yuyo_pack_jugos']);

      expect(products, {'yuyo_pack_jugos': 'USD 1.99'});
    });

    test('ids desconocidos reciben precio de pack por defecto', () async {
      final payment = MockPaymentService();
      await payment.init();

      final products = await payment.getProducts(productIds: ['otro_producto']);

      expect(products['otro_producto'], 'USD 1.99');
    });
  });
}
