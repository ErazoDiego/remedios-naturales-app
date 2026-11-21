import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads/rewarded_ads_config.dart';
import 'ads/rewarded_ad_gateway.dart';

/// Servicio central de decisión publicitaria.
///
/// Las pantallas NO interactúan con el SDK de AdMob directamente:
/// consultan [shouldShowAds] / [shouldShowInterstitial] y el servicio
/// decide y ejecuta.
///
/// Cuando exista el pago (Google Play Billing), el wrapper de compras
/// llamará [setPremium] y los anuncios se apagarán en un solo lugar.
class AdsService {
  static final RewardedAdsConfig _defaultRewardedConfig =
      RewardedAdsConfig.fromEnvironment();

  AdsService._()
      : rewardedConfig = _defaultRewardedConfig,
        interstitialPolicy = InterstitialPolicy(),
        rewardedAdGateway =
            AdMobRewardedAdGateway.fromConfig(_defaultRewardedConfig);

  /// Instancia aislada para tests: permite inyectar la política con reloj
  /// controlado, la config y un gateway de rewarded falso. No usar en
  /// producción.
  @visibleForTesting
  AdsService.test(
    this.interstitialPolicy, {
    RewardedAdGateway? rewardedAdGateway,
    RewardedAdsConfig? rewardedConfig,
  })  : rewardedConfig = rewardedConfig ?? RewardedAdsConfig.test(),
        rewardedAdGateway = rewardedAdGateway ?? const NoOpRewardedAdGateway();

  static final AdsService instance = AdsService._();

  /// Cantidad de anuncios requeridos para un desbloqueo temporal.
  static const int rewardedAdsPorUnlock = 2;

  /// Política de espaciado del intersticial (lógica pura, sin SDK).
  final InterstitialPolicy interstitialPolicy;

  /// Configuración de rewarded (IDs de plataforma + flag compile-time).
  final RewardedAdsConfig rewardedConfig;

  /// Gateway de rewarded inyectable (NoOp en tests).
  final RewardedAdGateway rewardedAdGateway;

  /// ¿Se puede ofrecer el CTA de anuncios? Depende SOLO de la config y
  /// del flag, no del switch de tests ni del estado premium: el muro ya
  /// se muestra únicamente a usuarios sin acceso.
  bool get rewardedDisponible => rewardedConfig.estaDisponible;

  // ── Estado ──────────────────────────────────────────────────────────

  /// Usuario premium (pagó). Los anuncios NO se muestran.
  bool _premium = false;

  /// Interruptor global (útil para tests; default true).
  bool _enabled = true;

  /// ¿Hay un intersticial cargado y listo para mostrar?
  bool _interstitialReady = false;

  /// El intersticial cargado (o null si no hay o ya se mostró).
  InterstitialAd? _interstitial;

  /// Después de un rewarded exitoso se salta el intersticial de salida.
  bool _suppressNextInterstitial = false;

  // ── Consultas ───────────────────────────────────────────────────────

  /// ¿Deben mostrarse anuncios (banner) en este momento?
  bool get shouldShowAds => _enabled && !_premium;

  bool get isPremium => _premium;

  /// Solo para assertions en tests.
  @visibleForTesting
  bool get pendingInterstitialSuppression => _suppressNextInterstitial;

  /// ¿Debe mostrarse el intersticial ahora?
  /// Requiere: no premium, ads habilitados, un ad cargado y la política
  /// de espaciado satisfecha (no interrumpir la 1ª receta, mín. 5 min).
  bool get shouldShowInterstitial =>
      _enabled && !_premium && _interstitialReady && interstitialPolicy.isDue;

  // ── Mutaciones ──────────────────────────────────────────────────────

  /// Activa el modo premium (lo llamará el wrapper de pagos).
  void setPremium(bool value) => _premium = value;

  /// Desactiva/activa anuncios globalmente.
  /// Solo para tests: no llamar en producción.
  @visibleForTesting
  void setEnabledForTesting(bool value) => _enabled = value;

