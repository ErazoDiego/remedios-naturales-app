import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';
import 'package:remedios_naturales_app/features/biblioteca/data/biblioteca_repository.dart';
import 'package:remedios_naturales_app/features/biblioteca/presentation/coleccion_screen.dart';
import 'package:remedios_naturales_app/presentation/providers/biblioteca_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tabler_icons/tabler_icons.dart';

/// ColeccionScreen: muro de bloqueo vs lista de recetas según el acceso.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PremiumProvider premium;
  late BibliotecaRepository repo;

  /// Filas del catálogo, leídas LAZY por el MockClient en cada request
  /// (mismo patrón que biblioteca_screen_test): se setean en el BODY
  /// del test; un segundo SupabaseClient dejaría el timer de autoRefresh
  /// pendiente y el test fallaría al final.
  List<Map<String, dynamic>>? filasCatalogo;

  Map<String, dynamic> filaJugos({String? imagen}) {
    return {
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
          'imagen': imagen,
          'keywords': ['jugo', 'verde'],
        },
      ],
    };
  }

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
          return jsonResp(request, filasCatalogo ?? [filaJugos()], 200);
        }
        return http.Response('Not found: ${request.url.path}', 404,
            request: request);
      }),
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  }

  setUp(() async {
    filasCatalogo = null; // default: sin placeholder (ícono)
    SharedPreferences.setMockInitialValues({});
    await UserService().clearAll();
    premium = PremiumProvider(payment: MockPaymentService());
    await premium.init();
    repo = BibliotecaRepository();
    repo.testClient = fakeClient();
  });

  tearDown(() {
    repo.testClient = null;
  });

  Future<void> pumpColeccion(WidgetTester tester) async {
    final biblioteca = BibliotecaProvider(premium: premium, repo: repo);
    await biblioteca.init();
    await tester.pumpWidget(
      ChangeNotifierProvider<PremiumProvider>.value(
        value: premium,
        child: ChangeNotifierProvider<BibliotecaProvider>.value(
          value: biblioteca,
          child: MaterialApp(
            home: ColeccionScreen(coleccionId: 'jugos'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'sin acceso: vista previa con índice candado + banner de desbloqueo',
      (tester) async {
    await pumpColeccion(tester);

    // Header de la colección + banner de compra.
    expect(find.text('Jugos naturales'), findsWidgets);
    expect(find.text('Esta colección no está desbloqueada. Comprá el pack '
        'para descargarla, o con Premium ya la tenés.'), findsOneWidget);
    expect(find.text('Desbloquear · USD 1.99'), findsOneWidget);
    // Índice del libro: la receta se VE pero con candado.
    expect(find.text('Jugo verde matinal'), findsOneWidget);
    expect(find.byIcon(TablerIcons.lock), findsOneWidget);
    expect(find.byIcon(TablerIcons.chevron_right), findsNothing);
  });

  testWidgets('sin acceso: Desbloquear abre el diálogo premium',
      (tester) async {
    await pumpColeccion(tester);

    await tester.tap(find.text('Desbloquear · USD 1.99'));
    await tester.pumpAndSettle();

    expect(find.text('Desbloquear sistema · USD 1.99'), findsOneWidget);
    expect(find.text('Ver Premium'), findsOneWidget);
  });

  testWidgets('sin acceso: tocar una receta candada abre el diálogo',
      (tester) async {
    await pumpColeccion(tester);

    await tester.tap(find.text('Jugo verde matinal'));
    await tester.pumpAndSettle();

    expect(find.text('Desbloquear sistema · USD 1.99'), findsOneWidget);
  });

  testWidgets('con pack de la colección: lista las recetas sin candado',
      (tester) async {
    await premium.purchasePack('jugos');
    await pumpColeccion(tester);

    expect(find.text('Jugo verde matinal'), findsOneWidget);
    expect(find.byIcon(TablerIcons.lock), findsNothing);
    expect(find.text('Desbloquear'), findsNothing);
  });

  testWidgets('con premium: lista las recetas', (tester) async {
    await premium.purchasePremium();
    await pumpColeccion(tester);

    expect(find.text('Jugo verde matinal'), findsOneWidget);
    expect(find.text('Desbloquear'), findsNothing);
  });

  testWidgets(
      'árbol real (main.dart): comprar desde el diálogo de la vista '
      'previa desbloquea la colección', (tester) async {
    // Reproduce el wiring de main.dart: MultiProvider donde BibliotecaProvider
    // toma el premium del árbol con context.read() (misma instancia).
    final router = GoRouter(
      initialLocation: '/biblioteca/jugos',
      routes: [
        GoRoute(
          path: '/biblioteca/:coleccionId',
          builder: (context, state) => ColeccionScreen(
            coleccionId: state.pathParameters['coleccionId']!,
          ),
        ),
        GoRoute(
          path: '/premium',
          builder: (context, state) => const Scaffold(
            body: Text('PremiumScreen'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => PremiumProvider(payment: MockPaymentService())
              ..init(),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                BibliotecaProvider(premium: context.read())..init(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Vista previa candada → diálogo → comprar el pack de la colección.
    expect(find.byIcon(TablerIcons.lock), findsOneWidget);
    await tester.tap(find.text('Desbloquear · USD 1.99'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desbloquear sistema · USD 1.99'));
    await tester.pumpAndSettle();

    // La compra se acredita y la vista rebuilda sin candados.
    expect(find.byIcon(TablerIcons.lock), findsNothing);
    expect(find.byIcon(TablerIcons.chevron_right), findsOneWidget);
  });

  testWidgets('árbol real (main.dart): Ver Premium navega a la pantalla',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/biblioteca/jugos',
      routes: [
        GoRoute(
          path: '/biblioteca/:coleccionId',
          builder: (context, state) => ColeccionScreen(
            coleccionId: state.pathParameters['coleccionId']!,
          ),
        ),
        GoRoute(
          path: '/premium',
          builder: (context, state) => const Scaffold(
            body: Text('PremiumScreen'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => PremiumProvider(payment: MockPaymentService())
              ..init(),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                BibliotecaProvider(premium: context.read())..init(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Desbloquear · USD 1.99'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver Premium'));
    await tester.pumpAndSettle();

    expect(find.text('PremiumScreen'), findsOneWidget);
  });

  testWidgets(
      'regresión wiring main.dart: el contexto del CREATE (no el capturado '
      'del build) inyecta la MISMA instancia → el diálogo desbloquea',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/biblioteca/jugos',
      routes: [
        GoRoute(
          path: '/biblioteca/:coleccionId',
          builder: (context, state) => ColeccionScreen(
            coleccionId: state.pathParameters['coleccionId']!,
          ),
        ),
        GoRoute(
          path: '/premium',
          builder: (context, state) => const Scaffold(
            body: Text('PremiumScreen'),
          ),
        ),
      ],
    );

    // El contexto del create (parámetro) SÍ ve al PremiumProvider anterior
    // del MultiProvider → instancia única → el diálogo desbloquea la vista.
    // (Con `create: (_) => ... context.read()` capturando el context del
    // build — arriba del MultiProvider — se crea una segunda instancia por
    // el fallback `premium ?? PremiumProvider()` y el flujo se rompe.)
    await tester.pumpWidget(
      Builder(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => PremiumProvider(payment: MockPaymentService())
                ..init(),
            ),
            ChangeNotifierProvider(
              create: (context) =>
                  BibliotecaProvider(premium: context.read())..init(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Desbloquear · USD 1.99'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desbloquear sistema · USD 1.99'));
    await tester.pumpAndSettle();

    expect(find.byIcon(TablerIcons.lock), findsNothing);
    expect(find.byIcon(TablerIcons.chevron_right), findsOneWidget);
  });

  testWidgets(
      'sin acceso: la receta candada MUESTRA su imagen + candado '
      '(como el núcleo: el bloqueo no oculta la foto)', (tester) async {
    filasCatalogo = [
      filaJugos(
        imagen: 'assets/images/recetas/jugos_01_limpiador_radiante.webp',
      ),
    ];
    await pumpColeccion(tester);

    expect(find.byIcon(TablerIcons.lock), findsOneWidget);
    // La imagen se ve aunque esté candada (mismo comportamiento que
    // category_screen: receta.imagen != null → Image.asset siempre).
    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    final assetName = (image.image as AssetImage).assetName;
    expect(assetName, 'assets/images/recetas/jugos_01_limpiador_radiante.webp');
  });

  testWidgets(
      'sin acceso: receta candada SIN imagen → color + ícono (fallback)',
      (tester) async {
    await pumpColeccion(tester);

    expect(find.byIcon(TablerIcons.lock), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(TablerIcons.cup), findsOneWidget);
  });

  testWidgets(
      'con pack: la receta muestra su imagen real (nítida, 800x446)',
      (tester) async {
    // flutter test empaqueta los assets del pubspec: la imagen real
    // carga de verdad en el listado desbloqueado.
    filasCatalogo = [
      filaJugos(
        imagen: 'assets/images/recetas/jugos_01_limpiador_radiante.webp',
      ),
    ];
    await premium.purchasePack('jugos');
    await pumpColeccion(tester);

    expect(find.text('Jugo verde matinal'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    final assetName = (image.image as AssetImage).assetName;
    // Desbloqueada → imagen full, no el LQIP.
    expect(assetName, 'assets/images/recetas/jugos_01_limpiador_radiante.webp');
  });

  testWidgets(
      'con pack: imagen rota (asset inexistente) → fallback color + '
      'ícono de preparación', (tester) async {
    filasCatalogo = [
      filaJugos(imagen: 'assets/images/recetas/no_existe.webp'),
    ];
    await premium.purchasePack('jugos');
    await pumpColeccion(tester);

    // En fake-async el decode del asset inexistente puede quedar pendiente
    // dentro del pumpAndSettle; con runAsync el file IO real corre y el
    // errorBuilder rebuilda con el fallback.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jugo verde matinal'), findsOneWidget);
    // errorBuilder → placeholder de color con el ícono de 'bebida'.
    // (El widget Image queda montado: el errorBuilder reemplaza el child
    // interno, no el Image en sí.)
    expect(find.byIcon(TablerIcons.cup), findsOneWidget);
  });
}
