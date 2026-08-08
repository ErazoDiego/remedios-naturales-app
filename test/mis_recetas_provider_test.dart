import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remedios_naturales_app/data/models/receta_usuario.dart';
import 'package:remedios_naturales_app/data/services/recetas_usuario_service.dart';
import 'package:remedios_naturales_app/presentation/providers/mis_recetas_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests del MisRecetasProvider: la lista de la UI debe reaccionar a
/// cada mutación (crear/actualizar/eliminar) notificando a los listeners
/// DESPUÉS del cambio — el bug de "eliminar no refrescaba la lista" se
/// detectó en la validación en dispositivo y quedó cubierto acá.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecetasUsuarioService service;
  late MisRecetasProvider provider;

  Map<String, dynamic> recetaRow({
    String id = 'a1',
    String nombre = 'Jarabe de jengibre',
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
      'actualizado_at': '2026-08-07T13:30:00.000Z',
    };
  }

  /// Cliente Supabase fake con el CRUD de recetas_usuario.
  /// `failDelete: true` simula error de red en DELETE.
  SupabaseClient fakeClient({bool failDelete = false}) {
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
        final path = request.url.path;
        final acceptObject = (request.headers['accept'] ?? '')
            .contains('pgrst.object');

        if (path == '/rest/v1/recetas_usuario') {
          if (request.method == 'POST') {
            return jsonResp(
              request,
              acceptObject ? recetaRow() : [recetaRow()],
              201,
            );
          }
          if (request.method == 'PATCH') {
            return jsonResp(request, null, 204);
          }
          if (request.method == 'DELETE') {
            if (failDelete) {
              return jsonResp(request, {'message': 'network error'}, 500);
            }
            return jsonResp(request, null, 204);
          }
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
    provider = MisRecetasProvider(service: service);
  });

  tearDown(() {
    service.testClient = null;
    service.testUserId = null;
    service.invalidateCache();
  });

  group('eliminar', () {
    test('quita la receta de la lista y notifica DESPUÉS del cambio', () async {
      service.testClient = fakeClient();
      service.testUserId = 'user-123';
      await provider.load();
      expect(provider.recetas, hasLength(2));

      var seenAfterChange = false;
      provider.addListener(() {
        if (provider.recetas.length == 1) seenAfterChange = true;
      });

      final ok = await provider.eliminar('a1');

      expect(ok, isTrue);
      expect(provider.recetas, hasLength(1));
      expect(provider.recetas.first.id, 'b2');
      // CLAVE del fix: el listener debe ver la lista YA sin la receta.
      // Antes, el notifyListeners() ocurría al inicio (lista vieja) y la
      // card quedaba visible hasta recargar la pantalla.
      expect(seenAfterChange, isTrue);
    });

    test('si DELETE falla, la lista queda intacta y setea error', () async {
      service.testClient = fakeClient(failDelete: true);
      service.testUserId = 'user-123';
      await provider.load();
      expect(provider.recetas, hasLength(2));

      final ok = await provider.eliminar('a1');

      expect(ok, isFalse);
      expect(provider.recetas, hasLength(2));
      expect(provider.error, contains('No se pudo eliminar'));
    });
  });

  group('crear', () {
    test('agrega la receta nueva al frente de la lista', () async {
      service.testClient = fakeClient();
      service.testUserId = 'user-123';

      final ok = await provider.crear(
        RecetaUsuario(
          nombre: 'Infusión de tilo',
          descripcion: 'Para calmar',
          idealPara: const ['nervios'],
          tipo: 'remedio casero',
          tipoPreparacion: 'infusión',
          ingredientes: const ['tilo'],
          preparacion: const ['Hervir'],
        ),
      );

      expect(ok, isTrue);
      expect(provider.recetas, hasLength(1));
      expect(provider.recetas.first.nombre, 'Jarabe de jengibre');
    });
  });

  group('actualizar', () {
    test('reemplaza la receta editada en la lista', () async {
      service.testClient = fakeClient();
      service.testUserId = 'user-123';
      await provider.load();
      expect(provider.recetas, hasLength(2));

      final original = provider.recetas.first;
      final ok = await provider.actualizar(
        RecetaUsuario(
          id: original.id,
          usuarioId: original.usuarioId,
          nombre: 'Jarabe de jengibre V2',
          descripcion: original.descripcion,
          idealPara: original.idealPara,
          tipo: original.tipo,
          tipoPreparacion: original.tipoPreparacion,
          cuandoUsar: original.cuandoUsar,
          precaucion: original.precaucion,
          ingredientes: original.ingredientes,
          preparacion: original.preparacion,
          dosis: original.dosis,
          almacenamiento: original.almacenamiento,
          creadoAt: original.creadoAt,
          actualizadoAt: original.actualizadoAt,
        ),
      );

      expect(ok, isTrue);
      expect(provider.recetas, hasLength(2));
      expect(provider.recetas.first.nombre, 'Jarabe de jengibre V2');
      expect(provider.recetas.first.id, 'a1');
    });
  });
}
