import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/features/biblioteca/data/biblioteca_repository.dart';
import 'package:remedios_naturales_app/presentation/providers/biblioteca_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests de BibliotecaProvider: catálogo + gating + precios de tienda.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PremiumProvider premium;
  late BibliotecaProvider biblioteca;
  late BibliotecaRepository repo;

  Map<String, dynamic> fila(String id, String nombre) => {
        'id': id,
        'nombre': nombre,
        'descripcion': 'Descripción de $nombre',
        'icono': 'glass-full',
        'color': 'verde',
        'activa': true,
        'orden': 1,
        'version': 1,
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

  SupabaseClient fakeClient({bool online = true}) {
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
        if (!online) {
          throw http.ClientException('Sin conexión');
        }
        if (request.url.path == '/rest/v1/colecciones') {
          return jsonResp(request, [
            fila('jugos', 'Jugos naturales'),
            fila('sin_tacc', 'Sin TACC'),
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
    premium = PremiumProvider(payment: MockPaymentService());
    await premium.init();
    repo = BibliotecaRepository();
    repo.testClient = fakeClient();
    biblioteca = BibliotecaProvider(premium: premium, repo: repo);
  });

  tearDown(() {
    repo.testClient = null;
  });

  group('init (catálogo + precios)', () {
    test('carga el catálogo con sus recetas', () async {
      await biblioteca.init();

      expect(biblioteca.catalogo, hasLength(2));
      expect(biblioteca.catalogo.first.nombre, 'Jugos naturales');
      expect(biblioteca.catalogo.first.recetas, hasLength(1));
      expect(biblioteca.isLoading, isFalse);
    });

    test('consulta precios de los packs de colecciones (mapa global)',
        () async {
      await biblioteca.init();

      expect(premium.priceFor('yuyo_pack_jugos'), 'USD 1.99');
      expect(premium.priceFor('yuyo_pack_sin_tacc'), 'USD 1.99');
      expect(biblioteca.precio('jugos'), 'USD 1.99');
    });

    test('sin catálogo no consulta precios', () async {
      repo.testClient = fakeClient(online: false); // sin cache tampoco
      await biblioteca.init();

      expect(biblioteca.catalogo, isEmpty);
      expect(biblioteca.precio('jugos'), isNull);
    });

    test('con fallo de red y cache previo devuelve el cache', () async {
      // Cache previo (como si un fetch exitoso hubiera corrido antes).
      SharedPreferences.setMockInitialValues({
        'biblioteca_cache': json.encode([fila('jugos', 'Jugos naturales')]),
      });
      premium = PremiumProvider(payment: MockPaymentService());
      await premium.init();
      biblioteca = BibliotecaProvider(
        premium: premium,
        repo: BibliotecaRepository(),
      );
      repo.testClient = fakeClient(online: false);

      await biblioteca.init();

      expect(biblioteca.catalogo, hasLength(1));
      expect(biblioteca.catalogo.first.id, 'jugos');
    });
  });

  group('gating (puedeAcceder / coleccionesDescargadas)', () {
    test('sin premium ni packs: bloqueado y nada descargado', () async {
      await biblioteca.init();

      expect(biblioteca.puedeAcceder('jugos'), isFalse);
      expect(biblioteca.coleccionesDescargadas, isEmpty);
    });

    test('comprar: compra el pack y la colección queda accesible', () async {
      await biblioteca.init();

      final ok = await biblioteca.comprar('jugos');

      expect(ok, isTrue);
      expect(premium.packs, contains('yuyo_pack_jugos'));
      expect(biblioteca.puedeAcceder('jugos'), isTrue);
      expect(biblioteca.coleccionesDescargadas, contains('jugos'));
      // La otra colección sigue bloqueada.
      expect(biblioteca.puedeAcceder('sin_tacc'), isFalse);
    });

    test('con premium todo accesible aunque no haya packs', () async {
      await premium.purchaseLifetime();
      await biblioteca.init();

      expect(biblioteca.puedeAcceder('jugos'), isTrue);
      expect(biblioteca.puedeAcceder('sin_tacc'), isTrue);
      expect(biblioteca.puedeAcceder('coleccion_futura'), isTrue);
    });

    test('coleccionesDescargadas solo refleja colecciones del catálogo',
        () async {
      await biblioteca.init();
      await biblioteca.comprar('jugos');

      // El pack del sistema digestivo NO es una colección descargada.
      await premium.purchasePack('digestivo');
      expect(biblioteca.coleccionesDescargadas, contains('jugos'));
      expect(biblioteca.coleccionesDescargadas, isNot(contains('digestivo')));
    });
  });

  group('recetas', () {
    test('recetaDe encuentra por colección e id', () async {
      await biblioteca.init();

      final receta = biblioteca.recetaDe('jugos', 'jugos_01');
      expect(receta, isNotNull);
      expect(receta!.receta.nombre, 'Receta 1 de Jugos naturales');
      expect(receta.keywords, contains('jugos_kw'));

      expect(biblioteca.recetaDe('jugos', 'no_existe'), isNull);
      expect(biblioteca.recetaDe('no_existe', 'jugos_01'), isNull);
    });
  });
}
