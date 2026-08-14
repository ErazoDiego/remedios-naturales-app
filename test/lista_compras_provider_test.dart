import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:remedios_naturales_app/features/lista_compras/domain/item_lista.dart';
import 'package:remedios_naturales_app/features/lista_compras/presentation/lista_compras_provider.dart';

void main() {
  group('ItemLista', () {
    test('desdeIngrediente: token normalizado + texto original en cantidades',
        () {
      final item = ItemLista.desdeIngrediente(
        '12 huevos',
        esManual: true,
      );
      expect(item.tokenBase, 'huevos');
      expect(item.cantidades, ['12 huevos']); // El dato NO se toca.
      expect(item.esManual, isTrue);
      expect(item.nombreMostrable, 'Huevos');
    });

    test('desdeIngrediente de receta lleva el nombre de la receta', () {
      final item = ItemLista.desdeIngrediente(
        '1 taza de agua',
        deReceta: 'Infusión digestiva',
      );
      expect(item.tokenBase, 'agua');
      expect(item.deRecetas, ['Infusión digestiva']);
      expect(item.esManual, isFalse);
    });

    test('agregar: acumula cantidades distintas y recetas, sin duplicar', () {
      var item = ItemLista.desdeIngrediente(
        '1 taza de agua',
        deReceta: 'Receta A',
      );
      // Misma cantidad exacta de otra receta → no duplica cantidad.
      item = item.agregar('1 taza de agua', deReceta: 'Receta B');
      expect(item.cantidades, ['1 taza de agua']);
      expect(item.deRecetas, ['Receta A', 'Receta B']);

      // Cantidad distinta (misma llave) → se acumula.
      item = item.agregar('500 ml de agua', deReceta: 'Receta B');
      expect(item.cantidades, ['1 taza de agua', '500 ml de agua']);
      expect(item.deRecetas, ['Receta A', 'Receta B']);
    });

    test('copiarMarcado alterna el toggle sin mutar el original', () {
      final item = ItemLista.desdeIngrediente('huevos', esManual: true);
      final marcado = item.copiarMarcado(true);
      expect(item.marcado, isFalse);
      expect(marcado.marcado, isTrue);
      expect(marcado.cantidades, item.cantidades);
    });

    test('fromJson/toJson roundtrip', () {
      final item = ItemLista(
        tokenBase: 'agua',
        cantidades: ['1 taza de agua', '500 ml de agua'],
        deRecetas: ['Receta A'],
        esManual: false,
        marcado: true,
      );
      final restaurado = ItemLista.fromJson(item.toJson());
      expect(restaurado.tokenBase, 'agua');
      expect(restaurado.cantidades, ['1 taza de agua', '500 ml de agua']);
      expect(restaurado.deRecetas, ['Receta A']);
      expect(restaurado.esManual, isFalse);
      expect(restaurado.marcado, isTrue);
    });
  });

  group('ListaComprasProvider', () {
    late ListaComprasProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ListaComprasProvider();
    });

    test('agregarDesdeReceta agrupa por token (agua en todas sus variantes)',
        () {
      provider.agregarDesdeReceta('Receta A', ['1 taza de agua']);
      provider.agregarDesdeReceta('Receta B', ['500 ml de agua']);
      provider.agregarDesdeReceta('Receta C', ['1 litro de agua']);

      expect(provider.totalItems, 1);
      final agua = provider.items.single;
      expect(agua.tokenBase, 'agua');
      expect(agua.cantidades, ['1 taza de agua', '500 ml de agua', '1 litro de agua']);
      expect(agua.deRecetas, ['Receta A', 'Receta B', 'Receta C']);
    });

    test('agregar la MISMA receta dos veces no duplica nada', () {
      provider.agregarDesdeReceta('Tortilla', ['2 huevos', '1 taza de agua']);
      provider.agregarDesdeReceta('Tortilla', ['2 huevos', '1 taza de agua']);

      expect(provider.totalItems, 2);
      final huevos = provider.items.firstWhere((i) => i.tokenBase == 'huevos');
      expect(huevos.cantidades, ['2 huevos']);
      expect(huevos.deRecetas, ['Tortilla']);
    });

    test('ítem manual y receta con el mismo ingrediente AGrupan (12 huevos)',
        () {
      provider.agregarManual('12 huevos');
      provider.agregarDesdeReceta('Tortilla', ['2 huevos']);

      expect(provider.totalItems, 1);
      final huevos = provider.items.single;
      expect(huevos.tokenBase, 'huevos');
      // El dato del usuario es sagrado: "12 huevos" intacto, nunca sumado.
      expect(huevos.cantidades, ['12 huevos', '2 huevos']);
      expect(huevos.esManual, isTrue);
    });

    test('agregarManual ignora texto vacío y recorta espacios', () {
      provider.agregarManual('   ');
      provider.agregarManual('  huevos  ');
      expect(provider.totalItems, 1);
      expect(provider.items.single.cantidades, ['huevos']);
    });

    test('toggleMarcado, quitarItem y vaciar', () {
      provider.agregarManual('huevos');
      provider.agregarManual('pan');

      provider.toggleMarcado('huevos');
      expect(provider.items.firstWhere((i) => i.tokenBase == 'huevos').marcado,
          isTrue);

      provider.quitarItem('pan');
      expect(provider.totalItems, 1);
      expect(provider.items.single.tokenBase, 'huevos');

      provider.vaciar();
      expect(provider.totalItems, 0);
    });

    test('exportarTexto: formato legible con estados y orígenes', () {
      provider.agregarManual('12 huevos');
      provider.agregarDesdeReceta('Tortilla', ['2 huevos', '1 taza de agua']);
      provider.toggleMarcado('agua');

      final texto = provider.exportarTexto();
      expect(texto, contains('Lista de compras'));
      expect(texto, contains('Huevos'));
      expect(texto, contains('   - 12 huevos'));
      expect(texto, contains('   - 2 huevos'));
      expect(texto, contains('Tortilla'));
      expect(texto, contains('☐ Huevos'));
      expect(texto, contains('✅ Agua'));
    });

    test('persistencia: un provider nuevo recupera la lista guardada', () async {
      provider.agregarManual('huevos');
      provider.agregarDesdeReceta('Tortilla', ['2 huevos']);
      provider.toggleMarcado('huevos');

      // Espera a que la persistencia (fire-and-forget) escriba.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final nuevo = ListaComprasProvider()..init();
      await Future<void>.delayed(Duration.zero);

      expect(nuevo.items, hasLength(1));
      final huevos = nuevo.items.single;
      expect(huevos.cantidades, ['huevos', '2 huevos']);
      expect(huevos.marcado, isTrue);
      expect(huevos.esManual, isTrue);
    });

    test('init con lista corrupta no revienta (best-effort)', () async {
      SharedPreferences.setMockInitialValues({
        'lista_compras_v1': 'esto no es json {',
      });
      final corrupto = ListaComprasProvider();
      await corrupto.init();
      expect(corrupto.items, isEmpty);
    });
  });
}
