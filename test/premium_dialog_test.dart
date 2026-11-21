import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/core/services/ads/rewarded_ads_config.dart';
import 'package:remedios_naturales_app/core/services/ads/rewarded_ad_gateway.dart';
import 'package:remedios_naturales_app/core/services/ads_service.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:remedios_naturales_app/presentation/widgets/premium/premium_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// showPremiumDialog: CTA premium + pack del sistema + unlock por 2 ads.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserService().clearAll();
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    String? sistemaId,
    String? recipeId,
    PremiumProvider? premium,
  }) async {
    final provider = premium ?? PremiumProvider(payment: MockPaymentService());

    // El provider va ARRIBA del MaterialApp (como en main.dart): el
    // diálogo abre una ruta nueva y necesita verlo desde ahí.
    await tester.pumpWidget(
      ChangeNotifierProvider<PremiumProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showPremiumDialog(
                    context,
                    sistemaId: sistemaId,
                    recipeId: recipeId,
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  PremiumProvider providerConAds(
    _FakeRewardedAdGateway gateway, {
    RewardedAdsConfig? config,
  }) =>
      PremiumProvider(
        payment: MockPaymentService(),
        adsService: AdsService.test(
          InterstitialPolicy(),
          rewardedAdGateway: gateway,
          rewardedConfig: config,
        ),
      );

  testWidgets('sin sistemaId: ofrece solo Ahora no y Ver Premium',
      (tester) async {
    await pumpDialog(tester);

    expect(find.text('Ahora no'), findsOneWidget);
    expect(find.text('Ver Premium'), findsOneWidget);
    expect(find.text('Desbloquear sistema'), findsNothing);
    expect(find.text('Mirar 2 anuncios · 24 h'), findsNothing);
  });

  testWidgets('con sistemaId: ofrece Desbloquear sistema', (tester) async {
    await pumpDialog(tester, sistemaId: 'digestivo');

    expect(find.text('Desbloquear sistema'), findsOneWidget);
  });

  testWidgets('Desbloquear sistema compra el pack del sistema',
      (tester) async {
    await pumpDialog(tester, sistemaId: 'digestivo');

    await tester.tap(find.text('Desbloquear sistema'));
    await tester.pumpAndSettle();

    final premium = tester
        .element(find.byType(Scaffold).first)
        .read<PremiumProvider>();
    expect(premium.packs, contains('yuyo_pack_digestivo'));
    expect(premium.isPremium, isFalse);
  });

  testWidgets('receta bloqueada elegible: ofrece Mirar 2 anuncios · 24 h',
      (tester) async {
    await pumpDialog(tester, recipeId: 'digestivo_01');

    expect(find.text('Mirar 2 anuncios · 24 h'), findsOneWidget);
  });

  testWidgets('receta del muestreo gratis NO ofrece unlock por anuncios',
      (tester) async {
    await pumpDialog(tester, recipeId: 'digestivo_03');

    expect(find.text('Mirar 2 anuncios · 24 h'), findsNothing);
  });

  testWidgets('flag apagado oculta el CTA aunque la receta sea elegible',
      (tester) async {
    final premium = providerConAds(
      _FakeRewardedAdGateway(const [true, true]),
      config: const RewardedAdsConfig(
        androidAdUnitId: RewardedAdsConfig.androidTestAdUnitId,
        iosAdUnitId: RewardedAdsConfig.iosTestAdUnitId,
        habilitado: false,
      ),
    );
    await pumpDialog(
      tester,
      recipeId: 'digestivo_01',
      premium: premium,
    );

    expect(premium.rewardedDisponible, isFalse);
    expect(find.text('Mirar 2 anuncios · 24 h'), findsNothing);
  });

  testWidgets('sin ad unit de producción oculta el CTA (fail-visible)',
      (tester) async {
    final premium = providerConAds(
      _FakeRewardedAdGateway(const [true, true]),
      config: const RewardedAdsConfig(
        androidAdUnitId: '',
        iosAdUnitId: '',
      ),
    );
    await pumpDialog(
      tester,
      recipeId: 'digestivo_01',
      premium: premium,
    );

    expect(premium.rewardedDisponible, isFalse);
    expect(find.text('Mirar 2 anuncios · 24 h'), findsNothing);
  });

  testWidgets('2 anuncios completos: disclosure por cada uno y desbloqueo',
      (tester) async {
    final gateway = _FakeRewardedAdGateway(const [true, true]);
    final premium = providerConAds(gateway);
    await pumpDialog(
      tester,
      sistemaId: 'digestivo',
      recipeId: 'digestivo_01',
      premium: premium,
    );

    await tester.tap(find.text('Mirar 2 anuncios · 24 h'));
    await tester.pumpAndSettle();
    expect(find.text('Anuncio 1 de 2'), findsOneWidget);
    expect(
      find.textContaining('La recompensa se entrega recién'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver anuncio 1 de 2'));
    await tester.pumpAndSettle();
    expect(find.text('Anuncio 2 de 2'), findsOneWidget);

    await tester.tap(find.text('Ver anuncio 2 de 2'));
    await tester.pumpAndSettle();

    expect(gateway.calls, 2);
    expect(premium.puedeAccederAReceta('digestivo_01'), isTrue);
    expect(find.text('Yuyo Premium'), findsNothing);
    expect(find.text('Receta desbloqueada por 24 h'), findsOneWidget);
  });

  testWidgets('cancelar el disclosure no otorga acceso y mantiene el muro',
      (tester) async {
    final gateway = _FakeRewardedAdGateway(const [true, true]);
    final premium = providerConAds(gateway);
    await pumpDialog(
      tester,
      recipeId: 'digestivo_01',
      premium: premium,
    );

    await tester.tap(find.text('Mirar 2 anuncios · 24 h'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(gateway.calls, 0);
    expect(premium.puedeAccederAReceta('digestivo_01'), isFalse);
    expect(find.text('Yuyo Premium'), findsOneWidget);
    expect(
      find.text('No se completaron los anuncios; la receta sigue bloqueada.'),
      findsOneWidget,
    );
  });

  testWidgets('helper del muro inline NO cierra la pantalla al desbloquear',
      (tester) async {
    final gateway = _FakeRewardedAdGateway(const [true, true]);
    final premium = providerConAds(gateway);

    await tester.pumpWidget(
      ChangeNotifierProvider<PremiumProvider>.value(
        value: premium,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('PANTALLA INLINE'),
                    ElevatedButton(
                      onPressed: () => desbloquearRecetaConAnuncios(
                        context,
                        premium,
                        'digestivo_01',
                      ),
                      child: const Text('desbloquear'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('desbloquear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver anuncio 1 de 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver anuncio 2 de 2'));
    await tester.pumpAndSettle();

    expect(gateway.calls, 2);
    expect(premium.puedeAccederAReceta('digestivo_01'), isTrue);
    // El pop lo hace el diálogo, no el helper: el muro sigue en pantalla.
    expect(find.text('PANTALLA INLINE'), findsOneWidget);
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
