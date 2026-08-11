import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/premium_provider.dart';

/// Pantalla de Yuyo Premium: beneficios, compra única y restauración.
///
/// Funciona con cualquier [PaymentService]: en debug compra simulada
/// (Mock), en release billing real de Google Play.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

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
                Icon(
                  premium.isPremium
                      ? TablerIcons.crown
                      : TablerIcons.crown,
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
                  'Compra única para siempre. Apoyás el proyecto '
                  'y desbloqueás todo el contenido de Yuyo.',
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
            _buildPremiumActive(context)
          else ...[
            _buildBeneficio(
              icon: TablerIcons.lock_open,
              color: AppConstants.sageGreenTitle,
              titulo: 'Todas las recetas',
              detalle: 'Acceso completo a los 10 sistemas corporales.',
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
            const SizedBox(height: 20),

            // Botón de compra
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed:
                    isLoading ? null : () => premium.purchasePremium(),
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
                    : const Text(
                        'Comprar premium',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pago único. La compra queda asociada a tu cuenta de Google '
              'y podés restaurarla en cualquier dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.textTertiary,
                height: 1.4,
              ),
            ),
          ],

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
  // WIDGETS INTERNOS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPremiumActive(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.sageGreenCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: const Column(
        children: [
          Icon(
            TablerIcons.check,
            size: 40,
            color: AppConstants.sageGreenTitle,
          ),
          SizedBox(height: 8),
          Text(
            '¡Premium activo!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.sageGreenTitle,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Gracias por apoyar Yuyo. Todo desbloqueado y sin anuncios.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
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
