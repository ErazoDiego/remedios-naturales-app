/// Cómo se identifica la hierba a partir de su nombre común.
///
/// La tabla maestra del herbolario distingue entre nombres inequívocos
/// (una sola especie) y nombres que agrupan varias especies según la
/// región. Esto es clave para no afirmar una especie que no es.
enum TipoIdentificacion {
  /// Un nombre común → una especie aceptada. Ej: Achicoria → Cichorium intybus.
  especieDefinida,

  /// El nombre común agrupa varias especies. Ej: "Muña muña" designa
  /// distintas Minthostachys según la región andina.
  nombreComunMultiespecie,

  /// Variante regional de una especie. Ej: Salvia blanca (Salvia apiana)
  /// cuando el nombre comercial puede usarse para otras salvias.
  varianteRegional,

  /// Producto procesado, no planta fresca. Ej: Té verde (hojas procesadas).
  productoProcesado;

  static TipoIdentificacion fromString(String? valor) {
    switch (valor) {
      case 'nombre_comun_multiespecie':
        return TipoIdentificacion.nombreComunMultiespecie;
      case 'variante_regional':
        return TipoIdentificacion.varianteRegional;
      case 'producto_procesado':
        return TipoIdentificacion.productoProcesado;
      default:
        return TipoIdentificacion.especieDefinida;
    }
  }

  String get valorJson {
    switch (this) {
      case TipoIdentificacion.especieDefinida:
        return 'especie_definida';
      case TipoIdentificacion.nombreComunMultiespecie:
        return 'nombre_comun_multiespecie';
      case TipoIdentificacion.varianteRegional:
        return 'variante_regional';
      case TipoIdentificacion.productoProcesado:
        return 'producto_procesado';
    }
  }
}

/// Nivel de riesgo de una hierba, derivado de la tabla maestra.
///
/// Las fichas de riesgo (precaucion/critico) requieren tratamiento
/// especial en la UI (Fase B): aviso destacado, sin promoción de uso.
enum RiesgoHerba {
  /// Sin nivel de riesgo destacado en la tabla maestra.
  ninguno,

  /// Precauciones relevantes (interacciones, contraindicaciones
  /// puntuales). Ej: Hipericón, Regaliz.
  precaucion,

  /// Toxicidad grave documentada; ficha educativa de riesgo,
  /// no de preparación. Ej: Mil hombres (aristoloquia).
  critico;

  static RiesgoHerba fromString(String? valor) {
    switch (valor) {
      case 'precaucion':
        return RiesgoHerba.precaucion;
      case 'critico':
        return RiesgoHerba.critico;
      default:
        return RiesgoHerba.ninguno;
    }
  }

  String? get valorJson {
    switch (this) {
      case RiesgoHerba.ninguno:
        return null;
      case RiesgoHerba.precaucion:
        return 'precaucion';
      case RiesgoHerba.critico:
        return 'critico';
    }
  }
}

/// Modelo de datos para una hierba medicinal del herbolario.
///
/// Schema enriquecido (Fase A): además de identidad y tags, trae datos
/// botánicos, identificación taxonómica, uso tradicional (sin claims
/// terapéuticos), precauciones y nivel de riesgo.
class Hierba {
  final String id;
  final String nombre;

  /// Nombres alternativos (sinónimos populares) usados para el matcheo
  /// de recetas y la búsqueda. Ej: "Amargón (Diente de león)" → alias
  /// ["Diente de león"], así una receta con "diente de león" en
  /// ingredientes sigue matcheando aunque el nombre visible sea compuesto.
  final List<String> alias;

  /// Nombre científico aceptado (puede ser grupo de especies o
  /// referencia regional cuando el nombre común es multiespecie).
  final String? nombreCientifico;

  /// Familia botánica.
  final String? familia;

  /// Origen o distribución general relevante.
  final String? origenDistribucion;

  /// Cómo se identifica el nombre común (especie definida, multiespecie…).
  final TipoIdentificacion tipoIdentificacion;

  /// Rasgos visuales para reconocimiento educativo. No habilita
  /// recolección silvestre segura.
  final String? comoReconocerla;

  /// Parte vegetal tradicionalmente utilizada.
  final String? parteUtilizada;

  /// Uso tradicional o reconocido según fuentes revisadas. Se presenta
  /// como tradición, nunca como recomendación médica ni eficacia clínica.
  final String usoTradicional;

