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

  test('purchaseLifetime: simula compra permanente exitosa', () async {
    final payment = MockPaymentService();
    await payment.init();

    final ok = await payment.purchaseLifetime();

    expect(ok, isTrue);
    expect(payment.isLifetime, isTrue);
    expect(payment.isPremium, isTrue);
  });

  test('purchaseSubscription mensual: vence a los 30 días', () async {
    final payment = MockPaymentService();
    await payment.init();

    final until = await payment.purchaseSubscription(MembresiaPlan.mensual);

    expect(until, isNotNull);
    expect(payment.premiumUntil, until);
    expect(payment.isPremium, isTrue);
    expect(payment.isLifetime, isFalse);
    // Duración aproximada: 30 días desde la compra.
    final diff = payment.premiumUntil!.difference(DateTime.now());
    expect(diff.inDays, 29); // 30 días menos el segundo que pasó
  });

  test('purchaseSubscription anual: vence a los 365 días', () async {
    final payment = MockPaymentService();
    await payment.init();

    final until = await payment.purchaseSubscription(MembresiaPlan.anual);

    expect(until, isNotNull);
    expect(payment.premiumUntil, until);
    expect(payment.isPremium, isTrue);
    expect(payment.isLifetime, isFalse);
  });

  test('init: restaura la "compra" persistida entre sesiones', () async {
    final payment = MockPaymentService();
    await payment.init();
    await payment.purchaseLifetime();

    // Nueva instancia (simula reinicio de la app): lee prefs
    final reinicio = MockPaymentService();
    expect(await reinicio.init(), isTrue);
    expect(reinicio.isLifetime, isTrue);
    expect(reinicio.isPremium, isTrue);
  });

  test('restorePurchases devuelve el estado actual', () async {
    final payment = MockPaymentService();
    await payment.init();
    expect(await payment.restorePurchases(), isFalse);

    await payment.purchaseLifetime();
    expect(await payment.restorePurchases(), isTrue);
  });

  test('membresía vencida: isPremium pasa a false', () async {
    final payment = MockPaymentService(
      premiumUntil: DateTime.now().subtract(const Duration(days: 1)),
    );

    expect(payment.isPremium, isFalse);
  });

  test('con fallo forzado: la compra devuelve false y NO activa premium',
      () async {
    final payment = MockPaymentService();
    await payment.init();
    payment.setFailPurchasesForTesting(true);

    final ok = await payment.purchaseLifetime();

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

    test('restorePurchases restaura lifetime y packs persistidos', () async {
      final payment = MockPaymentService();
      await payment.init();
      await payment.purchaseLifetime();
      await payment.purchasePack('sensorial');

      final reinicio = MockPaymentService();
      await reinicio.init();
      expect(await reinicio.restorePurchases(), isTrue);
      expect(reinicio.isPremium, isTrue);
      expect(reinicio.purchasedPacks, contains('yuyo_pack_sensorial'));
    });

    test('packs y lifetime se restauran juntos', () async {
      final payment = MockPaymentService();
      await payment.init();
      await payment.purchasePack('dermico');
      await payment.purchaseLifetime();

      expect(payment.isPremium, isTrue);
      expect(payment.purchasedPacks, contains('yuyo_pack_dermico'));
    });

    test('membresía NO borra packs ya comprados (compra para siempre)',
        () async {
      final payment = MockPaymentService();
      await payment.init();
      await payment.purchasePack('digestivo');
      await payment.purchaseSubscription(MembresiaPlan.mensual);

      // Ambos conviven: el pack sigue expuesto y el acceso premium activo.
      expect(payment.purchasedPacks, contains('yuyo_pack_digestivo'));
      expect(payment.isPremium, isTrue);

      // Nueva instancia: se restaura el pack (membresía vigente también).
      final reinicio = MockPaymentService();
      await reinicio.init();
      expect(reinicio.purchasedPacks, contains('yuyo_pack_digestivo'));
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
    test('devuelve precios fake para membresías, lifetime y packs',
        () async {
      final payment = MockPaymentService();
      await payment.init();

      final products = await payment.getProducts();

      expect(products[AppConstants.mensualProductId], 'USD 4.99');
      expect(products[AppConstants.anualProductId], 'USD 11.99');
      expect(products[PaymentService.lifetimeProductId], 'USD 24.99');
      expect(products['yuyo_pack_digestivo'], 'USD 1.99');
      // Sin args NO incluye packs de colecciones (la tienda los consulta
      // con productIds explícitos, ver test siguiente).
      expect(products.containsKey('yuyo_pack_jugos'), isFalse);
      // Debe incluir membresías + lifetime + un pack por sistema del núcleo.
      expect(products.length, AppConstants.sistemasIds.length + 3);
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
