import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';
import 'package:remedios_naturales_app/features/biblioteca/data/biblioteca_repository.dart';
import 'package:remedios_naturales_app/features/biblioteca/presentation/tienda_screen.dart';
import 'package:remedios_naturales_app/presentation/providers/biblioteca_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// TiendaScreen: catálogo con precios + compra de colecciones.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PremiumProvider premium;
  late BibliotecaProvider biblioteca;
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
    biblioteca = BibliotecaProvider(premium: premium, repo: repo);
    await biblioteca.init();
  });

  tearDown(() {
    repo.testClient = null;
  });

  Future<void> pumpTienda(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<BibliotecaProvider>.value(
        value: biblioteca,
        child: MaterialApp(home: const TiendaScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra catálogo con precio de la tienda', (tester) async {
    await pumpTienda(tester);

    expect(find.text('Jugos naturales'), findsOneWidget);
    expect(find.text('1 recetas'), findsOneWidget);
    expect(find.text('USD 1.99'), findsOneWidget);
    expect(find.text('Comprar · USD 1.99'), findsOneWidget);
    expect(find.text('Descargada'), findsNothing);
  });

  testWidgets('comprar: adquiere la colección y muestra Descargada',
      (tester) async {
    await pumpTienda(tester);

    await tester.tap(find.text('Comprar · USD 1.99'));
    await tester.pumpAndSettle();

    expect(premium.packs, contains('yuyo_pack_jugos'));
    expect(find.text('Descargada'), findsOneWidget);
    expect(find.text('Comprar · USD 1.99'), findsNothing);
    // Snackbar de confirmación
    expect(
      find.text('Jugos naturales descargada en tu biblioteca'),
      findsOneWidget,
    );
  });

  testWidgets('colección ya comprada: estado Descargada sin botón de compra',
      (tester) async {
    await premium.purchasePack('jugos');
    await pumpTienda(tester);

    expect(find.text('Descargada'), findsOneWidget);
    expect(find.text('Comprar · USD 1.99'), findsNothing);
  });

  testWidgets('premium: colección como Incluida en Premium', (tester) async {
    await premium.purchasePremium();
    await pumpTienda(tester);

    expect(find.text('Incluida en Premium'), findsOneWidget);
    expect(find.text('Comprar · USD 1.99'), findsNothing);
  });
}
