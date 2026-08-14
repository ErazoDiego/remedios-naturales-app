import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/features/lista_compras/presentation/lista_compras_provider.dart';
import 'package:remedios_naturales_app/features/lista_compras/presentation/lista_compras_screen.dart';
import 'package:remedios_naturales_app/presentation/providers/recetas_provider.dart';
import 'package:remedios_naturales_app/presentation/screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HomeScreen: el acceso a la lista de compras con contador navega a la
/// pantalla de la lista (con datos reales de assets).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ListaComprasProvider listaProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    listaProvider = ListaComprasProvider()..init();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/lista-compras',
          builder: (context, state) => const ListaComprasScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RecetasProvider()),
          ChangeNotifierProvider<ListaComprasProvider>.value(
            value: listaProvider,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ícono de carrito en el header sin badge cuando está vacía',
      (tester) async {
    await pumpHome(tester);

    // Acceso permanente pero sin peso visual: ícono sin numerito.
    expect(find.byTooltip('Lista de compras'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    // El contenido principal arranca directo: sin card intermedio.
    expect(find.text('Sistemas del cuerpo'), findsOneWidget);
    expect(find.text('Agregá ingredientes desde las recetas'), findsNothing);
  });

  testWidgets('con ítems el badge muestra el número de ítems', (tester) async {
    listaProvider.agregarManual('12 huevos');
    listaProvider.agregarManual('pan');
    await pumpHome(tester);

    // Badge numérico con el total de ítems agrupados.
    expect(find.byTooltip('Lista de compras'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('tocar el carrito navega a la lista de compras',
      (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Lista de compras'));
    await tester.pumpAndSettle();

    expect(find.text('Tu lista está vacía'), findsOneWidget);
  });
}
