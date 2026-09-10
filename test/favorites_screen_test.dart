import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/core/services/ads_service.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/data/services/auth_service.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';
import 'package:remedios_naturales_app/features/biblioteca/data/biblioteca_repository.dart';
import 'package:remedios_naturales_app/features/biblioteca/domain/favorito_coleccion.dart';
import 'package:remedios_naturales_app/presentation/providers/biblioteca_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/recetas_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/user_provider.dart';
import 'package:remedios_naturales_app/presentation/screens/favorites/favorites_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tabler_icons/tabler_icons.dart';

/// FavoritesScreen: agrupa los favoritos por ORIGEN (colecciones,
/// sistemas corporales, recetas propias) manteniendo el orden de marcado.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PremiumProvider premium;
  late BibliotecaRepository repo;
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
    // Sin ads en tests: el banner no carga un BannerAd real.
    AdsService.instance.setEnabledForTesting(false);
    AdsService.instance.setPremium(false);
    SharedPreferences.setMockInitialValues({});
    // UserService es SINGLETON: su cache en memoria sobrevive a
    // setMockInitialValues; setSession sin argumentos lo invalida.
    UserService().setSession();
    // AuthService singleton con cliente inyectable: UserProvider.init()
    // toca currentUser (sin esto peta "Supabase.instance no inicializado").
    authClient = fakeClient();
    AuthService().client = authClient;
    premium = PremiumProvider(payment: MockPaymentService());
    await premium.init();
    repo = BibliotecaRepository();
    repo.testClient = fakeClient();
  });

  tearDown(() {
    repo.testClient = null;
    authClient.dispose();
  });

  Future<void> pumpFavorites(WidgetTester tester) async {
    final userProvider = UserProvider(service: UserService(), auth: AuthService());
    await userProvider.init(); // carga el perfil local (favoritos de prefs)
    final biblioteca = BibliotecaProvider(premium: premium, repo: repo);
    await biblioteca.init();

    final router = GoRouter(
      initialLocation: '/favorites',
      routes: [
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/remedy/:recipeId',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('ficha receta')),
          ),
        ),
        GoRoute(
          path: '/biblioteca/:coleccionId/:recetaId',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('ficha colección')),
          ),
        ),
        GoRoute(
          path: '/mis-recetas/:id',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('ficha propia')),
          ),
        ),
        GoRoute(
          path: '/lista-compras',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('lista')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RecetasProvider()),
          ChangeNotifierProvider<PremiumProvider>.value(value: premium),
          ChangeNotifierProvider<BibliotecaProvider>.value(
            value: biblioteca,
          ),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('agrupa por origen: sistema + colección, en orden de aparición',
      (tester) async {
    // Orden de marcado: digestivo, jugos (colección), digestivo.
    SharedPreferences.setMockInitialValues({
      'user_profile': json.encode({
        'id': 'anonymous',
        'nombre': 'Usuario',
        'favoritos': [
          'digestivo_01',
          FavoritoColeccion.idDe('jugos', 'jugos_01'),
          'digestivo_02',
        ],
      }),
    });
    UserService().setSession();

    await pumpFavorites(tester);

    // Headers en orden de primera aparición.
    final headers = tester
        .widgetList<Text>(find.byWidgetPredicate(
          (w) => w is Text && w.data == 'SISTEMA DIGESTIVO',
        ))
        .length;
    expect(headers, 1);
    expect(find.text('JUGOS NATURALES'), findsOneWidget);

    // Ambas recetas del catálogo van bajo el mismo header (SISTEMA
    // DIGESTIVO aparece una sola vez), la de colección aparte.
    expect(find.byIcon(TablerIcons.chevron_right), findsNWidgets(3));
    expect(find.text('Jugo verde matinal'), findsOneWidget);

    // Orden visual: el header del sistema está ANTES que el de jugos.
    final ySistema = tester.getTopLeft(find.text('SISTEMA DIGESTIVO')).dy;
    final yJugos = tester.getTopLeft(find.text('JUGOS NATURALES')).dy;
    expect(ySistema, lessThan(yJugos));
  });

  testWidgets('favorito de colección sin colección descargada se omite',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_profile': json.encode({
        'id': 'anonymous',
        'nombre': 'Usuario',
        'favoritos': [FavoritoColeccion.idDe('kefir', 'kefir_01')],
      }),
    });
    UserService().setSession();

    await pumpFavorites(tester);

    // El favorito no resuelve (kefir no está en el catálogo fake): se
    // omite sin romper → estado vacío honesto.
    expect(find.text('No tenés favoritos aún'), findsOneWidget);
  });

  testWidgets('sin favoritos: estado vacío', (tester) async {
    await pumpFavorites(tester);

    expect(find.text('No tenés favoritos aún'), findsOneWidget);
  });
}