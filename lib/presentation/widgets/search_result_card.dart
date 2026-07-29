import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/recetas_service.dart';
import 'app_card.dart';

/// Card de resultado de búsqueda — reutilizada en search y by_symptom
/// Muestra imagen para recetas, ícono para sistemas
class SearchResultCard extends StatelessWidget {
  final RecetaResult result;
  final bool showImage;

  const SearchResultCard({
    super.key,
    required this.result,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSistema = result.type == ResultType.sistema;
    final sistemaId = result.sistemaId;
    final cardBg = AppConstants.getCardBackgroundColor(sistemaId);
    final titleColor = AppConstants.getCardTitleColor(sistemaId);
    final icon = SystemIcons.getIcon(sistemaId);

    return AppCard(
      onTap: () {
        if (isSistema) {
          context.go('/category/$sistemaId');
        } else {
          context.go('/remedy/${result.id}');
        }
      },
      child: Row(
        children: [
          // ─── Leading: imagen o ícono ───
          _buildLeading(
            isSistema: isSistema,
            cardBg: cardBg,
            titleColor: titleColor,
            icon: icon,
          ),
          const SizedBox(width: 14),

          // ─── Texto (título + subtítulo) ───
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                if (result.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    result.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── Badge de tipo + chevron ───
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSistema ? cardBg : AppConstants.warmGrayCard,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSistema ? 'Sistema' : 'Receta',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSistema ? titleColor : AppConstants.warmGrayTitle,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Icon(
                TablerIcons.chevron_right,
                size: 16,
                color: AppConstants.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeading({
    required bool isSistema,
    required Color cardBg,
    required Color titleColor,
    required IconData icon,
  }) {
    // Solo mostrar imagen si no es sistema y está habilitado
    if (!isSistema && showImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Image.asset(
            'assets/images/recetas/${result.id}.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildIconAvatar(cardBg, titleColor, icon);
            },
          ),
        ),
      );
    }

    return _buildIconAvatar(cardBg, titleColor, icon);
  }

  Widget _buildIconAvatar(Color cardBg, Color titleColor, IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: titleColor),
    );
  }
}
