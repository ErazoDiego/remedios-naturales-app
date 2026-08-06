import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';

/// Pantalla de seguridad - Precauciones y advertencias
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.alert_triangle, size: 20, color: AppConstants.alertAmber),
            SizedBox(width: 8),
            Text('Seguridad'),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ═══════════════════════════════════════════════════════════
          // ADVERTENCIA PRINCIPAL - Ámbar
          // ═══════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.alertAmberBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.alertAmber.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  TablerIcons.alert_triangle,
                  color: AppConstants.alertAmber,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IMPORTANTE',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppConstants.alertAmber,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Estos remedios son complementarios y NO reemplazan la consulta médica profesional.',
                        style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════════════════
          // SECCIONES DE ADVERTENCIA
          // ═══════════════════════════════════════════════════════════
          _buildWarningSection(
            icon: TablerIcons.stethoscope,
            title: 'Consultá a tu médico',
            items: [
              'Si estás embarazada o en período de lactancia',
              'Si estás tomando medicamentos',
              'Si tenés alergias conocidas',
              'Si padecés enfermedades crónicas',
              'Si sos niño o persona mayor',
            ],
          ),
          const SizedBox(height: 12),
          _buildWarningSection(
            icon: TablerIcons.shield_check,
            title: 'Precauciones generales',
            items: [
              'No exceder las dosis recomendadas',
              'Respetar las contraindicaciones',
              'Dejar de usar si aparecen efectos adversos',
              'No usar plantas silvestres sin identificación segura',
              'Guardar los preparados correctamente',
            ],
          ),
          const SizedBox(height: 12),
          _buildWarningSection(
            icon: TablerIcons.phone,
            title: 'Emergencias',
            items: [
              'Si presentas dificultad para respirar, buscá atención médica inmediata',
              'Si hay reacción alérgica severa, llamá a emergencias',
              'Si sospechás intoxicación, no esperes',
              'En caso de duda, SIEMPRE consultá a un profesional',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.textPrimary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  TablerIcons.point,
                  size: 8,
                  color: AppConstants.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
