import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/core/services/ads/rewarded_ads_config.dart';
import 'package:remedios_naturales_app/core/services/ads/rewarded_ad_gateway.dart';
import 'package:remedios_naturales_app/core/services/ads_service.dart';

void main() {
  group('RewardedAdsConfig', () {
    test('elige el ID según la plataforma', () {
      const config = RewardedAdsConfig(
        androidAdUnitId: 'android-id',
        iosAdUnitId: 'ios-id',
      );
      expect(config.idPara(platform: TargetPlatform.android), 'android-id');
      expect(config.idPara(platform: TargetPlatform.iOS), 'ios-id');
    });

    test('sin ID en la plataforma actual NO habilita el CTA', () {
      const config = RewardedAdsConfig(
        androidAdUnitId: '',
        iosAdUnitId: '',
      );
      expect(config.estaDisponible, isFalse);
    });

    test('con flag apagado NO habilita el CTA aunque haya IDs', () {
      const config = RewardedAdsConfig(
        androidAdUnitId: 'android-id',
        iosAdUnitId: 'ios-id',
        habilitado: false,
      );
      expect(config.estaDisponible, isFalse);
    });

    test('factory de test usa IDs de test sin depender del entorno', () {
      final config = RewardedAdsConfig.test();
      expect(config.androidAdUnitId, RewardedAdsConfig.androidTestAdUnitId);
      expect(config.iosAdUnitId, RewardedAdsConfig.iosTestAdUnitId);
      expect(config.estaDisponible, isTrue);
    });
  });

  group('AdsService', () {
    test('por defecto muestra anuncios (usuario no premium)', () {
      expect(AdsService.instance.shouldShowAds, isTrue);
      expect(AdsService.instance.isPremium, isFalse);
    });

    test('rewardedDisponible respeta la config inyectada', () {
      final service = AdsService.test(
        InterstitialPolicy(),
        rewardedConfig: const RewardedAdsConfig(
          androidAdUnitId: '',
          iosAdUnitId: '',
        ),
      );
      expect(service.rewardedDisponible, isFalse);
    });

    test('con premium activo NO muestra anuncios', () {
      AdsService.instance.setPremium(true);
      expect(AdsService.instance.shouldShowAds, isFalse);
      expect(AdsService.instance.isPremium, isTrue);
    });

    test('al desactivar premium vuelve a mostrar anuncios', () {
      AdsService.instance.setPremium(true);
      AdsService.instance.setPremium(false);
      expect(AdsService.instance.shouldShowAds, isTrue);
    });

    test('deshabilitado globalmente (modo test) nunca muestra anuncios', () {
      AdsService.instance.setPremium(false);
      AdsService.instance.setEnabledForTesting(false);
      expect(AdsService.instance.shouldShowAds, isFalse);

      AdsService.instance.setEnabledForTesting(true);
      expect(AdsService.instance.shouldShowAds, isTrue);
    });

    tearDown(() {
      // Restablece el singleton entre tests
      AdsService.instance.setPremium(false);
      AdsService.instance.setEnabledForTesting(true);
      AdsService.instance.setInterstitialReadyForTesting(false);
    });
  });

  group('InterstitialPolicy', () {
    late DateTime fakeNow;
    late InterstitialPolicy policy;

    setUp(() {
      fakeNow = DateTime(2026, 8, 7, 12, 0, 0);
      policy = InterstitialPolicy(now: () => fakeNow);
    });

    test('no es momento con menos de 2 aperturas de receta', () {
      policy.registerOpen();
      expect(policy.isDue, isFalse);
    });

    test('es momento al abrir la 2ª receta sin haber mostrado nunca', () {
      policy.registerOpen();
      policy.registerOpen();
      expect(policy.isDue, isTrue);
    });

    test('no es momento si pasó menos de 5 minutos desde el último', () {
      policy.registerOpen();
      policy.registerOpen();
      policy.markShown();
      fakeNow = fakeNow.add(const Duration(minutes: 4, seconds: 59));
      expect(policy.isDue, isFalse);
    });

    test('es momento si pasaron 5 minutos o más', () {
      policy.registerOpen();
      policy.registerOpen();
      policy.markShown();
      fakeNow = fakeNow.add(const Duration(minutes: 5));
      expect(policy.isDue, isTrue);
    });

    test('registerOpen cuenta las aperturas', () {
      policy.registerOpen();
      policy.registerOpen();
      policy.registerOpen();
      expect(policy.recipeOpens, 3);
    });
  });

  group('AdsService intersticial', () {
    late InterstitialPolicy policy;
    late AdsService service;

    setUp(() {
      policy = InterstitialPolicy(now: () => DateTime(2026, 8, 7, 12, 0, 0));
      service = AdsService.test(policy);
    });

    test('no muestra si el usuario es premium', () {
      service.setPremium(true);
      service.setInterstitialReadyForTesting(true);
      policy.registerOpen();
      policy.registerOpen();
      expect(service.shouldShowInterstitial, isFalse);
    });

    test('no muestra si los ads están deshabilitados globalmente', () {
      service.setEnabledForTesting(false);
      service.setInterstitialReadyForTesting(true);
      policy.registerOpen();
      policy.registerOpen();
      expect(service.shouldShowInterstitial, isFalse);
    });

    test('no muestra si no hay intersticial cargado', () {
      policy.registerOpen();
      policy.registerOpen();
      expect(service.shouldShowInterstitial, isFalse);
    });

    test('muestra con ad cargado y política satisfecha', () {
      service.setInterstitialReadyForTesting(true);
      policy.registerOpen();
      policy.registerOpen();
      expect(service.shouldShowInterstitial, isTrue);
    });

    test('registerRecipeOpen alimenta la política', () {
      service.registerRecipeOpen();
      service.registerRecipeOpen();
      expect(policy.recipeOpens, 2);
    });
  });

  group('AdsService rewarded', () {
    late AdsService service;
    late _FakeRewardedAdGateway gateway;
    late List<int> confirms;
    late List<int> progress;

    AdsService buildService(List<bool> outcomes) {
      gateway = _FakeRewardedAdGateway(outcomes);
      service = AdsService.test(
        InterstitialPolicy(now: () => DateTime(2026, 11, 19, 12)),
        rewardedAdGateway: gateway,
      );
      confirms = [];
      progress = [];
      return service;
    }

    test('dos rewarded exitosos: otorga y marca supresión del intersticial',
        () async {
      final svc = buildService([true, true]);

      final ok = await svc.mostrarAnunciosParaDesbloqueo(
        onConfirmAd: (n, total) async {
          confirms.add(n);
          return true;
        },
        onProgress: (n, total) => progress.add(n),
      );

      expect(ok, isTrue);
      expect(gateway.calls, 2);
      expect(confirms, [1, 2]);
      expect(progress, [1, 2]);
      expect(svc.pendingInterstitialSuppression, isTrue);

      await svc.maybeShowInterstitial();
      expect(svc.pendingInterstitialSuppression, isFalse);
    });

    test('cancelar el primer disclosure: no muestra anuncios', () async {
      final svc = buildService([true, true]);

      final ok = await svc.mostrarAnunciosParaDesbloqueo(
        onConfirmAd: (n, total) async => false,
      );

      expect(ok, isFalse);
      expect(gateway.calls, 0);
      expect(svc.pendingInterstitialSuppression, isFalse);
    });

    test('cancelar el segundo disclosure: solo se mostró 1 y no otorga',
        () async {
      final svc = buildService([true, true]);

      final ok = await svc.mostrarAnunciosParaDesbloqueo(
        onConfirmAd: (n, total) async => n == 1,
      );

      expect(ok, isFalse);
      expect(gateway.calls, 1);
      expect(svc.pendingInterstitialSuppression, isFalse);
    });

    test('falla el primer anuncio: no otorga', () async {
      final svc = buildService([false, true]);

      final ok = await svc.mostrarAnunciosParaDesbloqueo();

      expect(ok, isFalse);
      expect(gateway.calls, 1);
      expect(svc.pendingInterstitialSuppression, isFalse);
    });

    test('falla el segundo anuncio: no otorga (sin recompensa parcial)',
        () async {
      final svc = buildService([true, false]);

      final ok = await svc.mostrarAnunciosParaDesbloqueo();

      expect(ok, isFalse);
      expect(gateway.calls, 2);
      expect(svc.pendingInterstitialSuppression, isFalse);
    });

    test('premium nunca ve rewarded', () async {
      final svc = buildService([true, true]);
      svc.setPremium(true);

      final ok = await svc.mostrarAnunciosParaDesbloqueo();

      expect(ok, isFalse);
      expect(gateway.calls, 0);
    });

    test('ads deshabilitados globalmente: no muestra rewarded', () async {
      final svc = buildService([true, true]);
      svc.setEnabledForTesting(false);

      final ok = await svc.mostrarAnunciosParaDesbloqueo();

      expect(ok, isFalse);
      expect(gateway.calls, 0);
    });
  });
}

class _FakeRewardedAdGateway implements RewardedAdGateway {
  _FakeRewardedAdGateway(this._outcomes);

  final List<bool> _outcomes;
  int calls = 0;

  @override
  Future<bool> show() async {
    final result = _outcomes[calls];
    calls++;
    return result;
  }
}
