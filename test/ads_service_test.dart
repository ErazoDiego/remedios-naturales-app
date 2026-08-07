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
    });
  });
}
