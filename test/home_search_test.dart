import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:remedios_naturales_app/core/services/payments/mock_payment_service.dart';
import 'package:remedios_naturales_app/data/models/hierba.dart';
import 'package:remedios_naturales_app/data/repositories/hierbas_repository.dart';
import 'package:remedios_naturales_app/data/services/recetas_service.dart';
import 'package:remedios_naturales_app/features/lista_compras/presentation/lista_compras_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/premium_provider.dart';
import 'package:remedios_naturales_app/presentation/providers/recetas_provider.dart';
import 'package:remedios_naturales_app/presentation/screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El buscador del home usa el MISMO motor del buscador global:
/// - encuentra hierbas del herbolario (por alias y normalizando tildes)
/// - muestra estado vacío cuando no hay resultados
///
/// IMPORTANTE: el motor real se inyecta con una [HierbasDataSource] FAKE.
/// El JSON real (hierbas.json, ~61 KB) cuelga el canal de assets de
/// testWidgets (los assets >~30 KB requieren runAsync) y hace timeout en
/// pumpAndSettle. El herbolario real ya está cubierto por los tests
/// planos de hierbas_provider_test / hierbas_service_test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ListaComprasProvider listaProvider;
  late PremiumProvider premiumProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'ads_disclosure_shown': true, // evitar el diálogo de divulgación
    });
    listaProvider = ListaComprasProvider()..init();
    premiumProvider = PremiumProvider(payment: MockPaymentService());
  });

  Hierba hierba(String id, String nombre, List<String> alias,
          String usoTradicional, List<String> tags) =>
      Hierba(
        id: id,
        nombre: nombre,
        alias: alias,
        usoTradicional: usoTradicional,
        tags: tags,
      );

  Future<void> pumpHome(WidgetTester tester) async {
    final service = RecetasService(
      hierbasRepository: _FakeHierbasRepo([
        hierba('amargon', 'Amargón', const ['Diente de león'],
            'Pérdida de apetito, digestivo', const ['digestivo']),
        hierba('higuera', 'Higuera', const [],
            'Hipoglucemiante, laxante', const ['metabolico']),
      ]),
    );
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/herba/:herbaId',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('ficha hierba')),
          ),
        ),
        GoRoute(
          path: '/remedy/:recipeId',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('ficha receta')),
          ),
        ),
        GoRoute(
          path: '/category/:systemId',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('categoría')),
          ),
        ),
        GoRoute(
          path: '/lista-compras',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('lista')),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => RecetasProvider(service: service),
          ),
          ChangeNotifierProvider<PremiumProvider>.value(
            value: premiumProvider,
          ),
          ChangeNotifierProvider<ListaComprasProvider>.value(
            value: listaProvider,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('buscar por alias encuentra la hierba del herbolario',
      (tester) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'diente de le');
    await tester.pumpAndSettle();

    // Encontrada POR ALIAS (el nombre no contiene "diente"). Las recetas
    // con "diente" (ej. pasta dental) ganan por score, así que la card de
    // hierba queda más abajo: hay que scrollear igual que el usuario.
    await tester.dragUntilVisible(
      find.text('Amargón'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Amargón'), findsOneWidget);
    expect(find.text('Hierba'), findsWidgets);
  });

  testWidgets('buscar sin tilde encuentra la hierba', (tester) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'higuera');
    await tester.pumpAndSettle();

    expect(find.text('Higuera'), findsWidgets);
  });

  testWidgets('búsqueda sin resultados muestra el estado vacío',
      (tester) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();

    expect(find.text('No se encontraron resultados'), findsOneWidget);
    expect(find.text('Probá con otro término'), findsOneWidget);
  });

  testWidgets('limpiar la búsqueda vuelve al contenido principal',
      (tester) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron resultados'), findsOneWidget);

    // Tocar la X del campo limpia y restaura el home.
    await tester.tap(find.byIcon(TablerIcons.x));
    await tester.pumpAndSettle();

    expect(find.text('Sistemas del cuerpo'), findsOneWidget);
  });
}

class _FakeHierbasRepo implements HierbasDataSource {
  final List<Hierba> hierbas;

  _FakeHierbasRepo(this.hierbas);

  @override
  Future<List<Hierba>> getHierbas() async => hierbas;
}