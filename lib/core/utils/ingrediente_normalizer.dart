import 'text_normalizer.dart';

/// Normalización de ingredientes para la LISTA DE COMPRAS.
///
/// Problema que resuelve: los ingredientes del catálogo (y los que escribe
/// el usuario a mano) son `List<String>` libres — "1 taza de agua" y
/// "500 ml de agua" y "1 litro de agua" son el MISMO ingrediente con
/// cantidades distintas. La deduplicación por igualdad de string es
/// imposible: se necesita una LLAVE de agrupación (token base).
///
/// REGLA DE ORO: esta función genera SOLO la llave (agrupar/deduplicar).
/// NUNCA toca el dato real: la cantidad original ("12 huevos") se conserva
/// intacta en `cantidades[]` del ítem de la lista, se muestra y se
/// exporta tal cual. El normalizador no "pierde" nada.
///
/// Qué quita:
///  - Contenido entre paréntesis (y paréntesis colgantes: "250 ml de
///    alcohol (mínimo" quedó truncado en el parseo del libro).
///  - Sufijos de cantidad relativa: "al gusto", "c/n".
///  - Prefijos cantidad + unidad de medida + preposición, en CUALQUIER
///    posición: "1 taza de", "½ cucharadita de", "250 ml de", "jugo de
///    1 limón", "3 a 4 gotas de", "unas gotas de", "un trocito de".
///
/// La lista de unidades removibles es SOLO de unidades de medida reales
/// (taza, ml, cucharada...). NUNCA sustantivos (paño, frasco, cebolla):
/// "1 paño limpio" → "paño limpio" (no "limpio"), "1 cebolla mediana" →
/// "cebolla mediana", "1 frasco de vidrio" → "frasco de vidrio".
String normalizarIngrediente(String ingrediente) {
  var t = normalizarTexto(ingrediente);

  // Contenido entre paréntesis: "(opcional)", "(conservante natural)"...
  t = t.replaceAll(RegExp(r'\([^)]*\)'), ' ');
  // Paréntesis colgante sin cierre (dato real del libro): "(mínimo
  t = t.replaceAll(RegExp(r'\(.*$'), ' ');

  // Sufijos de cantidad relativa.
  t = t.replaceAll(RegExp(r'\b(al gusto|c/n)\b'), ' ');

  // Prefijos cantidad [+ unidad de medida] [+ preposición], en cualquier
  // posición. Cubre números enteros/decim./fracciones, fracciones unicode
  // (½ ¼ ¾), palabras ("una", "media") y rangos ("3 a 4", "2 a 3").
  t = t.replaceAll(_cantidadRegex, ' ');

  // Colapso de espacios.
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Fallback: si quedó vacío (p.ej. ingrediente "1 taza"), el dato
  // original normalizado es la llave — nunca perdemos el ítem.
  return t.isEmpty ? normalizarTexto(ingrediente) : t;
}

final RegExp _cantidadRegex = RegExp(
  // Cantidad: números (enteros, decimales, fracciones, rangos "3 a 4")
  // o palabras ("una", "media"). La fracción con slash va PRIMERO:
  // si no, "1/2" captura solo el "1" y deja "/2" residual.
  r'(?:\d+\s*/\s*\d+|'
  r'\d+([.,]\d+)?(\s*(?:a|al|-)\s*\d+)?|'
  r'½|¼|¾|\b(?:un|una|unos|unas|medio|media)\b)'
  // Unidad de medida OPCIONAL — SOLO unidades reales, nunca sustantivos
  // ("paño", "frasco", "cebolla" no están: "1 paño limpio" → "paño limpio").
  r'(?:\s*(?:tazas?|vasos?|copas?|cucharadas?|cucharaditas?|gotas?|'
  r'pizcas?|litros?|ml|cc|gr?|k?g|mg|dientes?|ramitas?|ramas?|vainas?|'
  r'rodajas?|rebanadas?|trozo|trozos|trocito|trocitos|chorrito|chorritos|'
  r'punados?|hojas?|tallos?|flores?|cascaras?|pieles?|cucharones?)'
  // Adjetivo OPCIONAL que acompaña a la unidad ("1 trocito pequeño de",
  // "1 rodaja fina de"). Va PEGADO a la unidad: si no hay unidad, el
  // adjetivo se conserva ("1 cebolla mediana" → "cebolla mediana").
  // Sin tildes ni ñ: la entrada ya pasó por normalizarTexto.
  r'(?:\s*(?:pequen[oa]s?|median[oa]s?|grandes?|fina?s?|grues[oa]s?|'
  r'limpia?s?|oscuras?|frias?|tibia?s?|seca?s?|frescas?|picada?s?|'
  r'rallada?s?|molidas?|enteras?|verdes?|maduras?|suaves?))?'
  // Preposición que une unidad e ingrediente: "de", "de la", "de las".
  // El cierre final `)?` cierra el grupo externo de la unidad (el
  // adjetivo queda DENTRO: sin unidad no hay adjetivo).
  r'(?:\s*de\s+(?:la\s+|las\s+|los\s+)?)?)?',
  caseSensitive: false,
);
