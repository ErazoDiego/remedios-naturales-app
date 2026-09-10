import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';
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
    // UserService es SINGLETON: su cache en memoria (_currentProfile)
    // sobrevive a setMockInitialValues y contamina tests posteriores
    // (packs comprados en un test aparecen en el siguiente). setSession
    // sin argumentos invalida el cache (mecanismo oficial).
    UserService().setSession();
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

      expect(biblioteca.catalogo, hasLength(3));
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

  group('colecciones gratis (flag + reclamar)', () {
    test('colección GRATIS accesible sin premium ni pack, sin reclamar no '
        'aparece en descargadas', () async {
      await biblioteca.init();

      expect(biblioteca.puedeAcceder('kefir'), isTrue);
      expect(biblioteca.esGratisReclamada('kefir'), isFalse);
      expect(biblioteca.coleccionesDescargadas, isNot(contains('kefir')));
      // La de pago sin pack sigue bloqueada.
      expect(biblioteca.puedeAcceder('jugos'), isFalse);
    });

    test('reclamarGratis: la marca como descargada (mismo estado que compra)',
        () async {
      await biblioteca.init();
      await biblioteca.reclamarGratis('kefir');

      expect(biblioteca.esGratisReclamada('kefir'), isTrue);
      expect(biblioteca.coleccionesDescargadas, contains('kefir'));
      // No agregó ningún pack (no hay compra).
      expect(premium.packs, isNot(contains('yuyo_pack_kefir')));
    });

    test('la colección gratis NO consulta precio (no hay producto IAP)',
        () async {
      await biblioteca.init();

      expect(biblioteca.precio('kefir'), isNull);
      // Las de pago sí tienen precio del fetch.
      expect(biblioteca.precio('jugos'), 'USD 1.99');
    });

    test('persistencia: reclamos guardados en cache local sobreviven',
        () async {
      SharedPreferences.setMockInitialValues({
        'biblioteca_gratis_reclamadas': json.encode(['kefir']),
      });
      biblioteca = BibliotecaProvider(
        premium: premium,
        repo: BibliotecaRepository(),
      );
      repo.testClient = fakeClient();

      await biblioteca.init();

      expect(biblioteca.esGratisReclamada('kefir'), isTrue);
      expect(biblioteca.coleccionesDescargadas, contains('kefir'));
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

  group('tiendaVisible (la tienda solo muestra lo no adquirido)', () {
    test('sin premium ni packs: muestra todo el catálogo', () async {
      await biblioteca.init();

      expect(
        biblioteca.tiendaVisible.map((c) => c.id).toList(),
        ['jugos', 'sin_tacc', 'kefir'],
      );
    });

    test('con pack comprado: esa colección desaparece de la tienda',
        () async {
      await biblioteca.init();
      await biblioteca.comprar('jugos');

      expect(
        biblioteca.tiendaVisible.map((c) => c.id).toList(),
        ['sin_tacc', 'kefir'],
      );
    });

    test('gratis sin reclamar se muestra; reclamada desaparece', () async {
      await biblioteca.init();

      // Gratis sin reclamar: visible (para que el usuario la marque).
      expect(biblioteca.tiendaVisible.map((c) => c.id), contains('kefir'));

      await biblioteca.reclamarGratis('kefir');

      expect(biblioteca.tiendaVisible.map((c) => c.id), isNot(contains('kefir')));
    });

    test('con premium la tienda queda vacía (todo incluido)', () async {
      await premium.purchaseLifetime();
      await biblioteca.init();

      expect(biblioteca.esPremium, isTrue);
      expect(biblioteca.tiendaVisible, isEmpty);
    });
  });
}
