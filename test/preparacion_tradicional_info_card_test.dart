import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/presentation/widgets/preparacion_tradicional_info_card.dart';

void main() {
  Widget buildCard() {
    return const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PreparacionTradicionalInfoCard(),
        ),
      ),
    );
  }

  testWidgets('tarjeta inicia colapsada mostrando título', (tester) async {
    await tester.pumpWidget(buildCard());
    expect(find.text('Preparación tradicional'), findsOneWidget);
    expect(find.text('Infusión · Decocción · Maceración'), findsOneWidget);

    // Contenido colapsado: no visible ni interactuable (AnimatedCrossFade
    // mantiene el hijo oculto montado con opacidad 0 → hitTestable()).
    expect(find.text('Combos tradicionales').hitTestable(), findsNothing);
  });

  testWidgets('al expandir muestra el contenido completo', (tester) async {
    await tester.pumpWidget(buildCard());

    // Tap en el header para expandir
    await tester.tap(find.text('Preparación tradicional'));
    await tester.pumpAndSettle();

    // Métodos: Infusión, Decocción, Maceración
    expect(find.textContaining('Infusión'), findsAtLeast(1));
    expect(find.textContaining('Decocción'), findsAtLeast(1));
    expect(find.textContaining('Maceración'), findsAtLeast(1));

    // Combos tradicionales (mate de yuyos)
    expect(find.text('Combos tradicionales'), findsOneWidget);
    expect(
      find.textContaining('mates de yuyos'),
      findsOneWidget,
    );

    // Nota regional (nombres variables)
    expect(find.text('Ojo con los nombres'), findsOneWidget);
    expect(
      find.textContaining('mil hombres'),
      findsOneWidget,
    );
  });

  testWidgets('al colapsar oculta el contenido', (tester) async {
    await tester.pumpWidget(buildCard());

    // Expandir
    await tester.tap(find.text('Preparación tradicional'));
    await tester.pumpAndSettle();
    expect(find.text('Combos tradicionales').hitTestable(), findsOneWidget);

    // Colapsar
    await tester.tap(find.text('Preparación tradicional'));
    await tester.pumpAndSettle();
    expect(find.text('Combos tradicionales').hitTestable(), findsNothing);
  });
}