import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/premium_provider.dart';

/// Modal que aparece al tocar una función bloqueada por el plan FREE.
///
/// CTA principal: lleva a la pantalla de compra de premium.
/// Si viene [sistemaId], ofrece además comprar el pack de ese sistema
/// (desbloquea todas sus recetas sin pagar premium completo).
Future<void> showPremiumDialog(
  BuildContext context, {
  String? title,
  String? message,
  String? sistemaId,
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
        if (sistemaId != null)
          FilledButton(
            onPressed: () {
              final premium = context.read<PremiumProvider>();
              Navigator.of(context).pop();
              premium.purchasePack(sistemaId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.alertAmberBackground,
              foregroundColor: AppConstants.alertAmber,
            ),
            child: const Text('Desbloquear sistema'),
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
