import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/data/services/auth_service.dart';
import 'package:remedios_naturales_app/presentation/providers/user_provider.dart';
import 'package:remedios_naturales_app/presentation/screens/forgot_password/forgot_password_screen.dart';
import 'package:remedios_naturales_app/presentation/screens/login/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ForgotPasswordScreen: validación, envío del link y manejo de errores.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService auth;

  /// AuthService con MockClient (sin red): el flujo se resuelve contra
  /// el handler, no contra Supabase real.
  ///
  /// autoRefreshToken:false porque gotrue arranca un Timer.periodic de
  /// auto-refresh en el constructor (default true) que jamás se apaga solo
  /// y hace fallar testWidgets (timers pendientes al final del test).
  void withMock(Future<http.Response> Function(http.Request) handler) {
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
  }

  setUp(() {
    auth = AuthService();
  });

  Future<void> pumpForgotPassword(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
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

  testWidgets('email vacío no envía nada y muestra error', (tester) async {
    await pumpForgotPassword(tester);

    await tester.tap(find.text('Enviar link de recuperación'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresá tu email'), findsOneWidget);
  });

  testWidgets('email inválido no envía nada y muestra error', (tester) async {
    await pumpForgotPassword(tester);

    await tester.enterText(find.byType(TextFormField), 'no-es-email');
    await tester.tap(find.text('Enviar link de recuperación'));
    await tester.pumpAndSettle();

    expect(find.text('El email no es válido'), findsOneWidget);
  });

  testWidgets('envía el link y navega a login con confirmación',
      (tester) async {
    withMock((request) async {
      expect(request.url.path, '/auth/v1/recover');
      expect(
        request.url.queryParameters['redirect_to'],
        AuthService.passwordRecoveryRedirect,
      );
      return http.Response('', 200);
    });

    await pumpForgotPassword(tester);

    await tester.enterText(find.byType(TextFormField), 'olvido@email.com');
    await tester.tap(find.text('Enviar link de recuperación'));
    await tester.pumpAndSettle();

    // Confirmación visible + navegación a login
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Deja expirar el timer del SnackBar (si no, el test falla al final)
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('error del backend se muestra en snackbar sin navegar',
      (tester) async {
    withMock((request) async {
      return http.Response(
        json.encode({'msg': 'Email not found'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    });

    await pumpForgotPassword(tester);

    await tester.enterText(find.byType(TextFormField), 'no@email.com');
    await tester.tap(find.text('Enviar link de recuperación'));
    await tester.pumpAndSettle();

    // Sigue en la pantalla, con el snackbar de error
    expect(find.text('Recuperar contraseña'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);

    // Deja expirar el timer del SnackBar
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
