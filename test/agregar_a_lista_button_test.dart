import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:remedios_naturales_app/features/lista_compras/presentation/lista_compras_provider.dart';
import 'package:remedios_naturales_app/presentation/widgets/agregar_a_lista_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AgregarAListaButton: agrega al provider y muestra el SnackBar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ListaComprasProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = ListaComprasProvider()..init();
  });

  Future<void> pumpBoton(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ListaComprasProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: AgregarAListaButton(
              recetaNombre: 'Tortilla',
              ingredientes: ['2 huevos', '1 taza de agua'],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('el tap agrega TODOS los ingredientes de la receta',
      (tester) async {
    await pumpBoton(tester);

    await tester.tap(find.text('Agregar a la lista de compras'));
    await tester.pump();

    expect(provider.totalItems, 2);
    expect(
      provider.items.firstWhere((i) => i.tokenBase == 'huevos').deRecetas,
      ['Tortilla'],
    );
  });

  testWidgets('agregar la misma receta dos veces no duplica',
      (tester) async {
    await pumpBoton(tester);

    await tester.tap(find.text('Agregar a la lista de compras'));
    await tester.pump();
    await tester.tap(find.text('Agregar a la lista de compras'));
    await tester.pump();

    final huevos = provider.items.firstWhere((i) => i.tokenBase == 'huevos');
    expect(huevos.cantidades, ['2 huevos']);
    expect(huevos.deRecetas, ['Tortilla']);
  });

  testWidgets('muestra SnackBar de confirmación', (tester) async {
    await pumpBoton(tester);

    await tester.tap(find.text('Agregar a la lista de compras'));
    await tester.pump();

    expect(find.text('Agregado a la lista de compras'), findsOneWidget);
  });
}
