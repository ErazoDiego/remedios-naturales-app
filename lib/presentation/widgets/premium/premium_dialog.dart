import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/payments/premium_rules.dart';
import '../../providers/premium_provider.dart';

/// Modal que aparece al tocar una función bloqueada por el plan FREE.
///
/// CTA principal: lleva a la pantalla de compra de premium.
/// Si viene [sistemaId], ofrece además comprar el pack de ese sistema
/// (desbloquea todas sus recetas sin pagar premium completo).
/// Si viene [recipeId] y la receta es elegible, ofrece desbloquear SOLO
/// esa receta durante 24 h viendo 2 anuncios rewarded.
Future<void> showPremiumDialog(
  BuildContext context, {
  String? title,
  String? message,
  String? sistemaId,
  String? recipeId,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final premium = context.read<PremiumProvider>();
      final ofreceUnlock = recipeId != null &&
          premium.rewardedDisponible &&
          premium.esElegibleParaUnlockPorAnuncio(recipeId);

      return AlertDialog(
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
          if (ofreceUnlock)
            TextButton.icon(
              onPressed: () async {
                final resultado =
                    await desbloquearRecetaConAnuncios(context, premium, recipeId);
                if (!context.mounted) return;
                // Acá SÍ hay un diálogo arriba: al otorgar acceso se cierra
                // para que se vea la receta recién desbloqueada.
                if (resultado == UnlockResult.exito) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('Mirar 2 anuncios · 24 h'),
            ),
          if (sistemaId != null)
            Builder(
              builder: (context) {
                final packId = PremiumRules.packIdDeSistema(sistemaId);
                final precio = premium.priceFor(packId);
                return FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    premium.purchasePack(sistemaId);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.alertAmberBackground,
                    foregroundColor: AppConstants.alertAmber,
                  ),
                  child: Text(
                    precio == null
                        ? 'Desbloquear sistema'
                        : 'Desbloquear sistema · $precio',
                  ),
                );
              },
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
      );
    },
  );
}

/// Ejecuta el flujo completo: disclosure antes de CADA anuncio, sin
/// recompensa parcial, y feedback acorde al resultado.
///
/// Público para reutilizarlo en muros inline (ej: `_buildPremiumWall` de
/// `remedy_detail_screen.dart`), donde no hay un `showPremiumDialog` arriba.
/// Devuelve el resultado: es el CALLER el que decide si cierra su diálogo.
Future<UnlockResult> desbloquearRecetaConAnuncios(
  BuildContext context,
  PremiumProvider premium,
  String recipeId,
) async {
  debugPrint('rewarded_unlock start recipeId=$recipeId');
  final resultado = await premium.desbloquearConAnuncios(
    recipeId,
    onConfirmAd: (adNumber, total) =>
        _confirmarAnuncio(context, adNumber, total),
    onProgress: (adNumber, total) =>
        debugPrint('rewarded_unlock ad=$adNumber/$total recipeId=$recipeId'),
  );
  debugPrint(
    'rewarded_unlock result=$resultado recipeId=$recipeId '
    'unlocksActivos=${premium.unlocksTemporalesActivos.length}',
  );
  if (!context.mounted) return resultado;

  final messenger = ScaffoldMessenger.of(context);
  switch (resultado) {
    case UnlockResult.exito:
      messenger.showSnackBar(
        const SnackBar(content: Text('Receta desbloqueada por 24 h')),
      );
      break;
    case UnlockResult.limiteAlcanzado:
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Ya tenés 3 recetas desbloqueadas. Esperá a que venza '
            'una o elegí un pack.',
          ),
        ),
      );
      break;
    case UnlockResult.cancelado:
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No se completaron los anuncios; la receta sigue bloqueada.',
          ),
        ),
      );
      break;
    case UnlockResult.noDisponible:
      break;
  }
  return resultado;
}

/// Aviso explícito antes de cada anuncio (cumple la política de AdMob):
/// es opt-in, se puede cancelar y la recompensa se entrega al finalizar.
Future<bool> _confirmarAnuncio(
  BuildContext context,
  int adNumber,
  int total,
) async {
  final confirmado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(
        Icons.play_circle_outline,
        size: 34,
        color: AppConstants.alertAmber,
      ),
      title: Text('Anuncio $adNumber de $total'),
      content: const Text(
        'Vas a mirar un anuncio para desbloquear esta receta durante 24 h. '
        'La recompensa se entrega recién cuando termina el anuncio. '
        'Si cancelás, no se desbloquea nada.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('Ver anuncio $adNumber de $total'),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
