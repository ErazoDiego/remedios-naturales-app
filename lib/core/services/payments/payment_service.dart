import '../../constants/app_constants.dart';

/// Planes de membresía (desbloquean TODO: sistemas + colecciones,
/// presentes y futuras, y quitan anuncios).
enum MembresiaPlan {
  mensual(AppConstants.mensualProductId, AppConstants.mensualDuracion),
  anual(AppConstants.anualProductId, AppConstants.anualDuracion);

  const MembresiaPlan(this.productId, this.duracion);

  /// ID del producto en la tienda (Play Console / mock).
  final String productId;

  /// Duración de la membresía desde la compra.
  final Duration duracion;
}

/// Contrato del servicio de pagos (Google Play Billing).
///
/// La UI y los providers NO conocen la implementación concreta: dependen
/// de esta interfaz. Así, en desarrollo y tests se usa [MockPaymentService]
/// (flujo completo de premium, sin plataforma de pago real) y en release
/// [GooglePlayPaymentService] (in_app_purchase nativo).
///
/// Modelo de acceso (regla de producto 2026-08-15):
/// - Membresía: mensual/anual, desbloquea TODO mientras esté vigente
///   ([premiumUntil] > now).
/// - Lifetime: compra permanente ([isLifetime]).
/// - Packs: compra individual PARA SIEMPRE de un sistema o colección.
///   No se pierden al vencer la membresía.
/// - `isPremium` es DERIVADO: `isLifetime || premiumUntil > now`.
abstract class PaymentService {
  /// Sincroniza el estado de compras previas (restore implícito).
  /// Devuelve true si el usuario tiene acceso total activo (premium).
  Future<bool> init();

  /// Inicia la compra de LIFETIME (compra permanente no consumible).
  /// Devuelve true solo si el pago se completó y confirmó.
  Future<bool> purchaseLifetime();

  /// Contrata una membresía (mensual/anual, no consumible).
  /// Devuelve la fecha de vencimiento (premiumUntil) si el pago se
  /// completó, o null si se canceló/falló.
  Future<DateTime?> purchaseSubscription(MembresiaPlan plan);

  /// Inicia la compra del pack de un sistema o colección (ej: 'digestivo'
  /// o 'coleccion-id'). El producto IAP es [AppConstants.packProductId]
  /// (no consumible). Devuelve true solo si el pago se completó.
  Future<bool> purchasePack(String sistemaId);

  /// Consulta los precios de los productos en la tienda.
  ///
  /// - Sin [productIds]: los productos conocidos (membresías + lifetime +
  ///   packs de todos los sistemas).
  /// - Con [productIds]: solo esos (lo usa la tienda de colecciones,
  ///   cuyos packs se conocen recién al leer el catálogo).
  ///
  /// Devuelve Map de productId a precio formateado, LISTO PARA MOSTRAR
  /// (ej: 'USD 4.99'). Vacío si la tienda no tiene configurado nada.
  Future<Map<String, String>> getProducts({List<String>? productIds});

  /// Restaura compras previas (reinstalación / nuevo dispositivo).
  /// Devuelve true si hay acceso total activo tras la restauración.
  Future<bool> restorePurchases();

  /// ¿Lifetime comprado? (fuente de verdad del pago, en memoria)
  bool get isLifetime;

  /// Vencimiento de la membresía activa (null si no hay).
  DateTime? get premiumUntil;

  /// ¿Acceso total activo? DERIVADO: lifetime o membresía vigente.
  bool get isPremium;

  /// Packs comprados en este dispositivo (fuente de verdad del pago).
  /// Ej: {'yuyo_pack_digestivo', 'yuyo_pack_urinario'}.
  Set<String> get purchasedPacks;

  /// ID del producto lifetime en la tienda (compra permanente).
  static const String lifetimeProductId = AppConstants.lifetimeProductId;
}
