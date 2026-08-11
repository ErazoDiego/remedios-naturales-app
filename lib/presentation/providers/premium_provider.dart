import 'package:flutter/material.dart';
import '../../data/services/user_service.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/payments/payment_service.dart';
import '../../core/services/payments/payment_service_factory.dart';

/// Provider del estado premium (compra única) para la UI.
///
/// Fuente de verdad = [PaymentService] (Google Play Billing / Mock),
/// reconciliado con el perfil persistido en Supabase/local para
/// restaurar la compra en otro dispositivo o tras reinstalar.
///
/// Al cambiar el estado, sincroniza [AdsService.setPremium] en un solo
/// lugar: si es premium, banner e intersticial se apagan.
class PremiumProvider extends ChangeNotifier {
  final PaymentService _payment;
  final UserService _userService;

  PremiumProvider({PaymentService? payment, UserService? userService})
      : _payment = payment ?? PaymentServiceFactory.create(),
        _userService = userService ?? UserService();

  bool _isPremium = false;
  bool _isLoading = false;
  String? _error;

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Inicializa: restaura compras del dispositivo + perfil persistido
  /// y sincroniza anuncios. Se llama desde main.dart.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final paymentPremium = await _payment.init();
      final profile = await _userService.getCurrentProfile();
      final profilePremium = profile?.premium ?? false;

      // OR: la compra puede estar en el dispositivo (billing/mock) o en
      // el perfil (comprada en otro dispositivo y persistida en Supabase).
      _isPremium = paymentPremium || profilePremium;

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

  /// Restaura compras previas (reinstalación / nuevo dispositivo).
  Future<bool> restorePurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final ok = await _payment.restorePurchases();
    if (ok) {
      _isPremium = true;
      AdsService.instance.setPremium(true);
      try {
        await _userService.setPremium(true);
      } catch (e) {
        debugPrint('No se pudo persistir premium: $e');
      }
    } else {
      _error = 'No se encontraron compras para restaurar';
    }

    _isLoading = false;
    notifyListeners();
    return ok;
  }
}
