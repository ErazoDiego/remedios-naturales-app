import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';

/// Pantalla acerca de - Información de la aplicación
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
            Icon(TablerIcons.info_circle, size: 20),
            SizedBox(width: 8),
            Text('Acerca de'),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ═══════════════════════════════════════════════════════════
          // HEADER CON NOMBRE DE APP
          // ═══════════════════════════════════════════════════════════
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
            child: const Column(
              children: [
                Icon(
                  TablerIcons.leaf,
                  size: 48,
                  color: AppConstants.sageGreenTitle,
                ),
                SizedBox(height: 16),
                Text(
                  'Remedios Naturales',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.sageGreenTitle,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tu guía de bienestar natural',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.sageGreenSubtitle,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Versión 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════════════════
          // DESCRIPCIÓN
          // ═══════════════════════════════════════════════════════════
          Container(
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
                const Text(
                  'Sobre esta aplicación',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Esta aplicación recopila remedios naturales transmitidos de generación en generación. '
                  'Cada receta ha sido cuidadosamente documentada con sus ingredientes, preparación y precauciones.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ═══════════════════════════════════════════════════════════
          // CARACTERÍSTICAS
          // ═══════════════════════════════════════════════════════════
          Container(
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
                const Text(
                  'Características',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeature(TablerIcons.wifi_off, 'Funciona sin internet'),
                _buildFeature(TablerIcons.search, 'Búsqueda por síntomas'),
                _buildFeature(TablerIcons.heart, 'Guarda tus favoritos'),
                _buildFeature(TablerIcons.history, 'Historial de recetas vistas'),
                _buildFeature(TablerIcons.leaf, '133 recetas naturales'),
                _buildFeature(TablerIcons.medical_cross, '10 sistemas del cuerpo'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ═══════════════════════════════════════════════════════════
          // AVISO LEGAL - Ámbar
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
                  size: 18,
                  color: AppConstants.alertAmber,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta aplicación es solo para fines informativos y educativos. '
                    'Los remedios aquí descritos no sustituyen el consejo médico profesional.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppConstants.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════
          // FOOTER
          // ═══════════════════════════════════════════════════════════
          const Center(
            child: Text(
              'Desarrollado con ♦',
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppConstants.sageGreenTitle,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
