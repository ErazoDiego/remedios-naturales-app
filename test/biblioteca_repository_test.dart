import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remedios_naturales_app/features/biblioteca/data/biblioteca_repository.dart';
import 'package:remedios_naturales_app/features/biblioteca/domain/coleccion.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests de BibliotecaRepository simulando PostgREST con MockClient
/// (mismo patrón que user_service_remote_test.dart).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibliotecaRepository repo;

  Map<String, dynamic> recetaMap(String id, List<String> keywords) => {
        'id': id,
        'nombre': 'Jugo de $id',
        'descripcion': 'Descripción $id',
        'idealPara': ['Energía'],
        'tipo': 'interno',
        'tipoPreparacion': 'bebida',
        'cuandoUsar': 'En ayunas',
        'precaucion': 'Cuidado',
        'ingredientes': ['Apio'],
        'preparacion': ['Licuar'],
        'dosis': '1 vaso',
        'almacenamiento': 'Frasco',
        'imagen': null,
        'keywords': keywords,
      };

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
          recetaMap('jugos_01', ['jugo', 'verde']),
          recetaMap('jugos_02', ['naranja', 'defensas']),
        ],
      };

  /// Cliente Supabase fake. `online=false` simula fallo de red.
  SupabaseClient fakeClient({
    bool online = true,
    List<Map<String, dynamic>>? filas,
    List<http.Request>? requestsLog,
  }) {
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
        requestsLog?.add(request);
        if (!online) {
          throw http.ClientException('Sin conexión');
        }
        if (request.url.path == '/rest/v1/colecciones') {
          return jsonResp(request, filas ?? [filaJugos()], 200);
        }
        return http.Response('Not found: ${request.url.path}', 404,
            request: request);
      }),
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = BibliotecaRepository();
  });

  tearDown(() {
    repo.testClient = null;
  });

  group('getCatalogo (online)', () {
    test('parsea metadata, recetas y keywords del JSONB', () async {
      repo.testClient = fakeClient();

      final catalogo = await repo.getCatalogo();

      expect(catalogo, hasLength(1));
      final jugos = catalogo.first;
      expect(jugos.id, 'jugos');
      expect(jugos.nombre, 'Jugos naturales');
      expect(jugos.icono, 'glass-full');
      expect(jugos.activa, isTrue);
      expect(jugos.version, 1);
      expect(jugos.recetas, hasLength(2));
      expect(jugos.recetas[0].receta.id, 'jugos_01');
      expect(jugos.recetas[0].receta.tipoPreparacion, 'bebida');
      expect(jugos.recetas[0].keywords, containsAll(['jugo', 'verde']));
      expect(jugos.recetaPorId('jugos_02')?.receta.nombre,
          'Jugo de jugos_02');
      expect(jugos.recetaPorId('no_existe'), isNull);
    });

    test('solo colecciones activas (filtro en la query)', () async {
      final requests = <http.Request>[];
      repo.testClient = fakeClient(filas: [], requestsLog: requests);

      await repo.getCatalogo();

      // La query debe filtrar activas y ordenar por orden.
      final query = requests.isEmpty ? '' : requests.first.url.query;
      expect(query, contains('activa'));
      expect(query, contains('order'));
    });

    test('tras un fetch exitoso actualiza el cache local', () async {
      repo.testClient = fakeClient();

      final catalogo = await repo.getCatalogo();
      expect(catalogo, hasLength(1));

      // "Apaga" la red: el cache devuelve el catálogo igual.
      repo.testClient = fakeClient(online: false);
      final offline = await repo.getCatalogo();

      expect(offline, hasLength(1));
      expect(offline.first.id, 'jugos');
      expect(offline.first.recetas, hasLength(2));
    });
  });

  group('getCatalogo (offline)', () {
    test('sin cache devuelve lista vacía', () async {
      repo.testClient = fakeClient(online: false);

      final catalogo = await repo.getCatalogo();

      expect(catalogo, isEmpty);
    });

    test('con cache devuelve el último catálogo', () async {
      // Cache previo (como si un fetch exitoso hubiera corrido antes).
      SharedPreferences.setMockInitialValues({
        'biblioteca_cache': json.encode([filaJugos()]),
      });
      repo.testClient = fakeClient(online: false);

      final catalogo = await repo.getCatalogo();

      expect(catalogo, hasLength(1));
      expect(catalogo.first.nombre, 'Jugos naturales');
    });

    test('cache corrupto devuelve lista vacía', () async {
      SharedPreferences.setMockInitialValues({
        'biblioteca_cache': 'no es json',
      });
      repo.testClient = fakeClient(online: false);

      expect(await repo.getCatalogo(), isEmpty);
    });
  });

  group('modelo Coleccion', () {
    test('fromJson con recetas vacías', () {
      final coleccion = Coleccion.fromJson({
        ...filaJugos(),
        'recetas': [],
      });

      expect(coleccion.recetas, isEmpty);
      expect(coleccion.recetaPorId('jugos_01'), isNull);
    });

    test('round-trip toJson → fromJson (formato cache)', () {
      final original = Coleccion.fromJson(filaJugos());

      final clon = Coleccion.fromJson(original.toJson());

      expect(clon.id, original.id);
      expect(clon.nombre, original.nombre);
      expect(clon.version, original.version);
      expect(clon.recetas, hasLength(2));
      expect(clon.recetas[1].keywords, containsAll(['naranja', 'defensas']));
    });

    test('round-trip con imagen de portada', () {
      final original = Coleccion.fromJson({
        ...filaJugos(),
        'imagen': 'assets/images/recetas/portada_jugos.webp',
      });

      expect(original.imagen, 'assets/images/recetas/portada_jugos.webp');
      final clon = Coleccion.fromJson(original.toJson());
      expect(clon.imagen, original.imagen);
    });

    test('campos faltantes tienen defaults', () {
      final coleccion = Coleccion.fromJson({'id': 'minima'});

      expect(coleccion.nombre, '');
      expect(coleccion.icono, 'leaf');
      expect(coleccion.color, 'verde');
      expect(coleccion.activa, isTrue);
      expect(coleccion.imagen, isNull);
      expect(coleccion.recetas, isEmpty);
    });
  });
}
