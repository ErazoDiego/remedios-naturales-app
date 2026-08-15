import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/payments/payment_service.dart';
import '../../../core/services/payments/premium_rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/premium_provider.dart';

/// Pantalla de Yuyo Premium: membresías (mensual/anual), lifetime y
/// packs por sistema.
///
/// Funciona con cualquier [PaymentService]: en debug compra simulada
/// (Mock), en release billing real de Google Play.
///
/// Diseño (regla de producto 2026-08-15): UN CTA prominente — el del
/// plan seleccionado (mensual/anual/lifetime). Los packs por sistema son
/// compras individuales secundarias (para siempre, no quitan anuncios).
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

/// Opciones del selector de planes. El lifetime es una opción distinta
/// (no puede representarse con `MembresiaPlan? null` porque null
/// significaría "sin selección").
enum _PlanOpcion { mensual, anual, lifetime }

class _PremiumScreenState extends State<PremiumScreen> {
  // Opción seleccionada del selector de planes. El lifetime es una
  // opción distinta (no puede representarse con MembresiaPlan? null,
  // porque null significa "sin selección").
  _PlanOpcion _planSeleccionado = _PlanOpcion.anual;

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();
    final isLoading = premium.isLoading;

    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: const Text(
          'Yuyo Premium',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ═══════════════════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.sageGreenCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.borderLight,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  TablerIcons.crown,
                  size: 48,
                  color: AppConstants.alertAmber,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Todas las recetas. Sin anuncios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Membresía o lifetime: desbloqueás todo el contenido '
                  'de Yuyo — los 10 sistemas y todas las colecciones, '
                  'presentes y futuras — sin anuncios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (premium.isPremium)
            _buildPremiumActive(context, premium)
          else ...[
            // ═══════════════════════════════════════════════════════
            // PLANES DE MEMBRESÍA + LIFETIME (selector + 1 CTA)
            // ═══════════════════════════════════════════════════════
            _buildPlanes(context, premium),

            const SizedBox(height: 12),

            _buildBeneficio(
              icon: TablerIcons.lock_open,
              color: AppConstants.sageGreenTitle,
              titulo: 'Todos los sistemas y colecciones',
              detalle: 'Acceso completo a los 10 sistemas corporales y '
                  'a cada colección nueva que lancemos.',
            ),
            _buildBeneficio(
              icon: TablerIcons.ad_off,
              color: AppConstants.alertAmber,
              titulo: 'Sin anuncios',
              detalle: 'Adiós a los banners e intersticiales.',
            ),
            _buildBeneficio(
              icon: TablerIcons.heart,
              color: AppConstants.alertRed,
              titulo: 'Favoritos ilimitados',
              detalle: 'Guardá todas las recetas que quieras.',
            ),
            _buildBeneficio(
              icon: TablerIcons.notes,
              color: AppConstants.sageGreenSubtitle,
              titulo: 'Mis recetas ilimitadas',
              detalle: 'Creá tus propias recetas sin límite.',
            ),
          ],

          const SizedBox(height: 12),

          // ═══════════════════════════════════════════════════════
          // PACKS POR SISTEMA (compras individuales, para siempre)
          // ═══════════════════════════════════════════════════════
          _buildPacksSection(premium),

          const SizedBox(height: 12),

          // Restaurar compras
          TextButton.icon(
            onPressed: isLoading ? null : () => premium.restorePurchases(),
            icon: const Icon(
              TablerIcons.refresh,
              size: 18,
              color: AppConstants.sageGreenTitle,
            ),
            label: const Text(
              'Restaurar compras',
              style: TextStyle(color: AppConstants.sageGreenTitle),
            ),
          ),
          if (premium.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                premium.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppConstants.alertRed,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PLANES
  // ═══════════════════════════════════════════════════════════════════

  /// Selector de planes (mensual/anual/lifetime) + UN botón de compra
  /// para el plan seleccionado. Respeta la regla de un solo CTA.
  Widget _buildPlanes(BuildContext context, PremiumProvider premium) {
    final isLoading = premium.isLoading;
    final plan = _planSeleccionado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Elegí tu plan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Las membresías vencen; el lifetime es para siempre.',
          style: TextStyle(
            fontSize: 12.5,
            color: AppConstants.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _buildPlanCard(
          context,
          premium,
          opcion: _PlanOpcion.mensual,
          titulo: 'Mensual',
          detalle: 'Todo por 30 días',
          icon: TablerIcons.calendar,
        ),
        _buildPlanCard(
          context,
          premium,
          opcion: _PlanOpcion.anual,
          titulo: 'Anual',
          detalle: 'Todo por un año · mejor valor',
          icon: TablerIcons.calendar,
          destacado: true,
        ),
        _buildPlanCard(
          context,
          premium,
          opcion: _PlanOpcion.lifetime,
          titulo: 'Lifetime',
          detalle: 'La app para siempre',
          icon: TablerIcons.infinity,
        ),
        const SizedBox(height: 12),

        // UN CTA prominente: compra el plan seleccionado.
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: isLoading
                ? null
                : () => _comprarPlan(context, premium, plan),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.sageGreenTitle,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _labelComprarPlan(premium, plan),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'El pago queda asociado a tu cuenta de Google y podés '
          'restaurarlo en cualquier dispositivo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppConstants.textTertiary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    PremiumProvider premium, {
    required _PlanOpcion opcion,
    required String titulo,
    required String detalle,
    required IconData icon,
    bool destacado = false,
  }) {
    final seleccionado = _planSeleccionado == opcion;
    final plan = opcion == _PlanOpcion.lifetime
        ? null
        : (opcion == _PlanOpcion.mensual
            ? MembresiaPlan.mensual
            : MembresiaPlan.anual);
    final precio = plan != null
        ? premium.membershipPrice(plan)
        : premium.lifetimePrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: seleccionado
            ? AppConstants.sageGreenCard
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: seleccionado
              ? AppConstants.sageGreenTitle
              : AppConstants.borderLight,
          width: seleccionado ? 1.5 : 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _planSeleccionado = opcion),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (destacado
                          ? AppConstants.alertAmberBackground
                          : AppConstants.sageGreenCard)
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: destacado
                      ? AppConstants.alertAmber
                      : AppConstants.sageGreenTitle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      detalle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                precio ?? (plan != null ? 'Ver en tienda' : 'Ver en tienda'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: seleccionado
                      ? AppConstants.sageGreenTitle
                      : AppConstants.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                seleccionado
                    ? TablerIcons.circle_check
                    : TablerIcons.circle,
                size: 20,
                color: seleccionado
                    ? AppConstants.sageGreenTitle
                    : AppConstants.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelComprarPlan(PremiumProvider premium, _PlanOpcion opcion) {
    final plan = opcion == _PlanOpcion.lifetime
        ? null
        : (opcion == _PlanOpcion.mensual
            ? MembresiaPlan.mensual
            : MembresiaPlan.anual);
    final precio = plan != null
        ? premium.membershipPrice(plan)
        : premium.lifetimePrice;
    final nombre = switch (opcion) {
      _PlanOpcion.mensual => 'Mensual',
      _PlanOpcion.anual => 'Anual',
      _PlanOpcion.lifetime => 'Lifetime',
    };
    return precio == null
        ? 'Comprar $nombre'
        : 'Comprar $nombre · $precio';
  }

  Future<void> _comprarPlan(
    BuildContext context,
    PremiumProvider premium,
    _PlanOpcion opcion,
  ) async {
    final plan = opcion == _PlanOpcion.lifetime
        ? null
        : (opcion == _PlanOpcion.mensual
            ? MembresiaPlan.mensual
            : MembresiaPlan.anual);
    final ok = plan != null
        ? await premium.purchaseSubscription(plan)
        : await premium.purchaseLifetime();
    if (!context.mounted) return;
    if (ok) {
      setState(() => _planSeleccionado = _PlanOpcion.anual);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Yuyo Premium activado! Todo desbloqueado.'),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // WIDGETS INTERNOS
  // ═══════════════════════════════════════════════════════════════════

  /// Sección "Packs por sistema": desbloqueo por sistema completo.
  /// Compras individuales PARA SIEMPRE (no quitan anuncios).
  Widget _buildPacksSection(PremiumProvider premium) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              TablerIcons.package,
              size: 18,
              color: AppConstants.sageGreenTitle,
            ),
            SizedBox(width: 6),
            Text(
              'Packs por sistema',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Comprá el pack de un sistema y desbloqueá TODAS sus recetas '
          'para siempre. Incluidos en la membresía y el lifetime. '
          'El precio lo define la tienda (Google Play).',
          style: TextStyle(
            fontSize: 12.5,
            color: AppConstants.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        for (final sistemaId in AppConstants.sistemasIds)
          _buildPackCard(premium, sistemaId),
      ],
    );
  }

  Widget _buildPackCard(PremiumProvider premium, String sistemaId) {
    final packId = PremiumRules.packIdDeSistema(sistemaId);
    final desbloqueado =
        premium.isPremium || premium.packs.contains(packId);
    final titleColor = AppConstants.getCardTitleColor(sistemaId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            SystemIcons.getIcon(sistemaId),
            size: 22,
            color: titleColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppConstants.sistemasNombres[sistemaId] ?? sistemaId,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
          if (desbloqueado)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  TablerIcons.check,
                  size: 16,
                  color: AppConstants.sageGreenTitle,
                ),
                const SizedBox(width: 4),
                Text(
                  premium.isPremium ? 'Incluido' : 'Desbloqueado',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.sageGreenTitle,
                  ),
                ),
              ],
            )
          else
            FilledButton(
              onPressed: premium.isLoading
                  ? null
                  : () => premium.purchasePack(sistemaId),
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.sageGreenTitle,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _packButtonLabel(premium, packId),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Etiqueta del botón de compra: con precio si la tienda lo devolvió.
  String _packButtonLabel(PremiumProvider premium, String packId) {
    final precio = premium.priceFor(packId);
    return precio == null ? 'Comprar pack' : 'Comprar pack · $precio';
  }

  Widget _buildPremiumActive(
    BuildContext context,
    PremiumProvider premium,
  ) {
    final esLifetime = premium.isLifetime;
    final hasta = premium.premiumUntil;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.sageGreenCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(
            TablerIcons.check,
            size: 40,
            color: AppConstants.sageGreenTitle,
          ),
          const SizedBox(height: 8),
          const Text(
            '¡Premium activo!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.sageGreenTitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            esLifetime
                ? 'Gracias por apoyar Yuyo con el lifetime. '
                    'Todo desbloqueado y sin anuncios, para siempre.'
                : hasta != null
                    ? 'Tu membresía vence el '
                        '${_fechaLegible(hasta)}. '
                        'Todo desbloqueado y sin anuncios.'
                    : 'Todo desbloqueado y sin anuncios.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _fechaLegible(DateTime fecha) {
    final local = fecha.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  Widget _buildBeneficio({
    required IconData icon,
    required Color color,
    required String titulo,
    required String detalle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
