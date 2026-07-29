import 'receta.dart';

/// Modelo de datos para un sistema corporal con sus recetas
class SistemaCorporal {
  final String id;
  final String nombre;
  final String emoji;
  final int totalRecetas;
  final List<Receta> recetas;

  SistemaCorporal({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.totalRecetas,
    required this.recetas,
  });

  factory SistemaCorporal.fromJson(Map<String, dynamic> json) {
    return SistemaCorporal(
      id: json['id'] ?? '',
      nombre: json['sistema'] ?? '',
      emoji: json['emoji'] ?? '',
      totalRecetas: json['totalRecetas'] ?? 0,
      recetas: (json['recetas'] as List<dynamic>?)
              ?.map((r) => Receta.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() => 'SistemaCorporal(id: $id, nombre: $nombre, total: $totalRecetas)';
}
