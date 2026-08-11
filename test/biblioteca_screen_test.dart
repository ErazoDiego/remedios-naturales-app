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

/// BibliotecaScreen: colecciones descargadas + buscador + entrada a Tienda.
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
}
