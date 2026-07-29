import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/recetas_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading_error_empty.dart';

/// Pantalla de detalle de receta - Muestra toda la información de un remedio
class RemedyDetailScreen extends StatefulWidget {
  final String recipeId;

  const RemedyDetailScreen({super.key, required this.recipeId});

  @override
  State<RemedyDetailScreen> createState() => _RemedyDetailScreenState();
}

class _RemedyDetailScreenState extends State<RemedyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecetasProvider>().loadReceta(widget.recipeId);
      context.read<UserProvider>().addToHistory(widget.recipeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecetasProvider>(
      builder: (context, provider, child) {
        final receta = provider.currentReceta;
        final sistemaId = widget.recipeId.split('_')[0];
        final titleColor = AppConstants.getCardTitleColor(sistemaId);

        return Scaffold(
          backgroundColor: AppConstants.backgroundCream,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(TablerIcons.arrow_left),
              onPressed: () => context.go('/category/$sistemaId'),
            ),
            title: Text(
              receta?.nombre ?? 'Cargando...',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppConstants.headerBeige,
            foregroundColor: AppConstants.textPrimary,
            actions: [
              if (receta != null)
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return FutureBuilder<bool>(
                      future: userProvider.isFavorite(receta.id),
                      builder: (context, snapshot) {
                        final isFavorite = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : TablerIcons.heart,
                            color: isFavorite
                                ? AppConstants.alertAmber
                                : AppConstants.textTertiary,
                          ),
                          onPressed: () {
                            if (isFavorite) {
                              userProvider.removeFavorite(receta.id);
                            } else {
                              userProvider.addFavorite(receta.id);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
            ],
          ),
          body: LoadingErrorEmpty(
            isLoading: provider.isLoading,
            error: provider.error,
            isEmpty: receta == null,
            emptyMessage: 'Receta no encontrada',
            child: receta != null ? _buildRecipeDetail(receta) : null,
          ),
        );
      },
    );
  }

  Widget _buildRecipeDetail(dynamic receta) {
    final tipo = receta.tipoPreparacion ?? receta.tipo ?? '';
    final preparacionStyle = AppConstants.getPreparacionStyle(tipo);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════
          // HERO IMAGE
          // ═══════════════════════════════════════════════════════════
          if (receta.imagen != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 220,
                child: Image.asset(
                  receta.imagen!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildHeroPlaceholder(preparacionStyle);
                  },
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════════════════════
                // HEADER CON NOMBRE Y TIPO
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
                      Row(
                        children: [
                          // Badge con color semántico por tipo de preparación
                          Builder(
                            builder: (context) {
                              final prepStyle = AppConstants.getPreparacionStyle(receta.tipoPreparacion);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: prepStyle.bg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  receta.tipoPreparacion,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: prepStyle.fg,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.warmGrayCard,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              receta.tipo,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.warmGrayTitle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        receta.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        receta.descripcion,
                        style: const TextStyle(
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
                // IDEAL PARA
                // ═══════════════════════════════════════════════════════════
                _buildSection(
                  icon: TablerIcons.circle_check,
                  title: 'Ideal para',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: receta.idealPara.map<Widget>((condicion) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.sageGreenCard,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          condicion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.sageGreenTitle,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // ═══════════════════════════════════════════════════════════
                // CUÁNDO USAR
                // ═══════════════════════════════════════════════════════════
                if (receta.cuandoUsar != null && receta.cuandoUsar!.isNotEmpty)
                  _buildSection(
                    icon: TablerIcons.clock,
                    title: 'Cuándo usarlo',
                    child: Text(
                      receta.cuandoUsar!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                if (receta.cuandoUsar != null && receta.cuandoUsar!.isNotEmpty)
                  const SizedBox(height: 12),

                // ═══════════════════════════════════════════════════════════
                // PRECAUCIÓN - Ámbar
                // ═══════════════════════════════════════════════════════════
                _buildSection(
                  icon: TablerIcons.alert_triangle,
                  title: 'Precaución',
                  isWarning: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.alertAmberBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.alertAmber.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      receta.precaucion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ═══════════════════════════════════════════════════════════
                // INGREDIENTES
                // ═══════════════════════════════════════════════════════════
                _buildSection(
                  icon: TablerIcons.list,
                  title: 'Ingredientes',
                  child: Column(
                    children: receta.ingredientes.map<Widget>((ingrediente) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              TablerIcons.point,
                              size: 8,
                              color: AppConstants.sageGreenTitle,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ingrediente,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // ═══════════════════════════════════════════════════════════
                // PREPARACIÓN
                // ═══════════════════════════════════════════════════════════
                _buildSection(
                  icon: TablerIcons.flask,
                  title: 'Preparación',
                  child: Column(
                    children: receta.preparacion.asMap().entries.map<Widget>((entry) {
                      final index = entry.key + 1;
                      final paso = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppConstants.sageGreenCard,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(
                                  '$index',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.sageGreenTitle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                paso,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppConstants.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // ═══════════════════════════════════════════════════════════
                // DOSIS
                // ═══════════════════════════════════════════════════════════
                _buildSection(
                  icon: TablerIcons.medical_cross,
                  title: 'Dosis',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.sageGreenCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          TablerIcons.info_circle,
                          size: 18,
                          color: AppConstants.sageGreenTitle,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            receta.dosis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ═══════════════════════════════════════════════════════════
                // ALMACENAMIENTO
                // ═══════════════════════════════════════════════════════════
                _buildSection(
                  icon: TablerIcons.package,
                  title: 'Almacenamiento',
                  child: Text(
                    receta.almacenamiento,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Placeholder hero cuando no hay imagen ───
  Widget _buildHeroPlaceholder(PreparacionStyle style) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Icon(
        style.icon,
        size: 64,
        color: style.fg,
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? AppConstants.alertAmber.withValues(alpha: 0.3)
              : AppConstants.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isWarning ? AppConstants.alertAmber : AppConstants.sageGreenTitle,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isWarning ? AppConstants.alertAmber : AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
