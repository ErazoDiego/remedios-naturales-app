import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/features/lista_compras/presentation/lista_compras_provider.dart';
import 'package:remedios_naturales_app/features/lista_compras/presentation/lista_compras_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabler_icons/tabler_icons.dart';

/// ListaComprasScreen: estado vacío, agregar manual, toggle de comprado,
/// quitar, vaciar con confirmación y el icono de compartir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ListaComprasProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = ListaComprasProvider()..init();
  });

  Future<void> pumpPantalla(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/lista-compras',
      routes: [
        GoRoute(
          path: '/lista-compras',
          builder: (context, state) => const ListaComprasScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ListaComprasProvider>.value(
        value: provider,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista vacía: estado vacío y sin acciones', (tester) async {
    await pumpPantalla(tester);

    expect(find.text('Tu lista está vacía'), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
    // Sin ítems no hay iconos de compartir ni vaciar
    expect(find.byTooltip('Compartir'), findsNothing);
    expect(find.byTooltip('Vaciar lista'), findsNothing);
  });

  testWidgets('agregar ítem manual: aparece con su cantidad intacta',
      (tester) async {
    await pumpPantalla(tester);

    await tester.enterText(find.byType(TextField), '12 huevos');
    await tester.tap(find.byIcon(TablerIcons.plus));
    await tester.pumpAndSettle();

    // Llave agrupada capitalizada + dato tal cual
    expect(find.text('Huevos'), findsOneWidget);
    expect(find.text('12 huevos'), findsOneWidget);
    // El campo se limpia
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('dedupe visual: manual + receta agrupan en una card',
      (tester) async {
    provider.agregarManual('12 huevos');
    provider.agregarDesdeReceta('Tortilla', ['2 huevos']);
    await pumpPantalla(tester);

    expect(find.text('Huevos'), findsOneWidget);
    expect(find.text('12 huevos'), findsOneWidget);
    expect(find.text('2 huevos'), findsOneWidget);
    expect(find.textContaining('Tortilla'), findsOneWidget);
  });

  testWidgets('toggle de comprado alterna el estado del ítem',
      (tester) async {
    provider.agregarManual('huevos');
    await pumpPantalla(tester);

    expect(provider.items.single.marcado, isFalse);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(provider.items.single.marcado, isTrue);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(provider.items.single.marcado, isFalse);
  });

  testWidgets('quitar: la X elimina el ítem de la lista', (tester) async {
    provider.agregarManual('huevos');
    provider.agregarManual('pan');
    await pumpPantalla(tester);

    expect(provider.totalItems, 2);
    await tester.tap(find.byTooltip('Quitar').first);
    await tester.pumpAndSettle();
    expect(provider.totalItems, 1);
    expect(find.text('Pan'), findsOneWidget);
  });

  testWidgets('vaciar: pide confirmación antes de borrar todo',
      (tester) async {
    provider.agregarManual('huevos');
    provider.agregarManual('pan');
    await pumpPantalla(tester);

    // Cancelar no borra nada
    await tester.tap(find.byTooltip('Vaciar lista'));
    await tester.pumpAndSettle();
    expect(find.text('¿Vaciar la lista?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(provider.totalItems, 2);

    // Confirmar vacía
    await tester.tap(find.byTooltip('Vaciar lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vaciar'));
    await tester.pumpAndSettle();
    expect(provider.totalItems, 0);
    expect(find.text('Tu lista está vacía'), findsOneWidget);
  });

  testWidgets('con ítems aparecen las acciones compartir y vaciar',
      (tester) async {
    provider.agregarManual('huevos');
    await pumpPantalla(tester);

    expect(find.byTooltip('Compartir'), findsOneWidget);
    expect(find.byTooltip('Vaciar lista'), findsOneWidget);
  });
}
