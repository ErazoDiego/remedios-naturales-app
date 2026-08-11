import '../../core/utils/text_normalizer.dart';

/// Índice de búsqueda: keywords por receta + sinónimos + stopwords.
///
/// Fuentes:
/// - keywordsPorReceta: 50 recetas con la columna "Dolencia / motivo de
///   selección" del Excel `recetas_mas_buscadas_por_sistema.xlsx` (términos
///   REALES que la gente busca, elegidos por el usuario a partir del libro)
///   + lotes por sistema extraídos del libro "Remedios naturales olvidados
///   de la abuela" (vocabulario coloquial: "no puedo ir al baño", "me cae
///   pesada la comida", etc.). Lote actual: digestivo (16/16) + nervioso
///   (14/14) + respiratorio (12/12) + inmunitario (13/13) + cardiovascular
///   (12/12) + hormonal (14/14) + musculoesqueletico (16/16) + urinario
///   (12/12) + dermico (14/14) + sensorial (10/10) completos — TODAS las
///   133 recetas cubiertas.
/// - gruposSinonimos: vocabulario del libro (cefalea↔dolor de cabeza,
///   resfriado↔gripe, etc.).
///
/// Lógica pura, sin estado: testeable.
class SearchIndex {
  SearchIndex._();

  /// Keywords de búsqueda por receta (ídolos de la app: `<sistema>_NN`).
  /// Los términos vienen de la columna Dolencia/motivo del Excel, que es
  /// el lenguaje real con el que la gente busca.
  static const Map<String, List<String>> keywordsPorReceta = {
    // ── Digestivo ─────────────────────────────────────────────────────
    'digestivo_01': ['me cae pesada la comida', 'no digiero bien', 'sensacion de llenura', 'pesadez despues de comer', 'comida copiosa'],
    'digestivo_02': ['digestion lenta', 'pesadez postcomida', 'pesadez', 'comida abundante', 'indigestion'],
    'digestivo_03': ['acidez', 'acidez de estomago', 'ardor', 'reflujo', 'malestar estomacal'],
    'digestivo_04': ['dolor de panza', 'frio en el estomago', 'panza hinchada', 'compresa caliente', 'calor en la panza'],
    'digestivo_05': ['jarabe para la digestion', 'ardor de estomago', 'me quema la panza', 'acidez despues de comer', 'proteger el estomago'],
    'digestivo_06': ['no tengo hambre', 'sin apetito', 'abrir el apetito', 'espasmos intestinales', 'panza inflamada'],
    'digestivo_07': ['depurar el cuerpo', 'limpiar el organismo', 'limpieza interna', 'desintoxicar', 'depurar el higado', 'eliminar liquidos'],
    'digestivo_08': ['estoy estrenido', 'no puedo ir al bano', 'batido digestivo', 'limpiar el intestino', 'transito lento'],
    'digestivo_09': ['no tengo hambre', 'me lleno rapido', 'estimular el apetito', 'manzanilla amarga', 'sin ganas de comer'],
    'digestivo_10': ['panza dura', 'vientre inflamado', 'no me salen los gases', 'expulsar gases', 'cataplasma de menta', 'tirarme el aire'],
    'digestivo_11': ['higado', 'higado lento', 'me cae mal la grasa', 'digestion de grasas', 'comidas grasosas', 'boldo'],
    'digestivo_12': ['gases', 'colicos', 'hinchazon abdominal', 'inflamacion abdominal', 'flatulencia'],
    'digestivo_13': ['agua digestiva', 'panza inflamada', 'hinchazon de panza', 'abdomen distendido', 'vientre hinchado'],
    'digestivo_14': ['nauseas', 'nausea', 'vomito', 'malestar', 'mareos matinales'],
    'digestivo_15': ['pesadez abdominal', 'comidas copiosas', 'digestion pesada', 'gases', 'mucha comida'],
    'digestivo_16': ['para viajar', 'comer fuera de casa', 'en el trabajo', 'polvo digestivo', 'alivio rapido', 'sin preparar'],
    // ── Nervioso ──────────────────────────────────────────────────────
    'nervioso_01': ['calmar los nervios', 'dia agitado', 'desconectar', 'relajarse despues del trabajo', 'antes de dormir'],
    'nervioso_02': ['estres', 'tension nerviosa', 'antiestres', 'relajacion'],
    'nervioso_03': ['conciliar el sueno', 'sueno profundo', 'dormir mejor', 'antes de acostarse', 'miel para dormir'],
    'nervioso_04': ['falta de enfoque', 'concentracion', 'atencion', 'estudiar', 'enfoque mental'],
    'nervioso_05': ['dia de nervios', 'preocupaciones', 'bano de hierbas', 'relajarse en el bano', 'bano caliente'],
    'nervioso_06': ['despejar la mente', 'roll on', 'antes de trabajar', 'energia mental', 'concentrarse', 'aromaterapia'],
    'nervioso_07': ['valeriana', 'calma profunda', 'relajante natural', 'sin somnolencia', 'nerviosismo'],
    'nervioso_08': ['tilo', 'jarabe para dormir', 'agitacion nocturna', 'sueno natural', 'dormir tranquilo'],
    'nervioso_09': ['ashwagandha', 'adaptogeno', 'descanso reparador', 'recuperar energia', 'estres cronico', 'sin excitacion'],
    'nervioso_10': ['cefalea', 'dolor de cabeza', 'migrana', 'jaqueca', 'dolor de cabeza por tension'],
    'nervioso_11': ['insomnio', 'desvelo', 'no poder dormir', 'descansar', 'sueno'],
    'nervioso_12': ['memoria', 'estado de animo', 'desanimo', 'cacao', 'maca', 'mente cansada'],
    'nervioso_13': ['ansiedad', 'nervios', 'bano relajante', 'calmarse'],
    'nervioso_14': ['tristeza', 'serenidad', 'sobrecarga emocional', 'flores de bach', 'agua de azahar', 'bajon emocional'],
    // ── Respiratorio ──────────────────────────────────────────────────
    'respiratorio_01': ['tos', 'tos seca', 'tos productiva', 'jarabe', 'tos suave'],
    'respiratorio_02': ['vapor de eucalipto', 'abrir la nariz', 'respirar mejor', 'presion en la cabeza', 'vias respiratorias tapadas'],
    'respiratorio_03': ['gordolobo', 'bronquios', 'pulmones', 'mucosidad atrapada', 'pecho con flema', 'descongestionar el pecho'],
    'respiratorio_04': ['balsamo para el pecho', 'opresion en el pecho', 'pecho tapado', 'unguento', 'frotar el pecho'],
    'respiratorio_05': ['dolor de garganta', 'garganta irritada', 'anginas', 'gargaras'],
    'respiratorio_06': ['congestion nasal', 'nariz tapada', 'vapor', 'descongestionar', 'vias respiratorias'],
    'respiratorio_07': ['mucosidad', 'flemas', 'expectorante', 'pecho congestionado'],
    'respiratorio_08': ['spray nasal', 'nariz seca', 'resequedad', 'lavado nasal', 'alergia', 'humectar la nariz'],
    'respiratorio_09': ['jarabe de cebolla', 'cebolla y miel', 'remedio de la abuela', 'jarabe casero', 'tos nocturna'],
    'respiratorio_10': ['dolor de garganta', 'garganta', 'pastillas', 'caramelos'],
    'respiratorio_11': ['sauco', 'sudoracion', 'romper el resfriado', 'malestar general', 'resfriado comun'],
    'respiratorio_12': ['despejar la nariz', 'cabeza pesada', 'nariz congestionada', 'roll on', 'oler mejor'],
    // ── Inmunitario ───────────────────────────────────────────────────
    'inmunitario_01': ['defensas bajas', 'bajon de defensas', 'inmunidad', 'equinacea', 'sauco'],
    'inmunitario_02': ['leche dorada', 'curcuma y pimienta', 'bebida caliente', 'dias frios', 'reconfortante', 'por la noche'],
    'inmunitario_03': ['resfriado', 'primeros sintomas', 'defensas', 'gripe', 'refuerzo'],
    'inmunitario_04': ['bayas', 'frutos rojos', 'antioxidantes', 'recuperacion tras resfriado', 'despues de la gripe', 'jarabe de frutos rojos'],
    'inmunitario_05': ['fatiga', 'cansancio', 'agotamiento', 'adaptogeno', 'falta de energia'],
    'inmunitario_06': ['caldo de ajo', 'caldo de cebolla', 'sopa para el resfriado', 'estoy debil', 'recuperarse rapido'],
    'inmunitario_07': ['cambio de estacion', 'limpiar la sangre', 'depuracion de primavera', 'ortiga', 'diente de leon', 'depurar'],
    'inmunitario_08': ['prevencion', 'invierno', 'defensas', 'resfriado', 'protegerse'],
    'inmunitario_09': ['antiviral', 'virus', 'gotas de ajo', 'ajo y limon', 'combatir virus', 'defensas contra virus'],
    'inmunitario_10': ['inflamacion', 'antiinflamatorio', 'curcuma'],
    'inmunitario_11': ['balsamo protector', 'antes de salir de casa', 'ambientes cargados', 'arbol de te', 'protegerse del frio'],
    'inmunitario_12': ['astragalo', 'energia estable', 'energia sostenida', 'cansancio prolongado', 'sin estimulantes'],
    'inmunitario_13': ['propolis', 'tintura', 'microbios', 'reforzar defensas', 'prepararse para el invierno'],
    // ── Cardiovascular ────────────────────────────────────────────────
    'cardiovascular_01': ['circulacion', 'circulacion lenta', 'corazon', 'espino blanco', 'mala circulacion'],
    'cardiovascular_02': ['retencion', 'retencion de liquidos', 'canela', 'metabolismo', 'hinchazon'],
    'cardiovascular_03': ['circulacion', 'tension', 'ajo', 'limon', 'colesterol', 'presion'],
    'cardiovascular_04': ['cansancio metabolico', 'metabolismo', 'energia', 'hibisco', 'jengibre'],
    'cardiovascular_05': ['extracto de curcuma', 'proteger el corazon', 'metabolismo', 'antiinflamatorio natural', 'inflamacion del cuerpo'],
    'cardiovascular_06': ['presion alta', 'presion arterial', 'hojas de olivo', 'tension alta', 'regular la presion', 'presion natural'],
    'cardiovascular_07': ['semillas', 'energia', 'circulacion', 'chia', 'linaza'],
    'cardiovascular_08': ['batido verde', 'licuado verde', 'espinaca', 'energia por la manana', 'empezar el dia con energia'],
    'cardiovascular_09': ['ajo negro', 'ajo fermentado', 'no me gusta el ajo', 'tintura de ajo', 'colesterol'],
    'cardiovascular_10': ['piernas cansadas', 'piernas pesadas', 'masaje circulatorio', 'pies frios', 'manos frias', 'activar la circulacion'],
    'cardiovascular_11': ['cansancio mental', 'mente nublada', 'despejar la mente', 'pesadez mental', 'depurar la mente'],
    'cardiovascular_12': ['vinagre de manzana', 'miel y vinagre', 'energia al despertar', 'despertar cansado', 'en ayunas'],
    // ── Hormonal ──────────────────────────────────────────────────────
    'hormonal_01': ['sindrome premenstrual', 'spm', 'menstruacion', 'regla', 'dolores menstruales'],
    'hormonal_02': ['ciclos irregulares', 'menstruacion irregular', 'vitex', 'equilibrio hormonal'],
    'hormonal_03': ['colicos', 'dolor menstrual', 'spm', 'menstruacion', 'bano'],
    'hormonal_04': ['aceite para colicos', 'masaje abdominal', 'bajo vientre', 'panza adolorida', 'masaje con lavanda'],
    'hormonal_05': ['sofocos', 'menopausia', 'calores', 'trebol rojo'],
    'hormonal_06': ['maca', 'cacao', 'elixir de maca', 'levanta el animo', 'energia femenina', 'decaimiento'],
    'hormonal_07': ['higado', 'diente de leon', 'hinchazon premenstrual', 'periodo hinchada', 'desinflamar el abdomen', 'depurar en el ciclo'],
    'hormonal_08': ['batido de avena', 'desayuno energetico', 'levantar energia', 'energia en el ciclo', 'banana y canela'],
    'hormonal_09': ['libido', 'deseo', 'apetito sexual', 'maca'],
    'hormonal_10': ['canela y miel', 'bajon de animo', 'levantar el animo', 'dias grises', 'animarse'],
    'hormonal_11': ['postparto', 'despues del parto', 'zona intima', 'puerperio', 'calendula', 'pezon agrietado'],
    'hormonal_12': ['regular el ciclo', 'regla irregular', 'periodo irregular', 'atraso menstrual', 'angelica'],
    'hormonal_13': ['cansancio hormonal', 'agotamiento menstrual', 'regaliz', 'energia durante el ciclo', 'dias de baja energia'],
    'hormonal_14': ['calmar el ciclo', 'tension premenstrual', 'irritable con la regla', 'hinojo', 'relajar el abdomen', 'rosa'],
    // ── Músculo-esquelético ───────────────────────────────────────────
    'musculoesqueletico_01': ['arnica', 'chichon', 'me di un golpe', 'dolor despues de entrenar', 'hematomas', 'golpeado'],
    'musculoesqueletico_02': ['tension muscular', 'musculos', 'contractura', 'compresa caliente', 'jengibre'],
    'musculoesqueletico_03': ['dolor articular', 'articulaciones', 'artritis', 'dolor de huesos', 'curcuma'],
    'musculoesqueletico_04': ['sales de magnesio', 'musculos cansados', 'bano de inmersion', 'descanso profundo', 'dolor de cuerpo despues del gym'],
    'musculoesqueletico_05': ['cayena', 'crema caliente', 'rigidez al despertar', 'dolor de rodilla', 'movilidad', 'manos rigidas'],
    'musculoesqueletico_06': ['agujetas', 'musculos doloridos', 'despues del gym', 'post entrenamiento', 'sobrecarga', 'unguento deportivo'],
    'musculoesqueletico_07': ['cola de caballo', 'tendones', 'ligamentos', 'fortalecer huesos', 'silice', 'debilidad articular'],
    'musculoesqueletico_08': ['golpes', 'esguinces', 'hematomas', 'moretones', 'cataplasma'],
    'musculoesqueletico_09': ['cuerpo pesado', 'pesadez corporal', 'cuerpo agotado', 'activar el cuerpo', 'romero y limon'],
    'musculoesqueletico_10': ['musculos tensos', 'aceite para masaje', 'calor en la zona', 'relajar musculos', 'despues del ejercicio'],
    'musculoesqueletico_11': ['calcio', 'huesos debiles', 'osteoporosis', 'descalcificacion', 'huesos fuertes', 'magnesio'],
    'musculoesqueletico_12': ['inflamacion', 'antiinflamatorio', 'jarabe', 'dolor muscular'],
    'musculoesqueletico_13': ['dolor de cuello', 'cervicales', 'contractura en el cuello', 'mala postura', 'mucho tiempo en la compu', 'hombros cargados'],
    'musculoesqueletico_14': ['dolor de espalda', 'espalda cargada', 'lumbago', 'dolor lumbar', 'cintura dolorida', 'espalda tensa'],
    'musculoesqueletico_15': ['sales de bano', 'bano muscular', 'bano con hierbas', 'relajar la tension', 'bano caliente'],
    'musculoesqueletico_16': ['dolor articular', 'laurel', 'dolores', 'tension muscular'],
    // ── Urinario ──────────────────────────────────────────────────────
    'urinario_01': ['retencion de liquidos', 'diuretico', 'hinchazon', 'ortiga', 'eliminar liquidos'],
    'urinario_02': ['depurar', 'retencion', 'perejil', 'limpieza'],
    'urinario_03': ['cistitis', 'irritacion urinaria', 'infeccion de orina', 'ardor al orinar', 'cebada', 'calendula'],
    'urinario_04': ['hinojo', 'depurativa', 'digestion pesada', 'diente de leon', 'hinchazon de abdomen'],
    'urinario_05': ['colico renal', 'dolor de riñones', 'molestias lumbares', 'calor en la zona lumbar', 'cataplasma de manzanilla'],
    'urinario_06': ['sistema linfatico', 'drenar liquidos', 'linfa', 'ortiga y limon', 'drenaje'],
    'urinario_07': ['apio', 'jarabe de apio', 'menta', 'retencion de liquidos', 'hinchazon leve'],
    'urinario_08': ['malvavisco', 'molestias urinarias', 'aliviar la irritacion', 'manzanilla', 'ardor'],
    'urinario_09': ['hinchazon al final del dia', 'depurar de noche', 'relajarse antes de dormir', 'manzanilla y miel', 'pesadez nocturna'],
    'urinario_10': ['pesadez renal', 'riñones', 'gayuba', 'cola de caballo', 'infeccion urinaria'],
    'urinario_11': ['tintura de riñones', 'apoyo renal', 'diente de leon', 'acumulacion de liquidos', 'pesadez en los riñones'],
    'urinario_12': ['vejiga sensible', 'irritacion urinaria', 'infeccion de orina', 'ardor'],
    // ── Dérmico ───────────────────────────────────────────────────────
    'dermico_01': ['hamamelis', 'locion facial', 'piel sensible', 'tonificar la piel', 'rosa mosqueta'],
    'dermico_02': ['piel grasa', 'acne', 'barros', 'espinillas', 'mascarilla', 'puntos negros'],
    'dermico_03': ['irritacion', 'piel irritada', 'aloe', 'quemadura', 'picazon'],
    'dermico_04': ['serum facial', 'arrugas', 'lineas de expresion', 'jojoba', 'luminosidad'],
    'dermico_05': ['pie de atleta', 'hongos en la piel', 'arbol de te', 'hongos en los pies', 'entre los dedos', 'sudor en los pies'],
    'dermico_06': ['quemadura solar', 'sol', 'enrojecimiento', 'post solar', 'piel quemada'],
    'dermico_07': ['labios secos', 'labios partidos', 'protector labial', 'labios agrietados', 'grietas en la boca'],
    'dermico_08': ['aceite corporal', 'aceite de almendra', 'piel tirante', 'elasticidad', 'piel apagada'],
    'dermico_09': ['se me cae el pelo', 'caida del cabello', 'champu de romero', 'cabello debil', 'fortalecer el pelo'],
    'dermico_10': ['vinagre de manzana', 'enjuague de vinagre', 'pelo apagado', 'pelo sin brillo', 'acondicionador natural'],
    'dermico_11': ['pepino', 'piel irritada', 'piel caliente', 'mascarilla de pepino', 'enrojecimiento'],
    'dermico_12': ['hidratacion', 'piel seca', 'calendula', 'crema', 'suavizar'],
    'dermico_13': ['uñas debiles', 'uñas que se rompen', 'fortalecer las uñas', 'cuticulas secas', 'vitamina e'],
    'dermico_14': ['cuero cabelludo', 'te verde', 'pelo sin vida', 'frescura en el pelo', 'cabello apagado'],
    // ── Sensorial ─────────────────────────────────────────────────────
    'sensorial_01': ['eufrasia', 'ojos irritados', 'sensacion de arenilla', 'limpiar los ojos', 'ojos rojos'],
    'sensorial_02': ['ojos cansados', 'ojos hinchados', 'ojeras', 'compresa', 'refrescar ojos'],
    'sensorial_03': ['halitosis', 'mal aliento', 'aliento', 'enjuague', 'boca'],
    'sensorial_04': ['bicarbonato', 'pasta de dientes', 'blanquear dientes', 'limpiar los dientes', 'dentadura'],
    'sensorial_05': ['oil pulling', 'enjuague con aceite', 'boca seca', 'limpiar la boca', 'pesadez bucal'],
    'sensorial_06': ['oido', 'molestia en oido', 'dolor de oido', 'gotas', 'infeccion de oido'],
    'sensorial_07': ['mareo', 'vertigo', 'mareos', 'roll-on', 'vahido'],
    'sensorial_08': ['spray bucal', 'tomillo', 'mal aliento', 'aliento fresco', 'despues de comer'],
    'sensorial_09': ['hidratar labios', 'balsamo de menta', 'tirantez en los labios', 'labios resecos', 'aloe'],
    'sensorial_10': ['ojos cansados', 'fatiga visual', 'ojos', 'pantalla'],
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
