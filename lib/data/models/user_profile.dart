/// Modelo de datos para el perfil de usuario
class UserProfile {
  final String id;
  final String email;
  final String nombre;
  final DateTime fechaRegistro;
  final List<String> favoritos;
  final List<String> historial;

  /// Compra lifetime (compra permanente): desbloquea todo para siempre,
  /// sin vencimiento. Reemplazó al viejo flag `premium` (compra única).
  final bool lifetime;

  /// Vencimiento de la suscripción activa (mensual/anual). Null si no
  /// hay suscripción vigente. El acceso premium se DERIVA:
  /// `lifetime || premiumUntil > now`.
  final DateTime? premiumUntil;

  /// IDs de packs comprados (ej: 'yuyo_pack_digestivo', 'yuyo_pack_jugos').
  /// Las compras individuales son PARA SIEMPRE: sobreviven al vencimiento
  /// de cualquier suscripción (regla de producto).
  final List<String> packs;

  UserProfile({
    required this.id,
    required this.email,
    required this.nombre,
    required this.fechaRegistro,
    this.favoritos = const [],
    this.historial = const [],
    this.lifetime = false,
    this.premiumUntil,
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
      lifetime: json['lifetime'] ?? false,
      premiumUntil: json['premiumUntil'] != null
          ? DateTime.tryParse(json['premiumUntil'].toString())
          : null,
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
      'lifetime': lifetime,
      'premiumUntil': premiumUntil?.toIso8601String(),
      'packs': packs,
    };
  }

  /// Sentinel para distinguir "no tocar el campo" de "limpiar a null"
  /// en [copyWith] (el clásico problema de `field ?? this.field`).
  static const Object _noTocar = Object();

  UserProfile copyWith({
    String? nombre,
    List<String>? favoritos,
    List<String>? historial,
    bool? lifetime,
    Object? premiumUntil = _noTocar,
    List<String>? packs,
  }) {
    return UserProfile(
      id: id,
      email: email,
      nombre: nombre ?? this.nombre,
      fechaRegistro: fechaRegistro,
      favoritos: favoritos ?? this.favoritos,
      historial: historial ?? this.historial,
      lifetime: lifetime ?? this.lifetime,
      premiumUntil: identical(premiumUntil, _noTocar)
          ? this.premiumUntil
          : premiumUntil as DateTime?,
      packs: packs ?? this.packs,
    );
  }

  @override
  String toString() => 'UserProfile(id: $id, email: $email, nombre: $nombre)';
}
