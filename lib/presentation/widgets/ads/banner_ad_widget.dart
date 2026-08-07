import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/services/ads_service.dart';

/// Banner publicitario autocontenido.
///
/// - Consulta [AdsService.shouldShowAds]: si el usuario es premium, no muestra nada.
/// - Es TickerMode-aware: si la tab no está activa (IndexedStack/StatefulShellRoute),
///   pausa y libera el banner para no gastar impresiones invisibles.
/// - Usa el ad unit de PRUEBA de Google: en desarrollo SIEMPRE ads de prueba
///   (usar ads reales en dev = riesgo de suspensión de cuenta AdMob).
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, this.service});

  /// Inyectable para tests; por defecto usa el singleton.
  final AdsService? service;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  /// Ad unit de PRUEBA de Google (banner) — público y documentado.
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  AdsService get _ads => widget.service ?? AdsService.instance;

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  bool get _isVisible =>
      TickerMode.valuesOf(context).enabled && _ads.shouldShowAds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncVisibility();
  }

  void _syncVisibility() {
    if (_isVisible) {
      _loadBanner();
    } else {
      _disposeBanner();
    }
  }

  void _loadBanner() {
    if (_bannerAd != null || !mounted) return;

    final banner = BannerAd(
      adUnitId: _testBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    );

    _bannerAd = banner; // marca "en carga" para no duplicar requests
    _isLoaded = false;
    banner.load();
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }

  @override
  void dispose() {
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerAd;
    if (!_isVisible || !_isLoaded || banner == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}
