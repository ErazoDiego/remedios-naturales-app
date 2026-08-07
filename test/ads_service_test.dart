import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/core/services/ads_service.dart';

void main() {
  group('AdsService', () {
    test('por defecto muestra anuncios (usuario no premium)', () {
      expect(AdsService.instance.shouldShowAds, isTrue);
      expect(AdsService.instance.isPremium, isFalse);
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
}
