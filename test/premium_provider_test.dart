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
}
