import '../../../data/models/receta.dart';

/// Receta dentro de una colección: el mismo formato [Receta] del núcleo
/// más `keywords` normalizados (sin tildes, ñ→n) para el buscador
/// propio de la biblioteca.
class RecetaColeccion {
  final Receta receta;
  final List<String> keywords;

  const RecetaColeccion({required this.receta, required this.keywords});

  factory RecetaColeccion.fromJson(Map<String, dynamic> json) {
    return RecetaColeccion(
      receta: Receta.fromJson(json),
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        ...receta.toJson(),
        'keywords': keywords,
      };
}

/// Colección de recetas descargable (catálogo de la tienda).
///
/// El row de Supabase (tabla `colecciones`) es la fuente de verdad; el
/// mismo formato lo usa el cache local (SharedPreferences), por eso hay
/// un único [Coleccion.fromJson]/[toJson] para red y cache.
class Coleccion {
  final String id;
  final String nombre;
  final String descripcion;
  final String icono; // nombre de ícono TablerIcons
  final String color; // familia visual: 'verde' | 'gris'
  final bool activa;
  final int orden;
  final int version;
  final String? imagen; // portada de la colección (asset local, ej: assets/images/recetas/portada_jugos.webp)
  final bool gratis; // colección gratuita (sin pack IAP): acceso abierto
  final List<RecetaColeccion> recetas;

  const Coleccion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.activa,
    required this.orden,
    required this.version,
    this.imagen,
    this.gratis = false,
    required this.recetas,
  });

  factory Coleccion.fromJson(Map<String, dynamic> json) {
    return Coleccion(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      icono: json['icono'] ?? 'leaf',
      color: json['color'] ?? 'verde',
      activa: json['activa'] ?? true,
      orden: json['orden'] ?? 0,
      version: json['version'] ?? 1,
      imagen: json['imagen'],
      gratis: json['gratis'] ?? false,
      recetas: [
        for (final receta in json['recetas'] ?? const [])
          RecetaColeccion.fromJson(
            Map<String, dynamic>.from(receta as Map),
          ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'icono': icono,
        'color': color,
        'activa': activa,
        'orden': orden,
        'version': version,
        'imagen': imagen,
        'gratis': gratis,
        'recetas': [for (final r in recetas) r.toJson()],
      };

  /// Receta por id dentro de la colección (null si no existe).
  RecetaColeccion? recetaPorId(String recetaId) {
    for (final r in recetas) {
      if (r.receta.id == recetaId) return r;
    }
    return null;
  }

  @override
  String toString() => 'Coleccion(id: $id, nombre: $nombre, '
      'recetas: ${recetas.length})';
}
