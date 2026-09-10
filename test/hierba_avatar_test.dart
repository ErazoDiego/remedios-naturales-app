import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/presentation/widgets/hierba_avatar.dart';

/// Avatar de hierba: imagen `assets/images/hierbas/<id>.webp` con fallback
/// a la inicial del nombre cuando el asset aún no existe. Verifica ambos
/// comportamientos y la ruta canónica.
void main() {
  testWidgets('sin imagen: muestra la inicial como fallback sin romper',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HierbaAvatar(
            hierbaId: 'hierba_sin_imagen',
            nombre: 'Manzanilla',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('M'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usa la ruta canónica assets/images/hierbas/<id>.webp',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HierbaAvatar(hierbaId: 'manzanilla', nombre: 'Manzanilla'),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final asset = image.image as AssetImage;
    expect(
      asset.assetName,
      'assets/images/hierbas/manzanilla.webp',
    );
  });

  testWidgets('nombre vacío: fallback con "?"', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HierbaAvatar(hierbaId: 'x', nombre: '   '),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('?'), findsOneWidget);
  });
}