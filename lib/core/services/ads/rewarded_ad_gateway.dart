import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'rewarded_ads_config.dart';

/// Contrato mínimo para mostrar un anuncio rewarded.
///
/// Devuelve `true` SOLO cuando el SDK disparó `onUserEarnedReward`:
/// cerrar el anuncio antes de tiempo o un error NUNCA cuenta como recompensa.
abstract class RewardedAdGateway {
  Future<bool> show();
}

/// Gateway real de AdMob.
///
/// El ad unit se resuelve desde [RewardedAdsConfig] (dart-define). Si la
/// configuración está vacía, la llamada falla CERRADA: no otorga reward.
class AdMobRewardedAdGateway implements RewardedAdGateway {
  AdMobRewardedAdGateway({
    required String adUnitId,
    this.timeout = const Duration(seconds: 60),
  }) : _adUnitId = adUnitId;

  factory AdMobRewardedAdGateway.fromConfig(RewardedAdsConfig config) =>
      AdMobRewardedAdGateway(adUnitId: config.idActual);

  final String _adUnitId;
  final Duration timeout;

  /// Conveniencia para callers que no inyectan config (usa dart-define).
  static String get defaultAdUnitId =>
      RewardedAdsConfig.fromEnvironment().idActual;

  @override
  Future<bool> show() async {
    if (_adUnitId.isEmpty) {
      debugPrint(
        'AdMobRewardedAdGateway: ad unit rewarded no configurado; '
        'no se otorga recompensa.',
      );
      return false;
    }

    final completer = Completer<bool>();
    var rewardEarned = false;
    RewardedAd? ad;

    void complete(bool value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (loadedAd) async {
          ad = loadedAd;
          loadedAd.fullScreenContentCallback = FullScreenContentCallback(
            onAdFailedToShowFullScreenContent: (shownAd, error) {
              debugPrint('RewardedAd failed to show: $error');
              shownAd.dispose();
              complete(false);
            },
            onAdDismissedFullScreenContent: (shownAd) {
              shownAd.dispose();
              complete(rewardEarned);
            },
          );
          try {
            await loadedAd.show(
              onUserEarnedReward: (
                AdWithoutView adWithoutView,
                RewardItem rewardItem,
              ) {
                rewardEarned = true;
              },
            );
          } catch (error) {
            debugPrint('RewardedAd show error: $error');
            loadedAd.dispose();
            complete(false);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          complete(false);
        },
      ),
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        debugPrint('RewardedAd timeout; no se otorga recompensa.');
        ad?.dispose();
        return false;
      },
    );
  }
}

/// Gateway no-op para tests que no ejercitan rewarded.
class NoOpRewardedAdGateway implements RewardedAdGateway {
  const NoOpRewardedAdGateway();

  @override
  Future<bool> show() async => false;
}
