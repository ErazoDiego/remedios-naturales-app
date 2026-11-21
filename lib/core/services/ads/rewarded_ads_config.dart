import 'package:flutter/foundation.dart';

/// Configuración compile-time de los anuncios rewarded del unlock de 24 h.
///
/// Los IDs se inyectan con `--dart-define` (o `--dart-define-from-file`):
///
/// ```sh
/// flutter build appbundle \
///   --dart-define=YUYO_REWARDED_ANDROID_ID=ca-app-pub-.../... \
///   --dart-define=YUYO_REWARDED_IOS_ID=ca-app-pub-.../... \
///   --dart-define=YUYO_REWARDED_ENABLED=true
/// ```
///
/// En debug se usan los IDs oficiales de test de AdMob si no se pasan
/// defines. En release, si falta el ID de la plataforma, [estaDisponible]
/// es `false` y el CTA de anuncios NO se muestra (fail-visible, no un
/// botón que promete recompensa y después falla).
class RewardedAdsConfig {
  const RewardedAdsConfig({
    required this.androidAdUnitId,
    required this.iosAdUnitId,
    this.habilitado = true,
  });

  /// IDs oficiales de test (verificados en la documentación de AdMob).
  static const String androidTestAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosTestAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  static const String androidEnvKey = 'YUYO_REWARDED_ANDROID_ID';
  static const String iosEnvKey = 'YUYO_REWARDED_IOS_ID';
  static const String enabledEnvKey = 'YUYO_REWARDED_ENABLED';

  final String androidAdUnitId;
  final String iosAdUnitId;

  /// Flag compile-time: permite apagar la feature sin Remote Config.
  final bool habilitado;

  factory RewardedAdsConfig.fromEnvironment({bool? debug}) {
    final esDebug = debug ?? kDebugMode;
    final android = const String.fromEnvironment(androidEnvKey);
    final ios = const String.fromEnvironment(iosEnvKey);
    final habilitado =
        const bool.fromEnvironment(enabledEnvKey, defaultValue: true);

    if (esDebug) {
      return RewardedAdsConfig(
        androidAdUnitId: android.isEmpty ? androidTestAdUnitId : android,
        iosAdUnitId: ios.isEmpty ? iosTestAdUnitId : ios,
        habilitado: habilitado,
      );
    }

    // Release: NUNCA caemos a IDs de test. Sin define = feature apagada.
    return RewardedAdsConfig(
      androidAdUnitId: android,
      iosAdUnitId: ios,
      habilitado: habilitado,
    );
  }

  /// Config explícita para tests: no depende de `kDebugMode` ni de
  /// `defaultTargetPlatform`, así el gate se puede probar determinísticamente.
  factory RewardedAdsConfig.test({
    String androidAdUnitId = androidTestAdUnitId,
    String iosAdUnitId = iosTestAdUnitId,
    bool habilitado = true,
  }) =>
      RewardedAdsConfig(
        androidAdUnitId: androidAdUnitId,
        iosAdUnitId: iosAdUnitId,
        habilitado: habilitado,
      );

  String idPara({TargetPlatform? platform}) {
    final plataforma = platform ?? defaultTargetPlatform;
    return plataforma == TargetPlatform.android
        ? androidAdUnitId
        : iosAdUnitId;
  }

  String get idActual => idPara();

  /// ¿Se puede ofrecer el CTA de anuncios en esta plataforma?
  bool get estaDisponible => habilitado && idActual.isNotEmpty;
}
