import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/core/services/ads_service.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/data/services/auth_service.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';
import 'package:remedios_naturales_app/features/biblioteca/data/biblioteca_repository.dart';
import 'package:remedios_naturales_app/features/biblioteca/domain/favorito_coleccion.dart';
import 'package:remedios_naturales_app/features/biblioteca/presentation/receta_coleccion_screen.dart';
import 'package:remedios_naturales_app/presentation/providers/biblioteca_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tabler_icons/tabler_icons.dart';

/// RecetaColeccionScreen: detalle de una receta de colección con corazón
/// de favoritos (ID compuesto `col:<coleccionId>:<recetaId>`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PremiumProvider premium;
  late BibliotecaRepository repo;
  late UserProvider userProvider;
  late SupabaseClient authClient;

  Map<String, dynamic> filaJugos() => {
        'id': 'jugos',
        'nombre': 'Jugos naturales',
        'descripcion': 'Jugos de prueba',
        'icono': 'glass-full',
        'color': 'verde',
        'activa': true,
        'orden': 1,
        'version': 1,
        'recetas': [
          {
            'id': 'jugos_01',
            'nombre': 'Jugo verde matinal',
            'descripcion': 'Apio y manzana',
            'idealPara': ['Energía'],
            'tipo': 'interno',
            'tipoPreparacion': 'bebida',
            'precaucion': 'cuidado',
            'ingredientes': ['apio'],
            'preparacion': ['licuar'],
            'dosis': '1 vaso',
            'almacenamiento': 'frasco',
            'keywords': ['jugo', 'verde'],
          },
        ],
      };

  SupabaseClient fakeClient() {
    http.Response jsonResp(http.Request request, Object? body, int status) {
      return http.Response(
        body == null ? '' : json.encode(body),
        status,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }

    return SupabaseClient(
      'http://localhost:54321',
      'fake-publishable-key',
      httpClient: MockClient((request) async {
        if (request.url.path == '/rest/v1/colecciones') {
          return jsonResp(request, [filaJugos()], 200);
        }
        return http.Response('Not found: ${request.url.path}', 404,
            request: request);
      }),
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  }

  setUp(() async {
    // Sin ads en tests: el banner no debe cargar un BannerAd real.
    AdsService.instance.setEnabledForTesting(false);
    AdsService.instance.setPremium(false);
    SharedPreferences.setMockInitialValues({});
    // UserService es SINGLETON: su cache en memoria sobrevive a
    // setMockInitialValues; setSession sin argumentos lo invalida.
    UserService().setSession();
    // AuthService es singleton con `client` inyectable: sin esto, el
    // UserProvider.init() del test de límite peta con
    // "You must initialize the supabase instance" (mismo patrón de
    // auth_service_test).
    authClient = fakeClient();
    AuthService().client = authClient;
    premium = PremiumProvider(payment: MockPaymentService());
    await premium.init();
    repo = BibliotecaRepository();
    repo.testClient = fakeClient();
    // UserProvider SIN init(): sin suscripción de auth ni fetches remotos;
    // con sesión local anónima, isFavorite/addFavorite operan en prefs.
    userProvider =
        UserProvider(service: UserService(), auth: AuthService());
  });

  tearDown(() {
    repo.testClient = null;
    // dispose cancela el timer de autoRefresh del GoTrueClient; el de
    // auth también (cada setUp crea uno nuevo para el singleton).
    authClient.dispose();
  });

  Future<void> pumpDetalle(WidgetTester tester) async {
    final biblioteca = BibliotecaProvider(premium: premium, repo: repo);
    await biblioteca.init();
    // Acceso a la colección para que el cuerpo se renderice (el corazón
    // aparece igual con muro, pero así validamos la pantalla completa).
    await biblioteca.comprar('jugos');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PremiumProvider>.value(value: premium),
          ChangeNotifierProvider<BibliotecaProvider>.value(
            value: biblioteca,
          ),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ],
        child: const MaterialApp(
          home: RecetaColeccionScreen(
            coleccionId: 'jugos',
            recetaId: 'jugos_01',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el detalle de receta de colección tiene corazón de favorito',
      (tester) async {
    await pumpDetalle(tester);

    // Corazón vacío (no favorito todavía) en el AppBar.
    expect(find.byIcon(TablerIcons.heart), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('tocar el corazón guarda el ID compuesto col:coleccion:receta',
      (tester) async {
    await pumpDetalle(tester);

    await tester.tap(find.byIcon(TablerIcons.heart));
    await tester.pumpAndSettle();

    expect(
      userProvider.profile?.favoritos,
      contains(FavoritoColeccion.idDe('jugos', 'jugos_01')),
    );
    // El corazón queda lleno.
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('favorito ya guardado: el corazón abre lleno',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_profile': json.encode({
        'id': 'anonymous',
        'nombre': 'Usuario',
        'favoritos': [FavoritoColeccion.idDe('jugos', 'jugos_01')],
      }),
    });
    UserService().setSession(); // recargar perfil local desde prefs

    await pumpDetalle(tester);

    expect(find.byIcon(Icons.favorite), findsOneWidget);

    // Tocar de nuevo lo quita de favoritos.
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(
      userProvider.profile?.favoritos,
      isNot(contains(FavoritoColeccion.idDe('jugos', 'jugos_01'))),
    );
  });

  testWidgets('límite FREE (5): el corazón no agrega y avisa con el diálogo',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_profile': json.encode({
        'id': 'anonymous',
        'nombre': 'Usuario',
        'favoritos': ['a', 'b', 'c', 'd', 'e'],
      }),
    });
    UserService().setSession();
    // _toggleFavorito lee userProvider.profile (cache del provider), no
    // solo el UserService: sin loadProfile, profile es null y el límite
    // se vería como 0. init() ya hace loadProfile → 5 favoritos.
    await userProvider.init();

    await pumpDetalle(tester);

    await tester.tap(find.byIcon(TablerIcons.heart));
    await tester.pumpAndSettle();

    expect(find.text('Llegaste al límite de favoritos'), findsOneWidget);
    expect(
      userProvider.profile?.favoritos,
      isNot(contains(FavoritoColeccion.idDe('jugos', 'jugos_01'))),
    );
  });

  testWidgets('con premium no hay límite: agrega sin diálogo', (tester) async {
    await premium.purchaseLifetime();
    await pumpDetalle(tester);

    await tester.tap(find.byIcon(TablerIcons.heart));
    await tester.pumpAndSettle();

    expect(find.text('Llegaste al límite de favoritos'), findsNothing);
    expect(
      userProvider.profile?.favoritos,
      contains(FavoritoColeccion.idDe('jugos', 'jugos_01')),
    );
  });
}