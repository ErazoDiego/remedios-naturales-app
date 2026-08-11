/// Modelo de datos para el perfil de usuario
class UserProfile {
  final String id;
  final String email;
  final String nombre;
  final DateTime fechaRegistro;
  final List<String> favoritos;
  final List<String> historial;

  /// Usuario premium (compra única): sin anuncios, todo ilimitado.
  final bool premium;

  /// IDs de packs comprados (ej: 'jugos', 'kefir').
  final List<String> packs;

  UserProfile({
    required this.id,
    required this.email,
    required this.nombre,
    required this.fechaRegistro,
    this.favoritos = const [],
    this.historial = const [],
    this.premium = false,
    this.packs = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nombre: json['nombre'] ?? '',
      fechaRegistro: DateTime.parse(json['fechaRegistro'] ?? DateTime.now().toIso8601String()),
      favoritos: List<String>.from(json['favoritos'] ?? []),
      historial: List<String>.from(json['historial'] ?? []),
      premium: json['premium'] ?? false,
      packs: List<String>.from(json['packs'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'favoritos': favoritos,
      'historial': historial,
      'premium': premium,
      'packs': packs,
    };
  }

  UserProfile copyWith({
    String? nombre,
    List<String>? favoritos,
    List<String>? historial,
    bool? premium,
    List<String>? packs,
  }) {
    return UserProfile(
      id: id,
      email: email,
      nombre: nombre ?? this.nombre,
      fechaRegistro: fechaRegistro,
      favoritos: favoritos ?? this.favoritos,
      historial: historial ?? this.historial,
      premium: premium ?? this.premium,
      packs: packs ?? this.packs,
    );
  }

  @override
  String toString() => 'UserProfile(id: $id, email: $email, nombre: $nombre)';
}
