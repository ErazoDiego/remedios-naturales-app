import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

/// Diálogo de divulgación de publicidad personalizada.
///
/// Google Play exige que los usuarios sean informados de que la app
/// muestra anuncios personalizados ANTES de que se les muestren.
/// Se muestra una sola vez (al primer launch) y queda registrado en
/// SharedPreferences para no volver a mostrarlo.
class AdsDisclosureDialog {
  static const String _shownKey = 'ads_disclosure_shown';

  /// ¿Ya se mostró el aviso en esta app?
  static Future<bool> alreadyShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_shownKey) ?? false;
  }

  /// Muestra el diálogo si no se mostró antes.
  /// Llamar desde el primer frame del HomeScreen.
  static Future<void> showIfNeeded(BuildContext context) async {
    if (await alreadyShown()) return;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.info_outline,
          size: 36,
          color: AppConstants.sageGreenTitle,
        ),
        title: const Text('Publicidad en Yuyo'),
        content: const Text(
          'Yuyo muestra anuncios para mantener la app gratuita. '
          'Algunos anuncios pueden ser personalizados según tus '
          'intereses. Podés desactivar la personalización de anuncios '
          'en los ajustes de tu dispositivo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppConstants.textSecondary,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_shownKey, true);
              if (context.mounted) Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.sageGreenTitle,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
