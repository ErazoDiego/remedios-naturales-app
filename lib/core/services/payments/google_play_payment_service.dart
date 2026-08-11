import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../constants/app_constants.dart';
import 'payment_service.dart';

/// Implementación real de [PaymentService] con Google Play Billing
/// (plugin `in_app_purchase` nativo, sin RevenueCat).
///
/// Los productos deben existir en Play Console (`yuyo_premium` y
/// `yuyo_pack_<sistema>`, no consumibles). Sin Play Console,
/// `queryProductDetails` devuelve vacío y la compra devuelve false
/// (la UI muestra "no disponible").
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

  bool _isPremium = false;
  final Set<String> _purchasedPacks = {};
  Completer<bool>? _pendingPurchase;
  String? _pendingProductId;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  /// Platform addition solo disponible en Android (el producto premium
  /// es de Google Play; iOS queda fuera del scope del MVP).
  InAppPurchaseAndroidPlatformAddition get _androidAddition => _iap
      .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

  @override
  bool get isPremium => _isPremium;

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
    return _isPremium;
  }

  @override
  Future<bool> purchasePremium() => _buy(PaymentService.premiumProductId);

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

  /// IDs conocidos por la app: premium + pack de cada sistema.
  List<String> _productosConocidos() => [
        PaymentService.premiumProductId,
        for (final sistemaId in AppConstants.sistemasIds)
          AppConstants.packProductId(sistemaId),
      ];

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
      return _isPremium;
    }
  }

  // ── Internos ────────────────────────────────────────────────────────

  bool _isOwned(PurchaseDetails purchase) =>
      purchase.status == PurchaseStatus.purchased ||
      purchase.status == PurchaseStatus.restored;

  /// Registra una compra válida: premium o pack según el productID.
  void _registerPurchase(PurchaseDetails purchase) {
    if (purchase.productID == PaymentService.premiumProductId) {
      _isPremium = true;
    } else {
      _purchasedPacks.add(purchase.productID);
    }
    _acknowledge(purchase);
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
          // Solo completamos el pending si corresponde a ESTE producto
          // (evita completar una compra de pack con el pending de premium).
          if (_pendingPurchase != null &&
              purchase.productID == _pendingProductId) {
            _pendingPurchase!.complete(true);
            _pendingPurchase = null;
            _pendingProductId = null;
          }
        } else if (purchase.status == PurchaseStatus.error ||
            purchase.status == PurchaseStatus.canceled) {
          _pendingPurchase?.complete(false);
          _pendingPurchase = null;
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
