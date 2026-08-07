import 'package:flutter/foundation.dart';

/// Servicio central de decisión publicitaria.
///
/// Las pantallas NO interactúan con el SDK de AdMob directamente:
/// consultan [shouldShowAds] y el [BannerAdWidget] decide qué mostrar.
///
/// Cuando exista el pago (Google Play Billing), el wrapper de compras
/// llamará [setPremium] y los anuncios se apagarán en un solo lugar.
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  // ── Estado ──────────────────────────────────────────────────────────

  /// Usuario premium (pagó). Los anuncios NO se muestran.
  bool _premium = false;

  /// Interruptor global (útil para tests de widget; default true).
  bool _enabled = true;

  // ── Consultas ───────────────────────────────────────────────────────

  /// ¿Deben mostrarse anuncios en este momento?
  bool get shouldShowAds => _enabled && !_premium;

  bool get isPremium => _premium;

  // ── Mutaciones ──────────────────────────────────────────────────────

  /// Activa el modo premium (lo llamará el wrapper de pagos).
  void setPremium(bool value) => _premium = value;

  /// Desactiva/activa anuncios globalmente.
  /// Solo para tests: no llamar en producción.
  @visibleForTesting
  void setEnabledForTesting(bool value) => _enabled = value;
}
