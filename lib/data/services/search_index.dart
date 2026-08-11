import '../../core/utils/text_normalizer.dart';

/// Índice de búsqueda: keywords por receta + sinónimos + stopwords.
///
/// Fuentes:
/// - keywordsPorReceta: columna "Dolencia / motivo de selección" del Excel
///   `recetas_mas_buscadas_por_sistema.xlsx` (términos REALES que la gente
///   busca, elegidos por el usuario a partir del libro).
/// - gruposSinonimos: vocabulario del libro "Remedios naturales olvidados
///   de la abuela" (cefalea↔dolor de cabeza, resfriado↔gripe, etc.).
///
/// Lógica pura, sin estado: testeable.
class SearchIndex {
  SearchIndex._();

  /// Keywords de búsqueda por receta (ídolos de la app: `<sistema>_NN`).
  /// Los términos vienen de la columna Dolencia/motivo del Excel, que es
  /// el lenguaje real con el que la gente busca.
  static const Map<String, List<String>> keywordsPorReceta = {
    // ── Digestivo ─────────────────────────────────────────────────────
    'digestivo_03': ['acidez', 'acidez de estomago', 'ardor', 'reflujo', 'malestar estomacal'],
    'digestivo_12': ['gases', 'colicos', 'hinchazon abdominal', 'inflamacion abdominal', 'flatulencia'],
    'digestivo_02': ['digestion lenta', 'pesadez postcomida', 'pesadez', 'comida abundante', 'indigestion'],
    'digestivo_15': ['pesadez abdominal', 'comidas copiosas', 'digestion pesada', 'gases', 'mucha comida'],
    'digestivo_14': ['nauseas', 'nausea', 'vomito', 'malestar', 'mareos matinales'],
    // ── Nervioso ──────────────────────────────────────────────────────
    'nervioso_13': ['ansiedad', 'nervios', 'bano relajante', 'calmarse'],
    'nervioso_11': ['insomnio', 'desvelo', 'no poder dormir', 'descansar', 'sueño'],
    'nervioso_10': ['cefalea', 'dolor de cabeza', 'migraña', 'jaqueca', 'dolor de cabeza por tension'],
    'nervioso_02': ['estres', 'tension nerviosa', 'antiestres', 'relajacion'],
    'nervioso_04': ['falta de enfoque', 'concentracion', 'atencion', 'estudiar', 'enfoque mental'],
    // ── Respiratorio ──────────────────────────────────────────────────
    'respiratorio_05': ['dolor de garganta', 'garganta irritada', 'anginas', 'gargaras'],
    'respiratorio_10': ['dolor de garganta', 'garganta', 'pastillas', 'caramelos'],
    'respiratorio_01': ['tos', 'tos seca', 'tos productiva', 'jarabe', 'tos suave'],
    'respiratorio_06': ['congestion nasal', 'nariz tapada', 'vapor', 'descongestionar', 'vias respiratorias'],
    'respiratorio_07': ['mucosidad', 'flemas', 'expectorante', 'pecho congestionado'],
    // ── Inmunitario ───────────────────────────────────────────────────
    'inmunitario_03': ['resfriado', 'primeros sintomas', 'defensas', 'gripe', 'refuerzo'],
    'inmunitario_08': ['prevencion', 'invierno', 'defensas', 'resfriado', 'protegerse'],
    'inmunitario_01': ['defensas bajas', 'bajon de defensas', 'inmunidad', 'equinacea', 'sauco'],
    'inmunitario_05': ['fatiga', 'cansancio', 'agotamiento', 'adaptogeno', 'falta de energia'],
    'inmunitario_10': ['inflamacion', 'antiinflamatorio', 'curcuma'],
    // ── Cardiovascular ────────────────────────────────────────────────
    'cardiovascular_01': ['circulacion', 'circulacion lenta', 'corazon', 'espino blanco', 'mala circulacion'],
    'cardiovascular_07': ['semillas', 'energia', 'circulacion', 'chia', 'linaza'],
    'cardiovascular_03': ['circulacion', 'tension', 'ajo', 'limon', 'colesterol', 'presion'],
    'cardiovascular_02': ['retencion', 'retencion de liquidos', 'canela', 'metabolismo', 'hinchazon'],
    'cardiovascular_04': ['cansancio metabolico', 'metabolismo', 'energia', 'hibisco', 'jengibre'],
    // ── Hormonal ──────────────────────────────────────────────────────
    'hormonal_01': ['sindrome premenstrual', 'spm', 'menstruacion', 'regla', 'dolores menstruales'],
    'hormonal_03': ['colicos', 'dolor menstrual', 'spm', 'menstruacion', 'bano'],
    'hormonal_05': ['sofocos', 'menopausia', 'calores', 'trebol rojo'],
    'hormonal_02': ['ciclos irregulares', 'menstruacion irregular', 'vitex', 'equilibrio hormonal'],
    'hormonal_09': ['libido', 'deseo', 'apetito sexual', 'maca'],
    // ── Músculo-esquelético ───────────────────────────────────────────
    'musculoesqueletico_03': ['dolor articular', 'articulaciones', 'artritis', 'dolor de huesos', 'curcuma'],
    'musculoesqueletico_16': ['dolor articular', 'laurel', 'dolores', 'tension muscular'],
    'musculoesqueletico_02': ['tension muscular', 'musculos', 'contractura', 'compresa caliente', 'jengibre'],
    'musculoesqueletico_12': ['inflamacion', 'antiinflamatorio', 'jarabe', 'dolor muscular'],
    'musculoesqueletico_08': ['golpes', 'esguinces', 'hematomas', 'moretones', 'cataplasma'],
    // ── Urinario ──────────────────────────────────────────────────────
    'urinario_03': ['cistitis', 'irritacion urinaria', 'infeccion de orina', 'ardor al orinar', 'cebada', 'calendula'],
    'urinario_12': ['vejiga sensible', 'irritacion urinaria', 'infeccion de orina', 'ardor'],
    'urinario_01': ['retencion de liquidos', 'diuretico', 'hinchazon', 'ortiga', 'eliminar liquidos'],
    'urinario_02': ['depurar', 'retencion', 'perejil', 'limpieza'],
    'urinario_10': ['pesadez renal', 'riñones', 'gayuba', 'cola de caballo', 'infeccion urinaria'],
    // ── Dérmico ───────────────────────────────────────────────────────
    'dermico_03': ['irritacion', 'piel irritada', 'aloe', 'quemadura', 'picazon'],
    'dermico_12': ['hidratacion', 'piel seca', 'calendula', 'crema', 'suavizar'],
    'dermico_02': ['piel grasa', 'acne', 'barros', 'espinillas', 'mascarilla', 'puntos negros'],
    'dermico_06': ['quemadura solar', 'sol', 'enrojecimiento', 'post solar', 'piel quemada'],
    'dermico_09': ['cabello debil', 'caida del cabello', 'champu', 'romero', 'fortalecer cabello'],
    // ── Sensorial ─────────────────────────────────────────────────────
    'sensorial_07': ['mareo', 'vertigo', 'mareos', 'roll-on', 'vahido'],
    'sensorial_03': ['halitosis', 'mal aliento', 'aliento', 'enjuague', 'boca'],
    'sensorial_02': ['ojos cansados', 'ojos hinchados', 'ojeras', 'compresa', 'refrescar ojos'],
    'sensorial_10': ['ojos cansados', 'fatiga visual', 'ojos', 'pantalla'],
    'sensorial_06': ['oido', 'molestia en oido', 'dolor de oido', 'gotas', 'infeccion de oido'],
  };

