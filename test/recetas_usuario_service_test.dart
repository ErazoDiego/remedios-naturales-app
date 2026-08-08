import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remedios_naturales_app/data/models/receta_usuario.dart';
import 'package:remedios_naturales_app/data/services/recetas_usuario_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Draft (receta sin id) para pruebas de crear/actualizar.
RecetaUsuario draft() {
  return RecetaUsuario(
    nombre: 'Jarabe de jengibre',
    descripcion: 'Para la garganta',
    idealPara: ['tos'],
    tipo: 'remedio casero',
    tipoPreparacion: 'jarabe',
    cuandoUsar: 'Ante los primeros síntomas',
    precaucion: 'No en embarazadas',
    ingredientes: ['jengibre', 'miel'],
    preparacion: ['Rallar', 'Mezclar'],
    dosis: '1 cucharada',
    almacenamiento: 'Frasco cerrado',
  );
}

/// Tests del servicio CRUD de recetas propias contra PostgREST simulado
/// con MockClient (mismo patrón que user_service_remote_test.dart).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecetasUsuarioService service;

  Map<String, dynamic> recetaRow({
    String id = 'a1',
    String nombre = 'Jarabe de jengibre',
    String actualizadoAt = '2026-08-07T13:30:00.000Z',
  }) {
    return {
      'id': id,
      'usuario_id': 'user-123',
      'nombre': nombre,
      'descripcion': 'Para la garganta',
      'ideal_para': ['tos'],
      'tipo': 'remedio casero',
      'tipo_preparacion': 'jarabe',
      'cuando_usar': 'Ante los primeros síntomas',
      'precaucion': 'No en embarazadas',
      'ingredientes': ['jengibre', 'miel'],
      'preparacion': ['Rallar', 'Mezclar'],
      'dosis': '1 cucharada',
      'almacenamiento': 'Frasco cerrado',
      'imagen': null,
      'imagen_placeholder': null,
      'creado_at': '2026-08-07T12:00:00.000Z',
      'actualizado_at': actualizadoAt,
    };
  }

  /// Cliente Supabase fake con el CRUD de recetas_usuario.
  SupabaseClient fakeClient({List<http.Request>? requestsLog}) {
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
        final path = request.url.path;
        final acceptObject = (request.headers['accept'] ?? '')
            .contains('pgrst.object');

        if (path == '/rest/v1/recetas_usuario') {
          // ─── INSERT (crear) ───
          if (request.method == 'POST') {
            final body = jsonResp(
              request,
              acceptObject ? recetaRow() : [recetaRow()],
              201,
            );
            return body;
          }

          // ─── UPDATE (actualizar) ───
          if (request.method == 'PATCH') {
            return jsonResp(request, null, 204);
          }

          // ─── DELETE (eliminar) ───
          if (request.method == 'DELETE') {
            return jsonResp(request, null, 204);
          }

          // ─── SELECT lista ───
          return jsonResp(request, [recetaRow(), recetaRow(id: 'b2')], 200);
        }

        return http.Response('Not found: $path', 404, request: request);
      }),
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  }

  setUp(() {
    service = RecetasUsuarioService();
    service.testClient = null;
    service.testUserId = null;
    service.invalidateCache();
  });

  tearDown(() {
    service.testClient = null;
    service.testUserId = null;
    service.invalidateCache();
  });

  group('getMisRecetas', () {
    test('trae las recetas ordenadas por actualizado_at desc', () async {
      final log = <http.Request>[];
      service.testClient = fakeClient(requestsLog: log);
      service.testUserId = 'user-123';

      final recetas = await service.getMisRecetas();

      expect(recetas, hasLength(2));
      expect(recetas.first.nombre, 'Jarabe de jengibre');
      expect(recetas.first.usuarioId, 'user-123');
      expect(recetas.first.ingredientes, ['jengibre', 'miel']);
      expect(recetas.first.tipoPreparacion, 'jarabe');

      final get = log.singleWhere((r) => r.method == 'GET');
      expect(get.url.path, '/rest/v1/recetas_usuario');
      // supabase-dart agrega .nullslast al order
      expect(get.url.queryParameters['order'], startsWith('actualizado_at.desc'));
    });

    test('usa el cache en memoria: no repite requests', () async {
      final log = <http.Request>[];
      service.testClient = fakeClient(requestsLog: log);
      service.testUserId = 'user-123';

      await service.getMisRecetas();
      await service.getMisRecetas();

      final gets = log.where((r) => r.method == 'GET').length;
      expect(gets, 1);
    });

    test('sin sesión lanza error claro', () async {
      service.testClient = fakeClient();
      service.testUserId = '';

      expect(
        () => service.getMisRecetas(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('iniciar sesión'),
        )),
      );
    });
  });

  group('crear', () {
    test('hace POST con usuario_id y body snake_case, devuelve la creada',
        () async {
      final log = <http.Request>[];
      service.testClient = fakeClient(requestsLog: log);
      service.testUserId = 'user-123';

      final creada = await service.crear(draft());

      expect(creada.id, isNotEmpty);
      expect(creada.usuarioId, 'user-123');
      expect(creada.creadoAt, isNotNull);

      final post = log.singleWhere((r) => r.method == 'POST');
      expect(post.url.path, '/rest/v1/recetas_usuario');
      final body = json.decode(post.body) as Map<String, dynamic>;
      expect(body['usuario_id'], 'user-123');
      expect(body['nombre'], 'Jarabe de jengibre');
      expect(body['ideal_para'], ['tos']);
      expect(body.containsKey('id'), isFalse);
      expect(body.containsKey('creado_at'), isFalse);
    });

    test('la receta creada queda primera en el cache', () async {
      final log = <http.Request>[];
      service.testClient = fakeClient(requestsLog: log);
      service.testUserId = 'user-123';

      await service.getMisRecetas(); // puebla cache con 2 items
      final creada = await service.crear(draft());

      // getMisRecetas devuelve el cache: la nueva debe estar al frente
      final recetas = await service.getMisRecetas();
      expect(recetas.first.id, creada.id);
    });

    test('sin sesión lanza error claro', () async {
      service.testClient = fakeClient();
      service.testUserId = '';

      expect(
        () => service.crear(draft()),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('actualizar', () {
    test('hace PATCH por id, sin incluir id/usuario_id en el body', () async {
      final log = <http.Request>[];
      service.testClient = fakeClient(requestsLog: log);
      service.testUserId = 'user-123';

      final receta = (await service.getMisRecetas()).first;
      final editada = receta.copyWith(nombre: 'Nombre editado');

      await service.actualizar(editada);

      final patch = log.singleWhere((r) => r.method == 'PATCH');
      expect(patch.url.path, '/rest/v1/recetas_usuario');
      expect(patch.url.queryParameters['id'], 'eq.a1');
      final body = json.decode(patch.body) as Map<String, dynamic>;
      expect(body['nombre'], 'Nombre editado');
      expect(body['actualizado_at'], isNotNull);
      expect(body.containsKey('id'), isFalse);
      expect(body.containsKey('usuario_id'), isFalse);
    });

    test('actualiza la copia en el cache', () async {
      service.testClient = fakeClient();
      service.testUserId = 'user-123';

      final receta = (await service.getMisRecetas()).first;
      await service.actualizar(receta.copyWith(nombre: 'Editada'));

      final recetas = await service.getMisRecetas();
      expect(recetas.first.nombre, 'Editada');
    });

    test('sin id lanza error', () async {
      service.testClient = fakeClient();
      service.testUserId = 'user-123';

      expect(
        () => service.actualizar(draft()),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('eliminar', () {    test('hace DELETE por id y lo quita del cache', () async {
      final log = <http.Request>[];
      service.testClient = fakeClient(requestsLog: log);
      service.testUserId = 'user-123';

      await service.getMisRecetas();
      await service.eliminar('a1');

      final del = log.singleWhere((r) => r.method == 'DELETE');
      expect(del.url.path, '/rest/v1/recetas_usuario');
      expect(del.url.queryParameters['id'], 'eq.a1');

      final recetas = await service.getMisRecetas();
      expect(recetas.any((r) => r.id == 'a1'), isFalse);
    });

    test('sin sesión lanza error claro', () async {
      service.testClient = fakeClient();
      service.testUserId = '';

      expect(
        () => service.eliminar('a1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('isRecetaPropiaId', () {
    test('reconoce UUID v4 como receta propia', () {
      expect(
        RecetasUsuarioService.isRecetaPropiaId(
          '3f2a9d51-7c4e-4b8a-9f1e-2d6b5c8a0f77',
        ),
        isTrue,
      );
      expect(
        RecetasUsuarioService.isRecetaPropiaId(
          'F3F2A9D5-7C4E-4B8A-9F1E-2D6B5C8A0F77',
        ),
        isTrue,
        reason: 'UUID con mayúsculas también es válido',
      );
    });

    test('NO reconoce IDs del catálogo como propios', () {
      expect(RecetasUsuarioService.isRecetaPropiaId('digestivo_remedio_01'),
          isFalse);
      expect(RecetasUsuarioService.isRecetaPropiaId('respiratorio_jarabe_2'),
          isFalse);
    });

    test('no confunde strings similares con UUID', () {
      expect(RecetasUsuarioService.isRecetaPropiaId(''), isFalse);
      expect(
        RecetasUsuarioService.isRecetaPropiaId(
          '3f2a9d51-7c4e-4b8a-9f1e-2d6b5c8a0f7', // 35 chars, falta un char
        ),
        isFalse,
      );
    });
  });
}

