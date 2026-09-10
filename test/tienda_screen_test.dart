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

/// TiendaScreen: solo muestra colecciones NO adquiridas.
///
/// La tienda deja de listar lo que ya se posee (pack comprado, gratis
/// reclamada o cubierto por Premium) y, cuando no queda nada nuevo,
/// muestra un estado vacío con el motivo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PremiumProvider premium;
  late BibliotecaRepository repo;

  Map<String, dynamic> fila(String id, String nombre,
          {bool gratis = false}) =>
      {
        'id': id,
        'nombre': nombre,
        'descripcion': 'Descripción de $nombre',
        'icono': 'glass-full',
        'color': 'verde',
        'activa': true,
        'orden': 1,
        'version': 1,
        'gratis': gratis,
        'recetas': [
          {
            'id': '${id}_01',
            'nombre': 'Receta 1 de $nombre',
            'descripcion': 'desc',
            'idealPara': ['X'],
            'tipo': 'interno',
            'tipoPreparacion': 'bebida',
            'precaucion': 'cuidado',
            'ingredientes': ['a'],
            'preparacion': ['b'],
            'dosis': '1 vaso',
            'almacenamiento': 'frasco',
            'keywords': ['${id}_kw'],
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
          return jsonResp(request, [
            fila('jugos', 'Jugos naturales'),
            fila('sin_tacc', 'Sin TACC'),
            fila('kefir', 'Recetas con kéfir', gratis: true),
          ], 200);
        }
        return http.Response('Not found: ${request.url.path}', 404,
            request: request);
      }),
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // UserService es SINGLETON: su cache en memoria sobrevive a
    // setMockInitialValues y contamina tests posteriores; setSession sin
    // argumentos invalida el cache (mecanismo oficial).
    UserService().setSession();
    premium = PremiumProvider(payment: MockPaymentService());
    await premium.init();
    repo = BibliotecaRepository();
    repo.testClient = fakeClient();
  });

  tearDown(() {
    repo.testClient = null;
  });

  Future<void> pumpTienda(
    WidgetTester tester, {
    required BibliotecaProvider biblioteca,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<PremiumProvider>.value(
        value: premium,
        child: ChangeNotifierProvider<BibliotecaProvider>.value(
          value: biblioteca,
          child: const MaterialApp(home: TiendaScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin adquiridas: la tienda lista todo el catálogo',
      (tester) async {
    final biblioteca = BibliotecaProvider(premium: premium, repo: repo);
    await biblioteca.init();
    await pumpTienda(tester, biblioteca: biblioteca);

    expect(find.text('Tienda'), findsOneWidget);
    expect(find.text('Jugos naturales'), findsOneWidget);
    expect(find.text('Sin TACC'), findsOneWidget);
    expect(find.text('Recetas con kéfir'), findsOneWidget);
    // Los que no compró todavía: siguen comprables.
    expect(find.text('Comprar · USD 1.99'), findsNWidgets(2));
    // La gratis sin reclamar se ofrece.
    expect(find.text('Recetas gratis'), findsOneWidget);
  });

  testWidgets('con pack comprado: esa colección desaparece de la tienda',
      (tester) async {
    final biblioteca = BibliotecaProvider(premium: premium, repo: repo);
    await biblioteca.init();
    await biblioteca.comprar('jugos');

    await pumpTienda(tester, biblioteca: biblioteca);

    expect(find.text('Jugos naturales'), findsNothing);
    expect(find.text('Sin TACC'), findsOneWidget);
    expect(find.text('Recetas con kéfir'), findsOneWidget);
  });

  testWidgets('gratis reclamada: ya no se ofrece en la tienda', (tester) async {
    final biblioteca = BibliotecaProvider(premium: premium, repo: repo);
    await biblioteca.init();
    await biblioteca.reclamarGratis('kefir');

    await pumpTienda(tester, biblioteca: biblioteca);

    expect(find.text('Recetas con kéfir'), findsNothing);
    expect(find.text('Recetas gratis'), findsNothing);
    // Las de pago siguen comprables.
    expect(find.text('Comprar · USD 1.99'), findsNWidgets(2));
  });

  testWidgets('con premium: tienda vacía con mensaje de todo incluido',
      (tester) async {
    await premium.purchaseLifetime();
    final biblioteca = BibliotecaProvider(premium: premium, repo: repo);
    await biblioteca.init();

    await pumpTienda(tester, biblioteca: biblioteca);

    expect(find.text('Jugos naturales'), findsNothing);
    expect(find.text('Sin TACC'), findsNothing);
    expect(find.text('Recetas con kéfir'), findsNothing);
    expect(
      find.text('Ya tenés todas las colecciones con Premium.'),
      findsOneWidget,
    );
  });

  testWidgets('sin premium y todo adquirido: mensaje de compra completa',
      (tester) async {
    final biblioteca = BibliotecaProvider(premium: premium, repo: repo);
    await biblioteca.init();
    await biblioteca.comprar('jugos');
    await biblioteca.comprar('sin_tacc');
    await biblioteca.reclamarGratis('kefir');

    await pumpTienda(tester, biblioteca: biblioteca);

    expect(find.text('Jugos naturales'), findsNothing);
    expect(
      find.text('Compraste todas las colecciones disponibles.'),
      findsOneWidget,
    );
  });
}