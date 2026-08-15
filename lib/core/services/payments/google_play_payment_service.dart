import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../constants/app_constants.dart';
import 'payment_service.dart';

/// Implementación real de [PaymentService] con Google Play Billing
/// (plugin `in_app_purchase` nativo, sin RevenueCat).
///
/// Los productos deben existir en Play Console:
/// - `yuyo_mensual` / `yuyo_anual` (suscripciones)
/// - `yuyo_lifetime` (no consumible)
/// - `yuyo_pack_<sistema>` / `yuyo_pack_<coleccion>` (no consumibles)
/// Sin Play Console, `queryProductDetails` devuelve vacío y la compra
/// devuelve false (la UI muestra "no disponible").
///
/// Fuente de verdad del pago = el Google account del dispositivo
/// (queryPastPurchases / purchaseStream); la persistencia en Supabase
/// la maneja el PremiumProvider/UserService para restore multi-dispositivo.
class GooglePlayPaymentService implements PaymentService {
  GooglePlayPaymentService({InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance {
    _listenToPurchases();
  }

  final InAppPurchase _iap;

  bool _isLifetime = false;
  DateTime? _premiumUntil;
  final Set<String> _purchasedPacks = {};
  Completer<DateTime?>? _pendingSubscription;
  Completer<bool>? _pendingPurchase;
  String? _pendingProductId;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  /// Platform addition solo disponible en Android (los productos de
  /// Yuyo son de Google Play; iOS queda fuera del scope del MVP).
  InAppPurchaseAndroidPlatformAddition get _androidAddition => _iap
      .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

  @override
  bool get isLifetime => _isLifetime;

  @override
  DateTime? get premiumUntil => _premiumUntil;

  @override
  bool get isPremium =>
      _isLifetime || (_premiumUntil != null && _premiumUntil!.isAfter(DateTime.now()));

  @override
  Set<String> get purchasedPacks => Set.unmodifiable(_purchasedPacks);

  @override
  Future<bool> init() async {
    try {
      // En v3 el plugin maneja las compras pendientes automáticamente.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final response = await _androidAddition.queryPastPurchases();
        for (final purchase in response.pastPurchases) {
          if (_isOwned(purchase)) {
            _registerPurchase(purchase);
          }
        }
      }
    } catch (_) {
      // Sin Play Store / sin conexión: mantener el estado actual
    }
    return isPremium;
  }

  @override
  Future<bool> purchaseLifetime() => _buy(PaymentService.lifetimeProductId);

  @override
  Future<DateTime?> purchaseSubscription(MembresiaPlan plan) =>
      _buySubscription(plan);

  @override
  Future<bool> purchasePack(String sistemaId) =>
      _buy(AppConstants.packProductId(sistemaId));

  @override
  Future<Map<String, String>> getProducts({List<String>? productIds}) async {
    final ids = (productIds ?? _productosConocidos()).toSet();
    if (ids.isEmpty) return {};

    try {
      final response = await _iap.queryProductDetails(ids);
      return {
        for (final product in response.productDetails)
          product.id: product.price,
      };
    } catch (_) {
      return {}; // sin Play Store / sin conexión: la UI no muestra precios
    }
  }

  /// IDs conocidos por la app: membresías + lifetime + pack de cada sistema.
  List<String> _productosConocidos() => [
        AppConstants.mensualProductId,
        AppConstants.anualProductId,
        PaymentService.lifetimeProductId,
        for (final sistemaId in AppConstants.sistemasIds)
          AppConstants.packProductId(sistemaId),
      ];

  /// Compra un producto no consumible (lifetime o pack). Devuelve true
  /// si el pago se completó y confirmó.
  Future<bool> _buy(String productId) async {
    if (_pendingPurchase != null) return false; // ya hay una compra en curso

    final ProductDetailsResponse response;
    try {
      response = await _iap.queryProductDetails({productId});
    } catch (_) {
      return false;
    }
    if (response.productDetails.isEmpty) {
      return false; // producto no configurado en Play Console
    }

    final completer = Completer<bool>();
    _pendingPurchase = completer;
    _pendingProductId = productId;

    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: response.productDetails.first,
        ),
      );
    } catch (_) {
      _pendingPurchase = null;
      _pendingProductId = null;
      return false;
    }

    // El resultado real llega por purchaseStream; esperamos hasta 3 min.
    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        _pendingPurchase = null;
        _pendingProductId = null;
        return false;
      },
    );
  }

  /// Compra una membresía (suscripción). Devuelve el vencimiento
  /// calculado del período (la expiración real la reporta Google en el
  /// purchaseStream / queryPastPurchases, vía expiryTimeMillis).
  Future<DateTime?> _buySubscription(MembresiaPlan plan) async {
    if (_pendingPurchase != null) return null; // ya hay una compra en curso

    final ProductDetailsResponse response;
    try {
      response = await _iap.queryProductDetails({plan.productId});
    } catch (_) {
      return null;
    }
    if (response.productDetails.isEmpty) {
      return null; // suscripción no configurada en Play Console
    }

    final completer = Completer<DateTime?>();
    _pendingSubscription = completer;
    _pendingPurchase = null;
    _pendingProductId = plan.productId;

    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: response.productDetails.first,
        ),
      );
    } catch (_) {
      _pendingSubscription = null;
      _pendingProductId = null;
      return null;
    }

    // El vencimiento real llega por purchaseStream (expiryTimeMillis del
    // Purchase de BillingClient); esperamos hasta 3 min.
    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        _pendingSubscription = null;
        _pendingProductId = null;
        return null;
      },
    );
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      final response = await _androidAddition.queryPastPurchases();
      var restored = false;
      for (final purchase in response.pastPurchases) {
        if (_isOwned(purchase)) {
          _registerPurchase(purchase);
          restored = true;
        }
      }
      return restored;
    } catch (_) {
      return isPremium;
    }
  }

  // ── Internos ────────────────────────────────────────────────────────

  bool _isOwned(PurchaseDetails purchase) =>
      purchase.status == PurchaseStatus.purchased ||
      purchase.status == PurchaseStatus.restored;

  /// Registra una compra válida: lifetime, membresía o pack según el
  /// productID. Las suscripciones se registran con su vencimiento real
  /// (expiryTimeMillis) reportado por BillingClient.
  void _registerPurchase(PurchaseDetails purchase) {
    final productId = purchase.productID;
    if (productId == PaymentService.lifetimeProductId) {
      _isLifetime = true;
    } else if (productId == AppConstants.mensualProductId ||
        productId == AppConstants.anualProductId) {
      final expiry = _expiryFromPurchase(purchase);
      if (expiry != null &&
          (_premiumUntil == null || expiry.isAfter(_premiumUntil!))) {
        _premiumUntil = expiry;
      }
    } else {
      _purchasedPacks.add(productId);
    }
    _acknowledge(purchase);
  }

  /// Expiración de una suscripción desde el JSON crudo del Purchase de
  /// BillingClient (`expiryTimeMillis`). Null para productos IAP o si el
  /// JSON no lo trae (la compra acaba de hacerse y Google aún no reporta
  /// el vencimiento: se calcula del período comprado).
  DateTime? _expiryFromPurchase(PurchaseDetails purchase) {
    final json = _originalJsonOf(purchase);
    final expiryMillis = json?['expiryTimeMillis'];
    if (expiryMillis is int && expiryMillis > 0) {
      return DateTime.fromMillisecondsSinceEpoch(expiryMillis);
    }
    return null;
  }

  /// Original JSON del Purchase de BillingClient (Android). El wrapper
  /// del plugin lo expone en `billingClientPurchase.originalJson`.
  Map<String, dynamic>? _originalJsonOf(PurchaseDetails purchase) {
    final androidPurchase = _androidPurchaseOf(purchase);
    final json = androidPurchase?.billingClientPurchase.originalJson;
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Accede al detalle Android (si la compra es de esta plataforma) para
  /// leer campos que el wrapper genérico no expone (expiryTimeMillis,
  /// isAutoRenewing) desde `billingClientPurchase.originalJson`.
  GooglePlayPurchaseDetails? _androidPurchaseOf(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      return purchase;
    }
    return null;
  }

  void _acknowledge(PurchaseDetails purchase) {
    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
  }

  void _listenToPurchases() {
    // En v3 el stream emite listas (un batch por evento).
    _purchaseSub = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          _registerPurchase(purchase);
          // Completamos el pending correspondiente a ESTE producto.
          final productId = purchase.productID;
          final esSuscripcion = productId == AppConstants.mensualProductId ||
              productId == AppConstants.anualProductId;
          if (esSuscripcion && _pendingSubscription != null) {
            _pendingSubscription!.complete(_premiumUntil);
            _pendingSubscription = null;
            _pendingProductId = null;
          } else if (!esSuscripcion &&
              _pendingPurchase != null &&
              productId == _pendingProductId) {
            _pendingPurchase!.complete(true);
            _pendingPurchase = null;
            _pendingProductId = null;
          }
        } else if (purchase.status == PurchaseStatus.error ||
            purchase.status == PurchaseStatus.canceled) {
          _pendingPurchase?.complete(false);
          _pendingPurchase = null;
          _pendingSubscription?.complete(null);
          _pendingSubscription = null;
          _pendingProductId = null;
        }
        // PurchaseStatus.pending: el usuario debe completar el pago;
        // no cancelamos el Completer — espera el desenlace.
      }
    });
  }

  void dispose() {
    _purchaseSub?.cancel();
  }
}
