import 'package:flutter/material.dart';
import '../../data/services/user_service.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/payments/payment_service.dart';
import '../../core/services/payments/payment_service_factory.dart';
import '../../core/services/payments/premium_rules.dart';

/// Provider del estado premium + packs por sistema (compras únicas).
///
/// Fuente de verdad = [PaymentService] (Google Play Billing / Mock),
/// reconciliado con el perfil persistido en Supabase/local para
/// restaurar la compra en otro dispositivo o tras reinstalar.
///
/// - Premium: OR entre pago del dispositivo y perfil (un flag).
/// - Packs: UNIÓN entre packs del dispositivo y packs del perfil
///   (cada sistema es un producto distinto).
///
/// Al cambiar el estado, sincroniza [AdsService.setPremium] en un solo
/// lugar: si es premium, banner e intersticial se apagan. Los packs NO
/// apagan anuncios (solo premium lo hace).
class PremiumProvider extends ChangeNotifier {
  final PaymentService _payment;
  final UserService _userService;

  PremiumProvider({PaymentService? payment, UserService? userService})
      : _payment = payment ?? PaymentServiceFactory.create(),
        _userService = userService ?? UserService();

  bool _isPremium = false;
  bool _isLoading = false;
  String? _error;
  final List<String> _packs = [];
  Map<String, String> _productPrices = {};

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Packs poseídos (device + perfil), ej: ['yuyo_pack_digestivo'].
  List<String> get packs => List.unmodifiable(_packs);

  /// Precios de la tienda: productId → precio formateado (ej: 'USD 4.99').
  /// Vacío si la tienda no tiene configurados los productos.
  Map<String, String> get productPrices => Map.unmodifiable(_productPrices);

  /// Precio formateado de un producto, o null si la tienda no lo tiene.
  String? priceFor(String productId) => _productPrices[productId];

  /// Precio del premium (atajo para la UI).
  String? get premiumPrice => priceFor(PaymentService.premiumProductId);

  /// Consulta precios adicionales (ej: packs de colecciones de la
  /// tienda) y los SUMA al mapa de precios existente.
  Future<void> fetchProductsFor(List<String> productIds) async {
    if (productIds.isEmpty) return;
    final nuevos = await _payment.getProducts(productIds: productIds);
    _productPrices = {..._productPrices, ...nuevos};
    notifyListeners();
  }

  /// ¿Tiene acceso a la receta? (premium, muestreo gratis o pack del sistema)
  bool puedeAccederAReceta(String recipeId) =>
      PremiumRules.puedeAccederAReceta(
        isPremium: _isPremium,
        recipeId: recipeId,
        packs: _packs,
      );

  /// Inicializa: restaura compras del dispositivo + perfil persistido
  /// y sincroniza anuncios. Se llama desde main.dart.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final paymentPremium = await _payment.init();
      final devicePacks = _payment.purchasedPacks;
      final profile = await _userService.getCurrentProfile();
      final profilePremium = profile?.premium ?? false;
      final profilePacks = profile?.packs ?? const [];

      // Premium: OR (un solo flag: la compra puede estar en cualquiera).
      _isPremium = paymentPremium || profilePremium;

      // Packs: unión (device + perfil).
      _packs
        ..clear()
        ..addAll(devicePacks)
        ..addAll(profilePacks.where((p) => !_packs.contains(p)));

      if (_isPremium) {
        AdsService.instance.setPremium(true);
        // Compra recién detectada en el dispositivo pero aún no
        // persistida: registrarla para el restore multi-dispositivo.
        if (paymentPremium && !profilePremium) {
          try {
            await _userService.setPremium(true);
          } catch (e) {
            debugPrint('No se pudo persistir premium: $e');
          }
        }
      }

      // Mismo principio para packs: lo que está en el device pero no en
      // el perfil se registra (idempotente en UserService).
      for (final packId in devicePacks) {
        if (profilePacks.contains(packId)) continue;
        try {
          await _userService.setPackOwned(packId);
        } catch (e) {
          debugPrint('No se pudo persistir pack $packId: $e');
        }
      }

      // Precios de la tienda (para mostrar en PremiumScreen y diálogos).
      _productPrices = await _payment.getProducts();
    } catch (e) {
      _error = 'Error al inicializar premium: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia la compra de premium. Devuelve true si se completó.
  Future<bool> purchasePremium() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final ok = await _payment.purchasePremium();
    if (ok) {
      _isPremium = true;
      AdsService.instance.setPremium(true);
      try {
        await _userService.setPremium(true);
      } catch (e) {
        debugPrint('No se pudo persistir premium: $e');
      }
    } else {
      _error = 'La compra se canceló o no está disponible';
    }

    _isLoading = false;
    notifyListeners();
    return ok;
  }

  /// Inicia la compra del pack de un sistema (ej: 'digestivo').
  /// Devuelve true si el pago se completó y confirmó.
  Future<bool> purchasePack(String sistemaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final ok = await _payment.purchasePack(sistemaId);
    if (ok) {
      final packId = PremiumRules.packIdDeSistema(sistemaId);
      if (!_packs.contains(packId)) {
        _packs.add(packId);
      }
      // Los packs NO apagan anuncios: solo premium lo hace.
      try {
        await _userService.setPackOwned(packId);
      } catch (e) {
        debugPrint('No se pudo persistir pack $packId: $e');
      }
    } else {
      _error = 'La compra del pack se canceló o no está disponible';
    }

    _isLoading = false;
    notifyListeners();
    return ok;
  }

  /// Restaura compras previas (reinstalación / nuevo dispositivo):
  /// premium y packs del dispositivo, persistidos al perfil.
  Future<bool> restorePurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final restoredPremium = await _payment.restorePurchases();
      final devicePacks = _payment.purchasedPacks;

      if (restoredPremium) {
        _isPremium = true;
        AdsService.instance.setPremium(true);
        try {
          await _userService.setPremium(true);
        } catch (e) {
          debugPrint('No se pudo persistir premium: $e');
        }
      }

      for (final packId in devicePacks) {
        if (_packs.contains(packId)) continue;
        _packs.add(packId);
        try {
          await _userService.setPackOwned(packId);
        } catch (e) {
          debugPrint('No se pudo persistir pack $packId: $e');
        }
      }

      if (!restoredPremium && devicePacks.isEmpty) {
        _error = 'No se encontraron compras para restaurar';
      }
      return restoredPremium || devicePacks.isNotEmpty;
    } catch (e) {
      _error = 'Error al restaurar compras: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
