# remedios_naturales_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Unlock por anuncios rewarded (Yuyo)

Los ad units de producción NO se versionan. Copiá
`env/rewarded_ads.example.json` como `env/rewarded_ads.json` y reemplazá
los placeholders por los IDs creados en AdMob (uno por plataforma).
`env/*.json` está en `.gitignore`, salvo el example.

En debug se usan automáticamente los IDs oficiales de test de AdMob,
así que `flutter run` funciona sin configurar nada.

Builds de release:

```sh
flutter build appbundle --dart-define-from-file=env/rewarded_ads.json
flutter build ipa --dart-define-from-file=env/rewarded_ads.json
```

También podés overridear valores puntuales:

```sh
flutter build appbundle \
  --dart-define=YUYO_REWARDED_ANDROID_ID=ca-app-pub-.../... \
  --dart-define=YUYO_REWARDED_ENABLED=false
```

Si falta el ID de la plataforma o `YUYO_REWARDED_ENABLED=false`, el botón
"Mirar 2 anuncios · 24 h" directamente NO se muestra (*fail-visible*):
nunca se le promete una recompensa que no se puede entregar.
