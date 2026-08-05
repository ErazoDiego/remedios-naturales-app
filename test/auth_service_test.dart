import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remedios_naturales_app/data/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests de AuthService con MockClient (sin red real).
///
/// SupabaseClient acepta un httpClient inyectable, así que simulamos
/// gotrue (el backend de auth) respondiendo como lo haría el servidor real.
void main() {
  late AuthService auth;

  /// Respuesta estándar de una sesión exitosa de gotrue
  Map<String, dynamic> sessionJson({String email = 'test@email.com'}) {
    return {
      'access_token': 'jwt-token-fake',
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'refresh-token-fake',
      'user': {
        'id': 'user-123',
        'email': email,
        'role': 'authenticated',
        'aud': 'authenticated',
      },
    };
  }

  /// Crea un AuthService con un cliente fake conectado al mock handler.
  AuthService withMock(Future<http.Response> Function(http.Request) handler) {
    final client = SupabaseClient(
      'http://localhost:54321',
      'fake-publishable-key',
      httpClient: MockClient(handler),
      // En tests no hay asyncStorage: el flujo PKCE (default) lanza una
      // assertion. Con implicit no se genera PKCE y todo funciona offline.
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    auth.client = client;
    return auth;
  }

  setUp(() {
    auth = AuthService();
  });

  group('signIn', () {
    test('con credenciales válidas devuelve success y setea sesión',
        () async {
      withMock((request) async {
        expect(request.url.path, '/auth/v1/token');
        expect(request.url.queryParameters['grant_type'], 'password');
        return http.Response(
          json.encode(sessionJson()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await auth.signIn(
        email: 'test@email.com',
        password: '123456',
      );

      expect(result.success, true);
      expect(result.error, isNull);
      expect(auth.isLoggedIn, true);
      expect(auth.currentUser?.id, 'user-123');
      expect(auth.currentUser?.email, 'test@email.com');
    });

    test('con credenciales inválidas devuelve error humanizado', () async {
      withMock((request) async {
        return http.Response(
          json.encode({'msg': 'Invalid login credentials'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await auth.signIn(
        email: 'mal@email.com',
        password: 'incorrecta',
      );

      expect(result.success, false);
      expect(result.error, 'Email o contraseña incorrectos');
      expect(auth.isLoggedIn, false);
    });

    test('si el email no está confirmado, avisa', () async {
      withMock((request) async {
        return http.Response(
          json.encode({'msg': 'Email not confirmed'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await auth.signIn(
        email: 'sinconfirmar@email.com',
        password: '123456',
      );

      expect(result.success, false);
      expect(result.error, 'Confirmá tu email antes de iniciar sesión');
    });
  });

  group('signUp', () {
    test('sin confirmación de email: sesión directa', () async {
      withMock((request) async {
        expect(request.url.path, '/auth/v1/signup');
        return http.Response(
          json.encode(sessionJson()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await auth.signUp(
        email: 'nuevo@email.com',
        password: '123456',
      );

      expect(result.success, true);
      expect(result.emailConfirmationRequired, false);
      expect(auth.isLoggedIn, true);
    });

    test('con confirmación de email: session null → requiere confirmar',
        () async {
      withMock((request) async {
        return http.Response(
          json.encode({
            'user': {
              'id': 'user-456',
              'email': 'nuevo@email.com',
              'role': 'authenticated',
            },
            // Sin "session" → el backend pidió confirmar email
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await auth.signUp(
        email: 'nuevo@email.com',
        password: '123456',
      );

      expect(result.success, true);
      expect(result.emailConfirmationRequired, true);
      expect(auth.isLoggedIn, false);
    });

    test('email ya registrado devuelve error humanizado', () async {
      withMock((request) async {
        return http.Response(
          json.encode({'msg': 'User already registered'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await auth.signUp(
        email: 'duplicado@email.com',
        password: '123456',
      );

      expect(result.success, false);
      expect(result.error, 'Ya existe una cuenta con ese email');
    });
  });

  group('signOut', () {
    test('cierra la sesión correctamente', () async {
      withMock((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            json.encode(sessionJson()),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/auth/v1/logout') {
          return http.Response('', 204);
        }
        return http.Response('Not found', 404);
      });

      await auth.signIn(email: 'test@email.com', password: '123456');
      expect(auth.isLoggedIn, true);

      final result = await auth.signOut();

      expect(result.success, true);
      expect(auth.isLoggedIn, false);
      expect(auth.currentUser, isNull);
    });
  });
}
