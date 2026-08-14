import '../../../core/utils/ingrediente_normalizer.dart';

/// Ítem de la LISTA DE COMPRAS: un ingrediente agrupado por su LLAVE
/// normalizada (tokenBase) con TODOS sus datos reales intactos.
///
/// Diseño (regla de oro): el [tokenBase] solo sirve para AGRUPAR y
/// deduplicar ("12 huevos" a mano y "2 huevos" de una receta → MISMA
/// llave "huevos"). El dato real vive en [cantidades] tal cual se
/// escribió — nunca se modifica ni se suma.
///
/// Dos orígenes:
///  - De receta ([esManual] = false): cada cantidad aportada por una
///    receta del catálogo/colección/propia, con el nombre de la receta
///    en [deRecetas] (se muestra directo, sin resolver catálogo).
///  - Manual ([esManual] = true): el texto que escribió el usuario
///    ("huevos", "12 huevos") — la lista es DEL usuario, las recetas
///    solo la alimentan.
///
/// [marcado] es el toggle del super (tachar lo que ya está en el changuito).
class ItemLista {
  final String tokenBase;
  final List<String> cantidades;
  final List<String> deRecetas;
  final bool esManual;
  final bool marcado;

  const ItemLista({
    required this.tokenBase,
    required this.cantidades,
    required this.deRecetas,
    required this.esManual,
    this.marcado = false,
  });

  /// Nombre mostrable derivado del token: "agua tibia" → "Agua tibia".
  String get nombreMostrable {
    if (tokenBase.isEmpty) return '';
    return tokenBase[0].toUpperCase() + tokenBase.substring(1);
  }

  /// Crea el ítem a partir de UN ingrediente (receta o manual).
  /// [esManual] distingue el origen (default: receta); el texto
  /// original va a [cantidades].
  factory ItemLista.desdeIngrediente(
    String ingrediente, {
    bool esManual = false,
    String? deReceta,
  }) {
    return ItemLista(
      tokenBase: normalizarIngrediente(ingrediente),
      cantidades: [ingrediente],
      deRecetas: deReceta == null ? const [] : [deReceta],
      esManual: esManual,
    );
  }

  /// Une OTRA aparición del mismo ingrediente (misma llave) al ítem:
  /// agrega la cantidad si no está duplicada exacta y la receta si no
  /// está. Devuelve un ítem NUEVO (inmutabilidad: los cambios de la
  /// lista se hacen reemplazando ítems, nunca mutando).
  ///
  /// El flag [esManual] se conserva si el ítem ALGUNA vez fue manual
  /// (la lista es del usuario: un aporte de receta no lo "desmanuali­za").
  ItemLista agregar(
    String ingrediente, {
    String? deReceta,
    bool? esManual,
  }) {
    return ItemLista(
      tokenBase: tokenBase,
      cantidades: cantidades.contains(ingrediente)
          ? cantidades
          : [...cantidades, ingrediente],
      deRecetas: deReceta == null || deRecetas.contains(deReceta)
          ? deRecetas
          : [...deRecetas, deReceta],
      esManual: this.esManual || (esManual ?? false),
      marcado: marcado,
    );
  }

  /// Toggle de marcado (comprado en el super).
  ItemLista copiarMarcado(bool marcado) {
    return ItemLista(
      tokenBase: tokenBase,
      cantidades: cantidades,
      deRecetas: deRecetas,
      esManual: esManual,
      marcado: marcado,
    );
  }

  factory ItemLista.fromJson(Map<String, dynamic> json) {
    return ItemLista(
      tokenBase: json['tokenBase'] ?? '',
      cantidades: List<String>.from(json['cantidades'] ?? []),
      deRecetas: List<String>.from(json['deRecetas'] ?? []),
      esManual: json['esManual'] ?? false,
      marcado: json['marcado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'tokenBase': tokenBase,
        'cantidades': cantidades,
        'deRecetas': deRecetas,
        'esManual': esManual,
        'marcado': marcado,
      };

  @override
  String toString() => 'ItemLista($tokenBase, cantidades: $cantidades, '
      'deRecetas: $deRecetas, manual: $esManual, marcado: $marcado)';
}
