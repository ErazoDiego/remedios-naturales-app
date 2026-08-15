import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/data/services/auth_service.dart';
import 'package:remedios_naturales_app/presentation/providers/user_provider.dart';
import 'package:remedios_naturales_app/presentation/screens/login/login_screen.dart';
import 'package:remedios_naturales_app/presentation/screens/reset_password/reset_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ResetPasswordScreen: validación, actualización de contraseña y errores.
///
/// La sesión de recovery la provee el backend (el deep link ya validó el
/// token): en los tests se simula con [SupabaseClient.setSession] antes de
/// montar la pantalla, como llega en la app real.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService auth;

  /// Respuesta estándar de una sesión exitosa de gotrue.
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

  /// Crea un AuthService con un client fake conectado al mock handler.
  ///
  /// autoRefreshToken:false porque gotrue arranca un Timer.periodic de
  /// auto-refresh en el constructor (default true) que jamás se apaga solo
  /// y hace fallar testWidgets (timers pendientes al final del test).
  SupabaseClient withMock(
      Future<http.Response> Function(http.Request) handler) {
    final client = SupabaseClient(
      'http://localhost:54321',
      'fake-publishable-key',
      httpClient: MockClient(handler),
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
      ),
    );
    auth.client = client;
    return client;
  }

  /// Simula la sesión de recovery ya activa: setSession sin accessToken
  /// dispara un refresh (POST /auth/v1/token) que el mock responde.
  Future<void> seedRecoverySession(SupabaseClient client) async {
    await client.auth.setSession('refresh-token-fake');
  }

  setUp(() {
    auth = AuthService();
  });

  Future<void> pumpResetPassword(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/reset-password',
      routes: [
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(auth: auth),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('contraseña corta no envía y muestra error', (tester) async {
    await pumpResetPassword(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      '123',
    );
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña debe tener al menos 6 caracteres'),
        findsOneWidget);
  });

  testWidgets('contraseñas que no coinciden muestran error', (tester) async {
    await pumpResetPassword(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'nueva-12345',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repetí la contraseña'),
      'otra-distinta',
    );
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  testWidgets('actualiza la contraseña y navega a login', (tester) async {
    final client = withMock((request) async {
      if (request.url.path == '/auth/v1/token') {
        // refresh de la sesión de recovery
        return http.Response(
          json.encode(sessionJson()),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      expect(request.url.path, '/auth/v1/user');
      expect(request.method, 'PUT');
      final body = json.decode(request.body) as Map<String, dynamic>;
      expect(body['password'], 'nueva-12345');
      return http.Response(
        json.encode({
          'id': 'user-123',
          'email': 'test@email.com',
          'role': 'authenticated',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    await seedRecoverySession(client);

    await pumpResetPassword(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'nueva-12345',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repetí la contraseña'),
      'nueva-12345',
    );
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    // Navegó a login
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Deja expirar el timer del SnackBar (si no, el test falla al final)
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('error del backend se muestra en snackbar sin navegar',
      (tester) async {
    final client = withMock((request) async {
      if (request.url.path == '/auth/v1/token') {
        // refresh de la sesión de recovery
        return http.Response(
          json.encode(sessionJson()),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        json.encode({'msg': 'Invalid JWT'}),
        401,
        headers: {'content-type': 'application/json'},
      );
    });
    await seedRecoverySession(client);

    await pumpResetPassword(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'nueva-12345',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repetí la contraseña'),
      'nueva-12345',
    );
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('Contraseña nueva').first, findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);

    // Deja expirar el timer del SnackBar
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
