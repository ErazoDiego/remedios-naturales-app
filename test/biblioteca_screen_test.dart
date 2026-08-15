import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';
import 'package:remedios_naturales_app/features/biblioteca/data/biblioteca_repository.dart';
import 'package:remedios_naturales_app/features/biblioteca/presentation/biblioteca_screen.dart';
import 'package:remedios_naturales_app/presentation/providers/biblioteca_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tabler_icons/tabler_icons.dart';

/// BibliotecaScreen: colecciones descargadas + buscador + entrada a Tienda.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PremiumProvider premium;
  late BibliotecaRepository repo;

  /// Filas del catálogo, leídas LAZY por el MockClient en cada request.
  /// Se setean en el BODY del test antes del pump (el client se crea una
  /// sola vez en el setUp; un segundo SupabaseClient dejaría el timer de
  /// autoRefresh pendiente y el test fallaría al final).
  List<Map<String, dynamic>>? filasCatalogo;

  Map<String, dynamic> filaJugos({String? imagen}) => {
        'id': 'jugos',
        'nombre': 'Jugos naturales',
        'descripcion': 'Jugos de prueba',
        'icono': 'glass-full',
        'color': 'verde',
        'activa': true,
        'orden': 1,
        'version': 1,
        'imagen': imagen,
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
          return jsonResp(request, filasCatalogo ?? [filaJugos()], 200);
        }
        return http.Response('Not found: ${request.url.path}', 404,
            request: request);
      }),
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  }

  setUp(() async {
    filasCatalogo = null; // default: filaJugos() sin portada
    SharedPreferences.setMockInitialValues({});
    await UserService().clearAll();
    premium = PremiumProvider(payment: MockPaymentService());
    await premium.init();
    repo = BibliotecaRepository();
    repo.testClient = fakeClient();
  });

  tearDown(() {
    // dispose cancela el timer de autoRefresh del GoTrueClient; si un
    // test creó un client propio (filas custom) queda el ÚLTIMO.
    repo.testClient?.dispose();
    repo.testClient = null;
  });

  Future<void> pumpBiblioteca(WidgetTester tester) async {
    final biblioteca = BibliotecaProvider(premium: premium, repo: repo);
    await biblioteca.init();
    await tester.pumpWidget(
      ChangeNotifierProvider<PremiumProvider>.value(
        value: premium,
        child: ChangeNotifierProvider<BibliotecaProvider>.value(
          value: biblioteca,
          child: const MaterialApp(home: BibliotecaScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin descargadas: estado vacío + banner a la tienda, sin buscador',
      (tester) async {
    await pumpBiblioteca(tester);

    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Todavía no tenés colecciones.'), findsOneWidget);
    expect(find.text('Tienda de colecciones'), findsOneWidget);
    // Sin contenido no hay buscador (no hay nada que buscar).
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('con colección descargada: se lista y el buscador filtra recetas',
      (tester) async {
    await premium.purchasePack('jugos');
    await pumpBiblioteca(tester);

    // El buscador queda arriba de Mis colecciones.
    expect(find.text('Buscar en tus colecciones'), findsOneWidget);
    expect(find.text('Jugos naturales'), findsOneWidget);
    expect(find.text('1 recetas'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Buscador propio: sin matches → "Sin resultados".
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Sin resultados para "xyz".'), findsOneWidget);
    expect(find.text('Jugo verde matinal'), findsNothing);

    // Con match por keyword normalizada, aparece la receta.
    await tester.enterText(find.byType(TextField), 'jugo');
    await tester.pumpAndSettle();
    expect(find.text('Jugo verde matinal'), findsOneWidget);
    expect(find.text('Sin resultados'), findsNothing);
  });

  testWidgets(
      'con premium (sin pack): todas las colecciones listadas + buscador, '
      'sin estado vacío', (tester) async {
    await premium.purchaseLifetime();
    await pumpBiblioteca(tester);

    // Premium incluye TODO el catálogo: la biblioteca ya no está vacía.
    expect(find.text('Buscar en tus colecciones'), findsOneWidget);
    expect(find.text('Jugos naturales'), findsOneWidget);
    expect(find.text('Todavía no tenés colecciones.'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    // Banner de tienda: ya tiene todo lo disponible.
    expect(find.text('Ya tenés todo lo disponible.'), findsOneWidget);
  });

  testWidgets('colección con portada: la tarjeta renderiza la imagen',
      (tester) async {
    // flutter test empaqueta los assets del pubspec: la portada real
    // carga de verdad y reemplaza al ícono de la colección.
    filasCatalogo = [
      filaJugos(imagen: 'assets/images/recetas/portada_jugos.webp'),
    ];
    await premium.purchasePack('jugos');
    await pumpBiblioteca(tester);

    expect(find.text('Jugos naturales'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(TablerIcons.glass_full), findsNothing);
  });

  testWidgets('portada rota (asset inexistente): fallback al ícono sin romper',
      (tester) async {
    filasCatalogo = [
      filaJugos(imagen: 'assets/images/recetas/no_existe.webp'),
    ];
    await premium.purchasePack('jugos');
    await pumpBiblioteca(tester);

    expect(find.text('Jugos naturales'), findsOneWidget);
    // errorBuilder → ícono de la familia visual.
    expect(find.byIcon(TablerIcons.glass_full), findsOneWidget);
  });

  testWidgets('colección sin portada: ícono de la familia visual',
      (tester) async {
    await premium.purchasePack('jugos');
    await pumpBiblioteca(tester);

    expect(find.text('Jugos naturales'), findsOneWidget);
    expect(find.byIcon(TablerIcons.glass_full), findsOneWidget);
  });
}
