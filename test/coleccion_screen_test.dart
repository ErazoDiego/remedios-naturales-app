import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// ColeccionScreen: muro de bloqueo vs lista de recetas según el acceso.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PremiumProvider premium;
  late BibliotecaRepository repo;

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

  testWidgets('sin acceso: muro con Desbloquear + precio', (tester) async {
    await pumpColeccion(tester);

    expect(find.text('Jugos naturales'), findsWidgets);
    expect(find.text('Esta colección no está desbloqueada. Comprá el pack '
        'para descargarla, o con Premium ya la tenés.'), findsOneWidget);
    expect(find.text('Desbloquear · USD 1.99'), findsOneWidget);
    expect(find.text('Jugo verde matinal'), findsNothing);
  });

  testWidgets('sin acceso: Desbloquear abre el diálogo premium',
      (tester) async {
    await pumpColeccion(tester);

    await tester.tap(find.text('Desbloquear · USD 1.99'));
    await tester.pumpAndSettle();

    expect(find.text('Desbloquear sistema · USD 1.99'), findsOneWidget);
    expect(find.text('Ver Premium'), findsOneWidget);
  });

  testWidgets('con pack de la colección: lista las recetas', (tester) async {
    await premium.purchasePack('jugos');
    await pumpColeccion(tester);

    expect(find.text('Jugo verde matinal'), findsOneWidget);
    expect(find.text('Desbloquear'), findsNothing);
  });

  testWidgets('con premium: lista las recetas', (tester) async {
    await premium.purchasePremium();
    await pumpColeccion(tester);

    expect(find.text('Jugo verde matinal'), findsOneWidget);
    expect(find.text('Desbloquear'), findsNothing);
  });
}
