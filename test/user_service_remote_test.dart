import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remedios_naturales_app/data/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests del modo REMOTO de UserService (con sesión), simulando
/// PostgREST con MockClient. El modo anónimo ya está cubierto en
/// user_service_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserService service;

  /// Crea un cliente Supabase fake. `online=false` simula fallo de red.
  SupabaseClient fakeClient({
    bool online = true,
    List<http.Request>? requestsLog,
  }) {
    // PostgREST accede a response.request!.headers: hay que adjuntar el
    // request a cada respuesta, si no revienta con null check.
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

        final path = request.url.path;

        // ─── Perfiles ───
        if (path == '/rest/v1/perfiles') {
          if (request.method == 'PATCH') return jsonResp(request, null, 204);
          return jsonResp(request, [
            {
              'nombre': 'Juan Pérez',
              'fecha_registro': '2026-01-01T00:00:00.000Z',
            }
          ], 200);
        }

        // ─── Favoritos ───
        if (path == '/rest/v1/favoritos') {
          if (request.method == 'POST') return jsonResp(request, [], 201);
          if (request.method == 'DELETE') return jsonResp(request, null, 204);
          return jsonResp(request, [
            {'receta_id': 'digestivo_01'},
            {'receta_id': 'nervioso_01'},
          ], 200);
        }

        // ─── Historial ───
        if (path == '/rest/v1/historial') {
          if (request.method == 'POST') return jsonResp(request, [], 201);
          return jsonResp(request, [
            {'receta_id': 'respiratorio_01'},
          ], 200);
        }

        return http.Response('Not found: $path', 404, request: request);
      }),
      // Mismo motivo que en auth_service_test: sin asyncStorage en tests,
      // el flujo PKCE (default) lanzaría una assertion al consultar auth.
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = UserService();
    service.testClient = null;
    service.setSession(userId: null);
    await service.clearAll();
  });

  tearDown(() async {
    service.setSession(userId: null);
    service.testClient = null;
    await service.clearAll();
  });

  group('modo remoto', () {
    test('getCurrentProfile carga el perfil desde la nube', () async {
      service.testClient = fakeClient();
      service.setSession(userId: 'user-123', email: 'juan@email.com');

      final profile = await service.getCurrentProfile();

      expect(profile, isNotNull);
      expect(profile!.id, 'user-123');
      expect(profile.email, 'juan@email.com');
      expect(profile.nombre, 'Juan Pérez');
      expect(profile.favoritos, containsAll(['digestivo_01', 'nervioso_01']));
      expect(profile.historial, contains('respiratorio_01'));
    });

    test('getFavorites devuelve los favoritos de la nube', () async {
      service.testClient = fakeClient();
      service.setSession(userId: 'user-123', email: 'juan@email.com');

      final favoritos = await service.getFavorites();

      expect(favoritos, containsAll(['digestivo_01', 'nervioso_01']));
    });

    test('addFavorite hace upsert con onConflict para no duplicar',
        () async {
      final log = <http.Request>[];
      service.testClient = fakeClient(requestsLog: log);
      service.setSession(userId: 'user-123', email: 'juan@email.com');

      await service.addFavorite('digestivo_01');

      final upsert = log.firstWhere((r) => r.method == 'POST');
      expect(upsert.url.path, '/rest/v1/favoritos');
      expect(
        upsert.url.queryParameters['on_conflict'],
        'usuario_id,receta_id',
      );
      expect(upsert.headers['Prefer'], contains('ignore-duplicates'));
      final body = json.decode(upsert.body) as Map<String, dynamic>;
      expect(body['usuario_id'], 'user-123');
      expect(body['receta_id'], 'digestivo_01');
    });

    test('removeFavorite hace delete filtrado por usuario y receta',
        () async {
      final log = <http.Request>[];
      service.testClient = fakeClient(requestsLog: log);
      service.setSession(userId: 'user-123', email: 'juan@email.com');

      await service.removeFavorite('digestivo_01');

      final del = log.firstWhere((r) => r.method == 'DELETE');
      expect(del.url.path, '/rest/v1/favoritos');
      expect(del.url.queryParameters['usuario_id'], 'eq.user-123');
      expect(del.url.queryParameters['receta_id'], 'eq.digestivo_01');
    });

    test('getFavorites offline usa el cache local del último perfil',
        () async {
      // 1) Online: puebla el cache local con un perfil logueado
      service.testClient = fakeClient(online: true);
      service.setSession(userId: 'user-123', email: 'juan@email.com');
      await service.getCurrentProfile();

      // 2) Offline: getFavorites cae al cache
      service.testClient = fakeClient(online: false);
      final favoritos = await service.getFavorites();

      expect(favoritos, containsAll(['digestivo_01', 'nervioso_01']));
    });

    test('getCurrentProfile offline devuelve perfil del cache con email',
        () async {
      service.testClient = fakeClient(online: true);
      service.setSession(userId: 'user-123', email: 'juan@email.com');
      await service.getCurrentProfile();

      service.testClient = fakeClient(online: false);
      final profile = await service.getCurrentProfile();

      expect(profile, isNotNull);
      expect(profile!.id, 'user-123');
      expect(profile.email, 'juan@email.com');
      expect(profile.nombre, 'Juan Pérez');
    });
  });

  group('migrateLocalToCloud', () {
    test('sube los datos anónimos y limpia la key local', () async {
      SharedPreferences.setMockInitialValues({
        'user_profile': json.encode({
          'id': 'anonymous',
          'email': '',
          'nombre': 'Usuario',
          'fechaRegistro': '2026-01-01T00:00:00.000Z',
          'favoritos': ['digestivo_01', 'nervioso_01'],
          'historial': ['digestivo_01'],
        }),
      });

      final log = <http.Request>[];
      service.testClient = fakeClient(requestsLog: log);
      service.setSession(userId: 'user-123', email: 'juan@email.com');

      await service.migrateLocalToCloud();

      // Upsert de favoritos con 2 items
      final favPost = log.firstWhere(
        (r) => r.method == 'POST' && r.url.path == '/rest/v1/favoritos',
      );
      final favBody = json.decode(favPost.body) as List;
      expect(favBody.length, 2);

      // Upsert de historial con 1 item
      final histPost = log.firstWhere(
        (r) => r.method == 'POST' && r.url.path == '/rest/v1/historial',
      );
      final histBody = json.decode(histPost.body) as List;
      expect(histBody.length, 1);
      expect((histBody[0] as Map)['receta_id'], 'digestivo_01');

      // La key anónima se limpia
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_profile'), isNull);
    });

    test('sin datos anónimos no hace requests', () async {
      final log = <http.Request>[];
      service.testClient = fakeClient(requestsLog: log);
      service.setSession(userId: 'user-123', email: 'juan@email.com');

      await service.migrateLocalToCloud();

      expect(log, isEmpty);
    });
  });
}
