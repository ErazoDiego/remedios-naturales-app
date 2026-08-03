/// Modelo de datos para una hierba medicinal del herbolario
class Hierba {
  final String id;
  final String nombre;
  final String propiedades;
  final List<String> tags;

  const Hierba({
    required this.id,
    required this.nombre,
    required this.propiedades,
    required this.tags,
  });

  factory Hierba.fromJson(Map<String, dynamic> json) {
    return Hierba(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      propiedades: json['propiedades'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'propiedades': propiedades,
      'tags': tags,
    };
  }

  @override
  String toString() => 'Hierba(id: $id, nombre: $nombre)';
}
