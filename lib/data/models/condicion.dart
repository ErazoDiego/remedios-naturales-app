/// Modelo de datos para una condición/síntoma indexado
class Condicion {
  final String condicion;
  final List<String> recetasIds;

  Condicion({
    required this.condicion,
    required this.recetasIds,
  });

  factory Condicion.fromJson(Map<String, dynamic> json) {
    return Condicion(
      condicion: json['condicion'] ?? '',
      recetasIds: List<String>.from(json['recetasIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condicion': condicion,
      'recetasIds': recetasIds,
    };
  }

  @override
  String toString() => 'Condicion(condicion: $condicion, recetas: ${recetasIds.length})';
}
