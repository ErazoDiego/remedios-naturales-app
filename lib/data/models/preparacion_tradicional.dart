/// Modelo de datos para la preparación tradicional de una hierba del
/// herbolario. Vive en un JSON separado de hierbas.json porque es contenido
/// de referencia independiente (una entrada por hierba, opcional).
class PreparacionTradicional {
  /// ID de la hierba a la que pertenece (misma clave que hierbas.json)
  final String id;

  /// Parte de la planta usada (ej: "Hojas", "Raíz", "Corteza")
  final String parte;

  /// Texto de preparación — literal del herbolario tradicional
  final String texto;

  /// Modos de preparación detectados (Infusión, Decocción, Maceración,
  /// Uso externo, ...). Se muestran como etiquetas.
  final List<String> modos;

  /// Frecuencia típica de uso (ej: "Después de las comidas")
  final String dosis;

  /// Advertencia específica (embarazo, contraindicaciones, variación de
  /// especie según región...). Vacío si no aplica.
  final String advertencia;

  const PreparacionTradicional({
    required this.id,
    required this.parte,
    required this.texto,
    required this.modos,
    this.dosis = '',
    this.advertencia = '',
  });

  factory PreparacionTradicional.fromJson(Map<String, dynamic> json) {
    return PreparacionTradicional(
      id: json['id'] ?? '',
      parte: json['parte'] ?? '',
      texto: json['texto'] ?? '',
      modos: List<String>.from(json['modos'] ?? []),
      dosis: json['dosis'] ?? '',
      advertencia: json['advertencia'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parte': parte,
      'texto': texto,
      'modos': modos,
      'dosis': dosis,
      'advertencia': advertencia,
    };
  }

  @override
  String toString() => 'PreparacionTradicional(id: $id, modos: $modos)';
}