  /// Contraindicaciones, interacciones o advertencias relevantes.
  final String? precauciones;

  /// Etiquetas normalizadas para búsqueda/filtros (solo las visibles:
  /// sin tags internos de riesgo ni metadata).
  final List<String> tags;

  /// Nivel de riesgo derivado de la tabla maestra.
  final RiesgoHerba nivelRiesgo;

  /// Nombre de archivo de la imagen de la ficha (ej: 'achicoria.webp').
  ///
  /// Solo el nombre: el directorio de assets se resuelve en la capa de
  /// presentación cuando existan las imágenes verificadas. Hasta entonces
  /// este campo queda null en memoria o con el nombre registrado en la
  /// tabla maestra, pero NUNCA se usa para renderizar (no hay UI de
  /// imagen todavía).
  final String? imagen;

  /// URLs de fuentes institucionales (EMA, NCCIH, SIB, Kew…).
  final List<String> fuentes;

  const Hierba({
    required this.id,
    required this.nombre,
    this.alias = const [],
    this.nombreCientifico,
    this.familia,
    this.origenDistribucion,
    this.tipoIdentificacion = TipoIdentificacion.especieDefinida,
    this.comoReconocerla,
    this.parteUtilizada,
    this.usoTradicional = '',
    this.precauciones,
    this.tags = const [],
    this.nivelRiesgo = RiesgoHerba.ninguno,
    this.imagen,
    this.fuentes = const [],
  });

  factory Hierba.fromJson(Map<String, dynamic> json) {
    return Hierba(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      alias: List<String>.from(json['alias'] ?? []),
      nombreCientifico: json['nombreCientifico'] as String?,
      familia: json['familia'] as String?,
      origenDistribucion: json['origenDistribucion'] as String?,
      tipoIdentificacion:
          TipoIdentificacion.fromString(json['tipoIdentificacion'] as String?),
      comoReconocerla: json['comoReconocerla'] as String?,
      parteUtilizada: json['parteUtilizada'] as String?,
      usoTradicional: json['usoTradicional'] ?? '',
      precauciones: json['precauciones'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      nivelRiesgo: RiesgoHerba.fromString(json['nivelRiesgo'] as String?),
      imagen: json['imagen'] as String?,
      fuentes: List<String>.from(json['fuentes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'alias': alias,
      'nombreCientifico': nombreCientifico,
      'familia': familia,
      'origenDistribucion': origenDistribucion,
      'tipoIdentificacion': tipoIdentificacion.valorJson,
      'comoReconocerla': comoReconocerla,
      'parteUtilizada': parteUtilizada,
      'usoTradicional': usoTradicional,
      'precauciones': precauciones,
      'tags': tags,
      'nivelRiesgo': nivelRiesgo.valorJson,
      'imagen': imagen,
      'fuentes': fuentes,
    };
  }

  /// Título visible de la hierba: nombre + alias cuando existen.
  ///
  /// Sin alias: "Amargón". Con alias: "Amargón - Diente de león".
  /// El alias NO debe quedar oculto: el usuario que solo conoce
  /// "diente de león" vería un resultado de búsqueda que parece
  /// un error si la ficha nunca muestra esa relación.
  String get tituloVisible =>
      alias.isEmpty ? nombre : '$nombre - ${alias.join(', ')}';

  /// Texto plano con todos los campos usados por los buscadores del
  /// herbolario: nombre, alias, científico, familia, origen, rasgos,
  /// parte, uso tradicional, precauciones y tags.
  ///
  /// Reemplaza al viejo campo `propiedades` en el matcheo: la búsqueda
  /// gana alcance (matchea "Cichorium", "Asteraceae", "decocción"…)
  /// sin tener que cambiar los motores.
  String get textoBusqueda => [
        nombre,
        ...alias,
        nombreCientifico,
        familia,
        origenDistribucion,
        comoReconocerla,
        parteUtilizada,
        usoTradicional,
        precauciones,
        ...tags,
      ].whereType<String>().join(' ');

  /// Si el nombre común agrupa varias especies según la región
  /// (requiere aviso tipo "verificá la especie" en la ficha).
  bool get esMultiespecie =>
      tipoIdentificacion != TipoIdentificacion.especieDefinida;

  /// Si la ficha requiere tratamiento especial por riesgo.
  bool get tieneRiesgo => nivelRiesgo != RiesgoHerba.ninguno;

  @override
  String toString() => 'Hierba(id: $id, nombre: $nombre)';
}