  /// Grupos de sinónimos con evidencia del libro original:
  /// ej. línea "Ideal para: cefaleas por tensión" + tabla de síntomas
  /// (Estrés leve → pasiflora, Ansiedad → baño de hierbas).
  /// Cada término expande a TODO su grupo al buscar.
  static const List<List<String>> gruposSinonimos = [
    ['dolor de cabeza', 'cefalea', 'migraña', 'jaqueca'],
    ['resfriado', 'gripe', 'catarro', 'resfrio'],
    ['acidez', 'ardor', 'reflujo'],
    ['gases', 'colicos', 'flatulencia', 'hinchazon'],
    // OJO: "tension" NO está en este grupo a propósito. Expandir
    // ansiedad/estrés con "tensión" arrastra recetas de tensión MUSCULAR
    // (falso amigo: tensión muscular ≠ tensión nerviosa). "Tensión
    // nerviosa" se cubre con las keywords de nervioso_02.
    ['estres', 'ansiedad', 'nervios'],
    ['insomnio', 'desvelo'],
    ['nauseas', 'nausea', 'vomito'],
    ['retencion', 'liquidos', 'hinchazon'],
    ['menstruacion', 'regla', 'spm'],
    ['menopausia', 'sofocos', 'calores'],
    // "jarabe" NO está: no todo jarabe es para tos (ej. jarabe
    // antiinflamatorio muscular). El término "tos" ya matchea las
    // keywords y idealPara de las recetas de tos.
    ['tos', 'tos seca', 'tos productiva'],
    ['garganta', 'anginas'],
    ['congestion', 'nariz tapada'],
    ['defensas', 'inmunidad', 'bajon'],
    ['fatiga', 'cansancio', 'agotamiento'],
    ['digestion', 'pesadez', 'indigestion'],
    ['estomago', 'malestar estomacal'],
    ['acne', 'barros', 'espinillas'],
    ['cabello', 'pelo'],
    ['mareo', 'vertigo', 'vahido'],
  ];

  static const Set<String> _stopwords = {
    'de', 'la', 'el', 'los', 'las', 'un', 'una', 'unos', 'unas',
    'para', 'con', 'sin', 'por', 'y', 'o', 'u', 'que', 'a', 'en',
    'al', 'del', 'me', 'mi', 'tu', 'su', 'te', 'se', 'lo', 'le',
    'es', 'son', 'hay', 'esta', 'estoy', 'tengo', 'mas', 'muy',
    'poco', 'como', 'cuando', 'mucho', 'todo', 'cual',
  };

  /// Descompone la query en términos: normalizados, sin tildes,
  /// sin stopwords, únicos. "Dolor de cabeza" → [dolor, cabeza].
  static List<String> terminosDe(String query) {
    final normalizada = normalizarTexto(query);
    return normalizada
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty && !_stopwords.contains(t))
        .toSet()
        .toList();
  }

  /// Expande un término normalizado a su grupo de sinónimos completo
  /// (incluye el propio término). "cefalea" → [cefalea, dolor de cabeza,
  /// migraña, jaqueca] (normalizados).
  static List<String> sinonimosDe(String termino) {
    for (final grupo in gruposSinonimos) {
      final normalizados = grupo.map(normalizarTexto).toList();
      if (normalizados.contains(termino)) return normalizados;
    }
    return [termino];
  }

  /// Keywords normalizadas de una receta (vacío si no tiene).
  static List<String> keywordsDe(String recetaId) {
    final keywords = keywordsPorReceta[recetaId] ?? const [];
    return keywords.map(normalizarTexto).toList();
  }
}
