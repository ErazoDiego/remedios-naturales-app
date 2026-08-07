import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/services/ads_service.dart';

/// Banner publicitario autocontenido.
///
/// - Consulta [AdsService.shouldShowAds]: si el usuario es premium, no muestra nada.
/// - Es TickerMode-aware: si la tab no está activa (IndexedStack/StatefulShellRoute),
///   pausa y libera el banner para no gastar impresiones invisibles.
/// - Ad unit real de producción (banner_yuyo). En desarrollo SIEMPRE ads de
///   prueba (usar ads reales en dev = riesgo de suspensión de cuenta AdMob).
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, this.service});

  /// Inyectable para tests; por defecto usa el singleton.
  final AdsService? service;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  /// Ad unit real de producción (unidad banner_yuyo de AdMob).
  static const String _bannerAdUnitId =
      'ca-app-pub-4703211765619398/6551159534';

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
      adUnitId: _bannerAdUnitId,
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

    // SafeArea: en Android 15+ (edge-to-edge forzado con targetSdk 35/36)
    // la barra de navegación del sistema (back/home/recent) se superpone
    // al banner. SafeArea respeta el inset inferior solo donde existe
    // (padding 0 en Android <= 14 => cero regresión).
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: SizedBox(
            width: banner.size.width.toDouble(),
            height: banner.size.height.toDouble(),
            child: AdWidget(ad: banner),
          ),
        ),
      ),
    );
  }
}