  /// Marca manualmente que hay un intersticial listo.
  /// Solo para tests unitarios (el SDK no corre en `flutter test`).
  @visibleForTesting
  void setInterstitialReadyForTesting(bool value) => _interstitialReady = value;

  @visibleForTesting
  void clearInterstitialSuppressionForTesting() =>
      _suppressNextInterstitial = false;

  // ── Rewarded ────────────────────────────────────────────────────────

  /// Muestra [rewardedAdsPorUnlock] anuncios para desbloquear una receta.
  ///
  /// [onConfirmAd] debe mostrar el disclosure ANTES de cada anuncio y
  /// devolver `false` si el usuario cancela. No hay recompensa parcial:
  /// si cualquiera falla, devuelve `false` y no se otorga acceso.
  Future<bool> mostrarAnunciosParaDesbloqueo({
    Future<bool> Function(int adNumber, int total)? onConfirmAd,
    void Function(int adNumber, int total)? onProgress,
  }) async {
    final total = rewardedAdsPorUnlock;
    for (var adNumber = 1; adNumber <= total; adNumber++) {
      if (!shouldShowAds) return false;
      if (onConfirmAd != null && !await onConfirmAd(adNumber, total)) {
        return false;
      }
      final rewardEarned = await rewardedAdGateway.show();
      if (!rewardEarned) return false;
      onProgress?.call(adNumber, total);
    }
    _suppressNextInterstitial = true;
    return true;
  }

  /// Fuerza saltear el próximo intersticial (lo consume [maybeShowInterstitial]).
  void suppressInterstitialOnce() => _suppressNextInterstitial = true;

  // ── Intersticial ────────────────────────────────────────────────────

  /// El usuario abrió una receta: registra la apertura (alimenta la
  /// política de espaciado). No muestra nada por sí mismo.
  void registerRecipeOpen() => interstitialPolicy.registerOpen();

  /// Precarga un intersticial (ad unit real de producción).
  /// Se llama tras inicializar AdMob y tras cada visualización, para que
  /// el siguiente siempre esté listo.
  void preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialReady = true;
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _interstitialReady = false;
        },
      ),
    );
  }

  /// Muestra el intersticial SI la política lo permite.
  /// Al mostrarlo, libera el ad y precarga el siguiente.
  Future<void> maybeShowInterstitial() async {
    if (_suppressNextInterstitial) {
      _suppressNextInterstitial = false;
      return;
    }
    if (!shouldShowInterstitial) return;

    final ad = _interstitial;
    _interstitial = null;
    _interstitialReady = false;
    if (ad == null) return;

    interstitialPolicy.markShown();
    await ad.show();
    preloadInterstitial(); // el siguiente ya viene cargado
  }

  /// Ad unit real de producción (unidad interstitial_yuyo de AdMob).
  static const String _interstitialAdUnitId =
      'ca-app-pub-4703211765619398/3092482015';
}

/// Política pura de espaciado de intersticiales — sin SDK, testeable.
///
/// Reglas:
/// - No interrumpir la primera receta abierta ([opensBeforeFirst] aperturas).
/// - Mínimo [minInterval] entre intersticiales consecutivos.
class InterstitialPolicy {
  InterstitialPolicy({
    DateTime Function()? now,
    this.minInterval = const Duration(minutes: 5),
    this.opensBeforeFirst = 2,
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Duration minInterval;
  final int opensBeforeFirst;

  int _recipeOpens = 0;
  DateTime? _lastShownAt;

  /// Aperturas de receta registradas en la sesión actual.
  int get recipeOpens => _recipeOpens;

  /// Cuándo se mostró el último intersticial (null = ninguno aún).
  DateTime? get lastShownAt => _lastShownAt;

  /// Registra una apertura de receta.
  void registerOpen() => _recipeOpens++;

  /// Marca que se mostró un intersticial ahora.
  void markShown() => _lastShownAt = _now();

  /// ¿Es momento de mostrar un intersticial según la política?
  bool get isDue {
    if (_recipeOpens < opensBeforeFirst) return false;
    final last = _lastShownAt;
    if (last == null) return true; // ya pasó la 1ª y nunca mostró → due
    return _now().difference(last) >= minInterval;
  }
}
