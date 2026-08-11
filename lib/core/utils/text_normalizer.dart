/// Normalización de texto para búsquedas en español.
///
/// Problema que resuelve: el 90% de las búsquedas móviles no escriben
/// tildes ("estres" en vez de "estrés", "nauseas" en vez de "náuseas").
/// El `contains` crudo sobre el texto original devuelve 0 resultados
/// cuando el texto tiene tildes y la query no (o viceversa).
///
/// Regla: minúsculas + sin diacríticos + ñ→n.
/// Se aplica SIEMPRE sobre query y campos por igual.
String normalizarTexto(String texto) {
  var normalizado = texto.toLowerCase();
  for (final entry in _diacriticos.entries) {
    normalizado = normalizado.replaceAll(entry.key, entry.value);
  }
  return normalizado;
}

const Map<String, String> _diacriticos = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
};
