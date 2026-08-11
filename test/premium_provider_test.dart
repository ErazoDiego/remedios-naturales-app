import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/core/services/ads_service.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
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

  test('purchasePremium: activa premium, apaga anuncios y persiste',
      () async {
    final provider = PremiumProvider(payment: MockPaymentService());
    await provider.init();

    final ok = await provider.purchasePremium();

    expect(ok, isTrue);
    expect(provider.isPremium, isTrue);
    expect(AdsService.instance.isPremium, isTrue);

    // Persistido en el perfil (anónimo local) para restore
    final profile = await UserService().getCurrentProfile();
    expect(profile!.premium, isTrue);
  });

  test('compra fallida: no activa premium ni toca el perfil', () async {
    final payment = MockPaymentService()..setFailPurchasesForTesting(true);
    final provider = PremiumProvider(payment: payment);
    await provider.init();

    final ok = await provider.purchasePremium();

    expect(ok, isFalse);
    expect(provider.isPremium, isFalse);
    expect(AdsService.instance.isPremium, isFalse);
    expect(provider.error, isNotNull);

    final profile = await UserService().getCurrentProfile();
    expect(profile!.premium, isFalse);
  });

  test('init: restaura premium persistido en el perfil (multi-dispositivo)',
      () async {
    // Simula compra previa persistida en el perfil local
    await UserService().setPremium(true);

    final provider = PremiumProvider(payment: MockPaymentService());

    await provider.init();

    expect(provider.isPremium, isTrue);
    expect(AdsService.instance.isPremium, isTrue);
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
}
