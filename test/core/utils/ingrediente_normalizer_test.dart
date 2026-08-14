import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:remedios_naturales_app/core/utils/ingrediente_normalizer.dart';

void main() {
  group('normalizarIngrediente — casos reales del catálogo', () {
    test('misma agua con distintas cantidades agrupa en "agua"', () {
      expect(normalizarIngrediente('1 taza de agua'), 'agua');
      expect(normalizarIngrediente('500 ml de agua'), 'agua');
      expect(normalizarIngrediente('1 litro de agua'), 'agua');
      expect(normalizarIngrediente('2 cucharadas de agua tibia'), 'agua tibia');
    });

    test('ítems manuales del usuario: cantidad conservada en el dato, '
        'llave limpia', () {
      // "12 huevos" a mano + "2 huevos" de una receta → MISMA llave.
      expect(normalizarIngrediente('12 huevos'), 'huevos');
      expect(normalizarIngrediente('2 huevos'), 'huevos');
      // La llave no toca el dato real: eso lo garantiza el provider.
    });

    test('unidades compuestas con adjetivo', () {
      expect(
        normalizarIngrediente('1 trocito pequeño de jengibre'),
        'jengibre',
      );
      expect(normalizarIngrediente('1 rodaja fina de limón'), 'limon');
      expect(normalizarIngrediente('1 puñado pequeño de perejil'), 'perejil');
      expect(normalizarIngrediente('2 ramitas de perejil fresco'), 'perejil fresco');
      expect(normalizarIngrediente('1 cebolla mediana'), 'cebolla mediana');
      expect(normalizarIngrediente('½ manzana verde'), 'manzana verde');
    });

    test('sustantivos que NO son unidades de medida se conservan', () {
      // La llave normaliza ñ→n SIEMPRE (regla de normalizarTexto).
      expect(normalizarIngrediente('1 paño limpio'), 'pano limpio');
      expect(normalizarIngrediente('1 frasco de vidrio'), 'frasco de vidrio');
      expect(
        normalizarIngrediente('frasco roll-on de vidrio oscuro'),
        'frasco roll-on de vidrio oscuro',
      );
      expect(
        normalizarIngrediente('toalla o paño grueso'),
        'toalla o pano grueso',
      );
    });

    test('cantidad en medio de la frase (jugo de X limón)', () {
      expect(normalizarIngrediente('jugo de 1 limón'), 'jugo de limon');
      expect(normalizarIngrediente('jugo de ½ limón'), 'jugo de limon');
      expect(normalizarIngrediente('jugo de medio limón (opcional)'), 'jugo de limon');
    });

    test('rangos de cantidad', () {
      expect(
        normalizarIngrediente('3 a 4 gotas de aceite esencial de menta'),
        'aceite esencial de menta',
      );
      expect(
        normalizarIngrediente('2 a 3 tazas de agua'),
        'agua',
      );
    });

    test('palabras de cantidad: una, unas, un', () {
      expect(normalizarIngrediente('una pizca de canela (opcional)'), 'canela');
      expect(normalizarIngrediente('unas gotas de limón (opcional)'), 'limon');
      expect(normalizarIngrediente('un trocito de jengibre'), 'jengibre');
    });

    test('paréntesis se eliminan (incluidos los colgantes del libro)', () {
      expect(
        normalizarIngrediente('1 cucharadita de miel pura (opcional)'),
        'miel pura',
      );
      expect(
        normalizarIngrediente(
            '1 cucharadita de alcohol o hamamelis (conservante natural)'),
        'alcohol o hamamelis',
      );
      // Dato real truncado: paréntesis SIN cierre.
      expect(
        normalizarIngrediente(
            '250 ml de alcohol de cereal o vodka (mínimo'),
        'alcohol de cereal o vodka',
      );
    });

    test('sufijos de cantidad relativa', () {
      expect(normalizarIngrediente('sal fina al gusto'), 'sal fina');
      expect(normalizarIngrediente('agua c/n'), 'agua');
    });

    test('tildes y ñ se normalizan (mismo patrón que el buscador)', () {
      expect(normalizarIngrediente('1 cucharadita de cúrcuma en polvo'),
          'curcuma en polvo');
      expect(normalizarIngrediente('2 gotas de aceite esencial de jengibre'),
          'aceite esencial de jengibre');
    });

    test('ingredientes sin cantidad se conservan completos', () {
      expect(normalizarIngrediente('Agua caliente para el baño'),
          'agua caliente para el bano');
      expect(normalizarIngrediente('Algodones o gasas'), 'algodones o gasas');
      expect(normalizarIngrediente('Gasa estéril o gotero para aplicar '
          'externamente'), 'gasa esteril o gotero para aplicar externamente');
    });

    test('fracciones con slash y decimales', () {
      expect(normalizarIngrediente('1/2 taza de miel'), 'miel');
      expect(normalizarIngrediente('1.5 litros de agua'), 'agua');
    });

    test('nunca devuelve string vacío (fallback al original)', () {
      expect(normalizarIngrediente('1 taza'), '1 taza');
      expect(normalizarIngrediente('½ cucharada'), '½ cucharada');
    });
  });

  group('smoke test — TODO el catálogo real', () {
    // Extrae TODOS los ingredientes de los JSON del núcleo y verifica
    // que el normalizador no mutile ninguno: token no vacío y sin
    // números residuales (la cantidad de la llave se fue siempre).
    final sistemas = [
      'digestivo', 'nervioso', 'respiratorio', 'inmunitario',
      'cardiovascular', 'hormonal', 'musculoesqueletico', 'urinario',
      'dermico', 'sensorial',
    ];

    final ingredientes = <String>[
      for (final sistema in sistemas)
        ..._recetasDe(sistema)
            .map((r) => List<String>.from(r['ingredientes'] ?? []))
            .expand((i) => i),
    ];

    test('ningún ingrediente del catálogo queda vacío ni con números', () {
      expect(ingredientes, isNotEmpty);
      for (final ing in ingredientes) {
        final token = normalizarIngrediente(ing);
        expect(token, isNotEmpty, reason: 'token vacío para: $ing');
        expect(
          token.contains(RegExp(r'\d|½|¼|¾')),
          isFalse,
          reason: 'token con cantidad residual para: $ing → "$token"',
        );
      }
    });

    test('agua: todas sus variantes reales agrupan', () {
      final aguas = ingredientes
          .where((i) => i.contains('agua'))
          .map(normalizarIngrediente)
          .where((t) => t == 'agua');
      expect(aguas.length, greaterThanOrEqualTo(10),
          reason: 'se esperaban las ~15 variantes de agua');
    });
  });
}

/// Lee las recetas del JSON de un sistema embebido (assets/data/).
List<Map<String, dynamic>> _recetasDe(String sistema) {
  final file = File('assets/data/$sistema.json');
  final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  return [
    for (final r in data['recetas'] as List<dynamic>)
      Map<String, dynamic>.from(r as Map),
  ];
}
