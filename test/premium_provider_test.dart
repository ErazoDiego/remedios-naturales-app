import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/core/services/ads_service.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/core/services/payments/payment_service.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PremiumProvider: compra, persistencia en el perfil y sincronización
/// con AdsService (modo anónimo + MockPaymentService, sin SDK).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AdsService.instance.setPremium(false);
    // El singleton UserService cachea el perfil en memoria: limpiarlo
    // para que un test no contamine al siguiente.
    await UserService().clearAll();
  });

  tearDown(() {
    AdsService.instance.setPremium(false);
  });

  test('init: usuario free no es premium y los anuncios siguen activos',
      () async {
    final provider = PremiumProvider(payment: MockPaymentService());

    await provider.init();

    expect(provider.isPremium, isFalse);
    expect(AdsService.instance.isPremium, isFalse);
  });

  test('purchaseLifetime: activa premium, apaga anuncios y persiste',
      () async {
    final provider = PremiumProvider(payment: MockPaymentService());
    await provider.init();

    final ok = await provider.purchaseLifetime();

    expect(ok, isTrue);
    expect(provider.isLifetime, isTrue);
    expect(provider.isPremium, isTrue);
    expect(AdsService.instance.isPremium, isTrue);

    // Persistido en el perfil (anónimo local) para restore
    final profile = await UserService().getCurrentProfile();
    expect(profile!.lifetime, isTrue);
  });

  test('purchaseSubscription: activa premium temporal y apaga anuncios',
      () async {
    final provider = PremiumProvider(payment: MockPaymentService());
    await provider.init();

    final ok = await provider.purchaseSubscription(MembresiaPlan.mensual);

    expect(ok, isTrue);
    expect(provider.isLifetime, isFalse);
    expect(provider.premiumUntil, isNotNull);
    expect(provider.isPremium, isTrue);
    expect(AdsService.instance.isPremium, isTrue);

    // Persistido en el perfil (anónimo local) para restore
    final profile = await UserService().getCurrentProfile();
    expect(profile!.premiumUntil, isNotNull);
  });

  test('compra fallida: no activa premium ni toca el perfil', () async {
    final payment = MockPaymentService()..setFailPurchasesForTesting(true);
    final provider = PremiumProvider(payment: payment);
    await provider.init();

    final ok = await provider.purchaseLifetime();

    expect(ok, isFalse);
    expect(provider.isPremium, isFalse);
    expect(AdsService.instance.isPremium, isFalse);
    expect(provider.error, isNotNull);

    final profile = await UserService().getCurrentProfile();
    expect(profile!.lifetime, isFalse);
  });

  test('init: restaura lifetime persistido en el perfil (multi-dispositivo)',
      () async {
    // Simula compra previa persistida en el perfil local
    await UserService().setLifetime(true);

    final provider = PremiumProvider(payment: MockPaymentService());

    await provider.init();

    expect(provider.isLifetime, isTrue);
    expect(provider.isPremium, isTrue);
    expect(AdsService.instance.isPremium, isTrue);
  });

  test('init: restaura membresía vigente persistida en el perfil',
      () async {
    await UserService().setPremiumUntil(
      DateTime.now().add(const Duration(days: 20)),
    );

    final provider = PremiumProvider(payment: MockPaymentService());
    await provider.init();

    expect(provider.isLifetime, isFalse);
    expect(provider.premiumUntil, isNotNull);
    expect(provider.isPremium, isTrue);
    expect(AdsService.instance.isPremium, isTrue);
  });

  test('init: membresía VENCIDA en el perfil no activa premium', () async {
    await UserService().setPremiumUntil(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    final provider = PremiumProvider(payment: MockPaymentService());
    await provider.init();

    expect(provider.isPremium, isFalse);
    expect(AdsService.instance.isPremium, isFalse);
  });

  test('restorePurchases: sin compras previas devuelve false y setea error',
      () async {
    final provider = PremiumProvider(payment: MockPaymentService());
    await provider.init();

    final ok = await provider.restorePurchases();

    expect(ok, isFalse);
    expect(provider.error, isNotNull);
  });

  group('packs por sistema', () {
    test('purchasePack: agrega el pack, NO apaga anuncios ni activa premium',
        () async {
      final provider = PremiumProvider(payment: MockPaymentService());
      await provider.init();

      final ok = await provider.purchasePack('digestivo');

      expect(ok, isTrue);
      expect(provider.packs, contains('yuyo_pack_digestivo'));
      expect(provider.isPremium, isFalse);
      expect(AdsService.instance.isPremium, isFalse);

      // Persistido en el perfil (anónimo local) para restore
      final profile = await UserService().getCurrentProfile();
      expect(profile!.packs, contains('yuyo_pack_digestivo'));
    });

    test('pack comprado antes de la membresía sobrevive al vencimiento '
        '(compra para siempre)', () async {
      final device = MockPaymentService();
      final provider = PremiumProvider(payment: device);
      await provider.init();

      await provider.purchasePack('digestivo');
      await provider.purchaseSubscription(MembresiaPlan.mensual);

      // Ambos conviven durante la membresía.
      expect(provider.packs, contains('yuyo_pack_digestivo'));
      expect(provider.isPremium, isTrue);

      // La membresía VENCE (el device reporta la sub vencida, como
      // Google al restaurar) y el perfil se actualiza.
      await device.expireMembershipForTesting();
      await UserService().setPremiumUntil(null);
      final reinicio = PremiumProvider(payment: device);
      await reinicio.init();

      // El pack SIGUE: es una compra individual de por vida.
      expect(reinicio.packs, contains('yuyo_pack_digestivo'));
      // La membresía vencida no da acceso.
      expect(reinicio.isPremium, isFalse);
      expect(AdsService.instance.isPremium, isFalse);
    });

    test('purchasePack: idempotente (no duplica el pack)', () async {
      final provider = PremiumProvider(payment: MockPaymentService());
      await provider.init();

      await provider.purchasePack('urinario');
      await provider.purchasePack('urinario');

      expect(provider.packs.where((p) => p == 'yuyo_pack_urinario'),
          hasLength(1));
    });

    test('purchasePack fallida: no agrega el pack y setea error', () async {
      final payment = MockPaymentService()..setFailPurchasesForTesting(true);
      final provider = PremiumProvider(payment: payment);
      await provider.init();

      final ok = await provider.purchasePack('dermico');

      expect(ok, isFalse);
      expect(provider.packs, isEmpty);
      expect(provider.error, isNotNull);
    });

    test('init: restaura packs del perfil (multi-dispositivo)', () async {
      await UserService().setPackOwned('yuyo_pack_sensorial');

      final provider = PremiumProvider(payment: MockPaymentService());
      await provider.init();

      expect(provider.packs, contains('yuyo_pack_sensorial'));
    });

    test('init: restaura packs del dispositivo y los persiste al perfil',
        () async {
      // Compra simulada en el device (persistida en prefs del mock)
      final device = MockPaymentService();
      await device.init();
      await device.purchasePack('hormonal');

      final provider = PremiumProvider(payment: device);
      await provider.init();

      expect(provider.packs, contains('yuyo_pack_hormonal'));
      final profile = await UserService().getCurrentProfile();
      expect(profile!.packs, contains('yuyo_pack_hormonal'));
    });

    test('init: unión de packs device + perfil sin duplicar', () async {
      await UserService().setPackOwned('yuyo_pack_digestivo');

      final device = MockPaymentService();
      await device.init();
      await device.purchasePack('digestivo'); // el mismo pack en el device
      await device.purchasePack('cardiovascular');

      final provider = PremiumProvider(payment: device);
      await provider.init();

      expect(provider.packs, containsAll([
        'yuyo_pack_digestivo',
        'yuyo_pack_cardiovascular',
      ]));
      expect(provider.packs.where((p) => p == 'yuyo_pack_digestivo'),
          hasLength(1));
    });

    test('restorePurchases: restaura packs del dispositivo', () async {
      final device = MockPaymentService();
      await device.init();
      await device.purchasePack('nervioso');
      // Reinicio simulado: la "compra" quedó solo en prefs del mock
      final reinicio = MockPaymentService();
      await reinicio.init();

      final provider = PremiumProvider(payment: reinicio);
      await provider.init();

      final ok = await provider.restorePurchases();

      expect(ok, isTrue);
      expect(provider.packs, contains('yuyo_pack_nervioso'));
      final profile = await UserService().getCurrentProfile();
      expect(profile!.packs, contains('yuyo_pack_nervioso'));
    });

    test('puedeAccederAReceta: pack del sistema desbloquea sus recetas',
        () async {
      final provider = PremiumProvider(payment: MockPaymentService());
      await provider.init();

      // Free sin packs: bloqueada
      expect(provider.puedeAccederAReceta('digestivo_01'), isFalse);

      await provider.purchasePack('digestivo');

      // Con el pack del sistema: desbloqueada
      expect(provider.puedeAccederAReceta('digestivo_01'), isTrue);
      // Otro sistema sigue bloqueado
      expect(provider.puedeAccederAReceta('nervioso_01'), isFalse);
    });
  });

  group('reset (cierre de sesión)', () {
    test('reset: limpia lifetime, premiumUntil y packs, re-activa anuncios',
        () async {
      final provider = PremiumProvider(payment: MockPaymentService());
      await provider.init();

      // Compra lifetime + pack → premium activo, anuncios apagados
      await provider.purchaseLifetime();
      await provider.purchasePack('digestivo');
      expect(provider.isPremium, isTrue);
      expect(AdsService.instance.isPremium, isTrue);
      expect(provider.packs, isNotEmpty);

      // Simula cierre de sesión
      provider.reset();

      expect(provider.isLifetime, isFalse);
      expect(provider.premiumUntil, isNull);
      expect(provider.packs, isEmpty);
      expect(provider.isPremium, isFalse);
      expect(AdsService.instance.isPremium, isFalse);
    });

    test('reset: después de membresía activa también limpia', () async {
      final provider = PremiumProvider(payment: MockPaymentService());
      await provider.init();

      await provider.purchaseSubscription(MembresiaPlan.mensual);
      expect(provider.isPremium, isTrue);

      provider.reset();

      expect(provider.premiumUntil, isNull);
      expect(provider.isPremium, isFalse);
      expect(AdsService.instance.isPremium, isFalse);
    });

    test('reset: limpia error previo', () async {
      final payment = MockPaymentService()..setFailPurchasesForTesting(true);
      final provider = PremiumProvider(payment: payment);
      await provider.init();

      await provider.purchaseLifetime(); // falla
      expect(provider.error, isNotNull);

      provider.reset();

      expect(provider.error, isNull);
    });
  });
}
