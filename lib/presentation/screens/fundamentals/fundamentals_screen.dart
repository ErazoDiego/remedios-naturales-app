import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';

/// Pantalla de fundamentos - Principios de la medicina natural
class FundamentalsScreen extends StatelessWidget {
  const FundamentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () => context.go('/'),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.book, size: 20),
            SizedBox(width: 8),
            Text('Fundamentos'),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            icon: TablerIcons.leaf,
            title: '¿Qué son los remedios naturales?',
            content: 'Los remedios naturales son preparaciones hechas con plantas medicinales que se han utilizado durante siglos para aliviar diferentes dolencias. Estos remedios aprovechan los principios activos de las plantas para promover la salud de forma suave y natural.',
          ),
          const SizedBox(height: 12),
          _buildSection(
            icon: TablerIcons.flask,
            title: '¿Cómo funcionan?',
            content: 'Las plantas medicinales contienen sustancias químicas naturales que interactúan con nuestro cuerpo. Algunas actúan como antiinflamatorios, otras como analgésicos, y muchas fortalecen el sistema inmunológico. La clave está en usarlas correctamente.',
          ),
          const SizedBox(height: 12),
          _buildSection(
            icon: TablerIcons.alert_triangle,
            title: 'Precauciones importantes',
            content: 'Aunque son naturales, estos remedios pueden tener efectos secundarios. Siempre consulta con un profesional de salud antes de usarlos, especialmente si estás embarazada, tomas medicamentos o tienes condiciones médicas crónicas.',
            isWarning: true,
          ),
          const SizedBox(height: 12),
          _buildSection(
            icon: TablerIcons.history,
            title: 'Sabiduría ancestral',
            content: 'Estos remedios han sido transmitidos de generación en generación. La abuela sabia conocía el poder de las plantas y las preparaba con cuidado y dedicación. Hoy recuperamos esa sabiduría para el bienestar moderno.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    bool isWarning = false,
  }) {
    final cardColor = isWarning ? AppConstants.alertAmberBackground : Colors.white;
    final iconColor = isWarning ? AppConstants.alertAmber : AppConstants.sageGreenTitle;
    final borderColor = isWarning ? AppConstants.alertAmber.withValues(alpha: 0.3) : AppConstants.borderLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isWarning ? AppConstants.alertAmber : AppConstants.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
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
}
