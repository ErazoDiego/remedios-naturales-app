import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';

/// Modal que aparece al tocar una función bloqueada por el plan FREE.
/// CTA: lleva a la pantalla de compra de premium.
Future<void> showPremiumDialog(
  BuildContext context, {
  String? title,
  String? message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(
        TablerIcons.crown,
        size: 36,
        color: AppConstants.alertAmber,
      ),
      title: Text(title ?? 'Yuyo Premium'),
      content: Text(
        message ??
            'Con Premium desbloqueás todas las recetas, favoritos y '
            'recetas propias ilimitados, y sin anuncios.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppConstants.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Ahora no',
            style: TextStyle(color: AppConstants.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/premium');
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppConstants.sageGreenTitle,
            foregroundColor: Colors.white,
          ),
          child: const Text('Ver Premium'),
        ),
      ],
    ),
  );
}
