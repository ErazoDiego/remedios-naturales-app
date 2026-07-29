/// Modelo de datos para una receta de remedio natural
class Receta {
  final String id;
  final String nombre;
  final String descripcion;
  final List<String> idealPara;
  final String tipo;
  final String tipoPreparacion;
  final String? cuandoUsar;
  final String precaucion;
  final List<String> ingredientes;
  final List<String> preparacion;
  final String dosis;
  final String almacenamiento;
  final String? imagen;
  final String? imagenPlaceholder;

  Receta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.idealPara,
    required this.tipo,
    required this.tipoPreparacion,
    this.cuandoUsar,
    required this.precaucion,
    required this.ingredientes,
    required this.preparacion,
    required this.dosis,
    required this.almacenamiento,
    this.imagen,
    this.imagenPlaceholder,
  });

  factory Receta.fromJson(Map<String, dynamic> json) {
    return Receta(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      idealPara: List<String>.from(json['idealPara'] ?? []),
      tipo: json['tipo'] ?? '',
      tipoPreparacion: json['tipoPreparacion'] ?? '',
      cuandoUsar: json['cuandoUsar'],
      precaucion: json['precaucion'] ?? '',
      ingredientes: List<String>.from(json['ingredientes'] ?? []),
      preparacion: List<String>.from(json['preparacion'] ?? []),
      dosis: json['dosis'] ?? '',
      almacenamiento: json['almacenamiento'] ?? '',
      imagen: json['imagen'],
      imagenPlaceholder: json['imagenPlaceholder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'idealPara': idealPara,
      'tipo': tipo,
      'tipoPreparacion': tipoPreparacion,
      'cuandoUsar': cuandoUsar,
      'precaucion': precaucion,
      'ingredientes': ingredientes,
      'preparacion': preparacion,
      'dosis': dosis,
      'almacenamiento': almacenamiento,
      'imagen': imagen,
      'imagenPlaceholder': imagenPlaceholder,
    };
  }

  @override
  String toString() => 'Receta(id: $id, nombre: $nombre)';
}
