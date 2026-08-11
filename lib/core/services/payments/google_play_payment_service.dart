import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'payment_service.dart';

/// Implementación real de [PaymentService] con Google Play Billing
/// (plugin `in_app_purchase` nativo, sin RevenueCat).
///
/// El producto debe existir en Play Console (`yuyo_premium`, no
/// consumible). Sin Play Console, `queryProductDetails` devuelve vacío
/// y la compra devuelve false (la UI muestra "no disponible").
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
  Completer<bool>? _pendingPurchase;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  /// Platform addition solo disponible en Android (el producto premium
  /// es de Google Play; iOS queda fuera del scope del MVP).
  InAppPurchaseAndroidPlatformAddition get _androidAddition => _iap
      .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

  @override
  bool get isPremium => _isPremium;

  @override
  Future<bool> init() async {
    try {
      // En v3 el plugin maneja las compras pendientes automáticamente.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final response = await _androidAddition.queryPastPurchases();
        for (final purchase in response.pastPurchases) {
          if (_isPremiumPurchase(purchase)) {
            _isPremium = true;
            _acknowledge(purchase);
          }
        }
      }
    } catch (_) {
      // Sin Play Store / sin conexión: mantener el estado actual
    }
    return _isPremium;
  }

  @override
  Future<bool> purchasePremium() async {
    if (_pendingPurchase != null) return false; // ya hay una compra en curso

    final ProductDetailsResponse response;
    try {
      response =
          await _iap.queryProductDetails({PaymentService.premiumProductId});
    } catch (_) {
      return false;
    }
    if (response.productDetails.isEmpty) {
      return false; // producto no configurado en Play Console
    }

    final completer = Completer<bool>();
    _pendingPurchase = completer;

    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: response.productDetails.first,
        ),
      );
    } catch (_) {
      _pendingPurchase = null;
      return false;
    }

    // El resultado real llega por purchaseStream; esperamos hasta 3 min.
    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        _pendingPurchase = null;
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
        if (_isPremiumPurchase(purchase)) {
          _isPremium = true;
          restored = true;
          _acknowledge(purchase);
        }
      }
      return restored;
    } catch (_) {
      return _isPremium;
    }
  }

  // ── Internos ────────────────────────────────────────────────────────

  bool _isPremiumPurchase(PurchaseDetails purchase) =>
      purchase.productID == PaymentService.premiumProductId &&
      (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored);

  void _acknowledge(PurchaseDetails purchase) {
    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
  }

  void _listenToPurchases() {
    // En v3 el stream emite listas (un batch por evento).
    _purchaseSub = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.productID != PaymentService.premiumProductId) continue;

        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          _isPremium = true;
          _acknowledge(purchase);
          _pendingPurchase?.complete(true);
        } else if (purchase.status == PurchaseStatus.error ||
            purchase.status == PurchaseStatus.canceled) {
          _pendingPurchase?.complete(false);
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
