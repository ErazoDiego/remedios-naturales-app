/// Modelo de una receta creada por el usuario (feature premium).
///
/// Espejo de la tabla `recetas_usuario` de Supabase. Los campos van en
/// camelCase en Dart y se mapean a snake_case en la DB (PostgREST).
class RecetaUsuario {
  final String id;
  final String usuarioId;
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
  final DateTime? creadoAt;
  final DateTime? actualizadoAt;

  RecetaUsuario({
    this.id = '',
    this.usuarioId = '',
    required this.nombre,
    this.descripcion = '',
    this.idealPara = const [],
    this.tipo = '',
    this.tipoPreparacion = '',
    this.cuandoUsar,
    this.precaucion = '',
    this.ingredientes = const [],
    this.preparacion = const [],
    this.dosis = '',
    this.almacenamiento = '',
    this.imagen,
    this.imagenPlaceholder,
    this.creadoAt,
    this.actualizadoAt,
  });

  factory RecetaUsuario.fromJson(Map<String, dynamic> json) {
    return RecetaUsuario(
      id: json['id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      idealPara: List<String>.from(json['ideal_para'] ?? []),
      tipo: json['tipo'] ?? '',
      tipoPreparacion: json['tipo_preparacion'] ?? '',
      cuandoUsar: json['cuando_usar'],
      precaucion: json['precaucion'] ?? '',
      ingredientes: List<String>.from(json['ingredientes'] ?? []),
      preparacion: List<String>.from(json['preparacion'] ?? []),
      dosis: json['dosis'] ?? '',
      almacenamiento: json['almacenamiento'] ?? '',
      imagen: json['imagen'],
      imagenPlaceholder: json['imagen_placeholder'],
      creadoAt: json['creado_at'] != null
          ? DateTime.parse(json['creado_at'].toString())
          : null,
      actualizadoAt: json['actualizado_at'] != null
          ? DateTime.parse(json['actualizado_at'].toString())
          : null,
    );
  }

  /// Serialización para insert/update en Supabase.
  /// Excluye `id`/`usuario_id`/`creado_at`/`actualizado_at`: la DB los
  /// genera y las políticas RLS validan el dueño (auth.uid()).
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'ideal_para': idealPara,
      'tipo': tipo,
      'tipo_preparacion': tipoPreparacion,
      'cuando_usar': cuandoUsar,
      'precaucion': precaucion,
      'ingredientes': ingredientes,
      'preparacion': preparacion,
      'dosis': dosis,
      'almacenamiento': almacenamiento,
      'imagen': imagen,
      'imagen_placeholder': imagenPlaceholder,
    };
  }

  RecetaUsuario copyWith({
    String? id,
    String? usuarioId,
    String? nombre,
    String? descripcion,
    List<String>? idealPara,
    String? tipo,
    String? tipoPreparacion,
    String? cuandoUsar,
    String? precaucion,
    List<String>? ingredientes,
    List<String>? preparacion,
    String? dosis,
    String? almacenamiento,
    String? imagen,
    String? imagenPlaceholder,
    DateTime? creadoAt,
    DateTime? actualizadoAt,
  }) {
    return RecetaUsuario(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      idealPara: idealPara ?? this.idealPara,
      tipo: tipo ?? this.tipo,
      tipoPreparacion: tipoPreparacion ?? this.tipoPreparacion,
      cuandoUsar: cuandoUsar ?? this.cuandoUsar,
      precaucion: precaucion ?? this.precaucion,
      ingredientes: ingredientes ?? this.ingredientes,
      preparacion: preparacion ?? this.preparacion,
      dosis: dosis ?? this.dosis,
      almacenamiento: almacenamiento ?? this.almacenamiento,
      imagen: imagen ?? this.imagen,
      imagenPlaceholder: imagenPlaceholder ?? this.imagenPlaceholder,
      creadoAt: creadoAt ?? this.creadoAt,
      actualizadoAt: actualizadoAt ?? this.actualizadoAt,
    );
  }

  @override
  String toString() => 'RecetaUsuario(id: $id, nombre: $nombre)';
}
