import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/payments/premium_rules.dart';
import '../../../data/models/receta_usuario.dart';
import '../../providers/premium_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/premium/premium_dialog.dart';

/// Detalle de una receta propia del usuario.
///
/// Mismo lenguaje visual que RemedyDetailScreen: secciones blancas con
/// borde, badges semánticos por tipo de preparación y disclaimer fijo.
/// La receta llega por parámetro (ya está en memoria) — sin fetch.
class RecetaUsuarioDetailScreen extends StatelessWidget {
  final RecetaUsuario receta;

  const RecetaUsuarioDetailScreen({super.key, required this.receta});

  @override
  Widget build(BuildContext context) {
    final tipo = receta.tipoPreparacion.isNotEmpty
        ? receta.tipoPreparacion
        : receta.tipo;
    final preparacionStyle = AppConstants.getPreparacionStyle(tipo);

    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/mis-recetas');
            }
          },
        ),
        title: Text(
          receta.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(
              TablerIcons.edit,
              size: 18,
              color: AppConstants.sageGreenTitle,
            ),
            tooltip: 'Editar',
            onPressed: () => context.push(
              '/mis-recetas/${receta.id}/editar',
              extra: receta,
            ),
          ),
          // Corazón de favorito (mismo patrón que RemedyDetailScreen).
          // Requiere sesión: las recetas propias solo existen logueado.
          if (context.watch<UserProvider>().isLoggedIn)
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
                          final premium =
                              context.read<PremiumProvider>();
                          final favoritosActuales =
                              userProvider.profile?.favoritos.length ?? 0;
                          if (PremiumRules.canAddFavorite(
                            isPremium: premium.isPremium,
                            currentFavorites: favoritosActuales,
                          )) {
                            userProvider.addFavorite(receta.id);
                          } else {
                            showPremiumDialog(
                              context,
                              title: 'Llegaste al límite de favoritos',
                              message: 'En el plan gratis podés guardar '
                                  '${AppConstants.freeFavoritosLimit} '
                                  'recetas. Con Premium guardás todas '
                                  'las que quieras.',
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════════════════════════
                  // HEADER: hero placeholder + badges + nombre
                  // ═══════════════════════════════════════════════
                  _buildHeroPlaceholder(preparacionStyle),
                  const SizedBox(height: 12),
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
                        if (receta.tipoPreparacion.isNotEmpty ||
                            receta.tipo.isNotEmpty) ...[
                          Row(
                            children: [
                              if (receta.tipoPreparacion.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: preparacionStyle.bg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    receta.tipoPreparacion,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: preparacionStyle.fg,
                                    ),
                                  ),
                                ),
                              if (receta.tipoPreparacion.isNotEmpty &&
                                  receta.tipo.isNotEmpty)
                                const SizedBox(width: 8),
                              if (receta.tipo.isNotEmpty)
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
                        ],
                        Text(
                          receta.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (receta.descripcion.isNotEmpty) ...[
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ═══════════════════════════════════════════════
                  // IDEAL PARA (chips)
                  // ═══════════════════════════════════════════════
                  if (receta.idealPara.isNotEmpty) ...[
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
                  ],

                  // ═══════════════════════════════════════════════
                  // CUÁNDO USAR
                  // ═══════════════════════════════════════════════
                  if (receta.cuandoUsar?.isNotEmpty == true) ...[
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
                    const SizedBox(height: 12),
                  ],

                  // ═══════════════════════════════════════════════
                  // PRECAUCIÓN (ámbar)
                  // ═══════════════════════════════════════════════
                  if (receta.precaucion.isNotEmpty) ...[
                    _buildSection(
                      icon: TablerIcons.alert_triangle,
                      title: 'Precaución',
                      isWarning: true,
                      child: Text(
                        receta.precaucion,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppConstants.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ═══════════════════════════════════════════════
                  // INGREDIENTES
                  // ═══════════════════════════════════════════════
                  if (receta.ingredientes.isNotEmpty) ...[
                    _buildSection(
                      icon: TablerIcons.list,
                      title: 'Ingredientes',
                      child: Column(
                        children:
                            receta.ingredientes.map<Widget>((ingrediente) {
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
                  ],

                  // ═══════════════════════════════════════════════
                  // PREPARACIÓN (numerada)
                  // ═══════════════════════════════════════════════
                  if (receta.preparacion.isNotEmpty) ...[
                    _buildSection(
                      icon: TablerIcons.flask,
                      title: 'Preparación',
                      child: Column(
                        children: receta.preparacion.asMap().entries
                            .map<Widget>((entry) {
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
                  ],

                  // ═══════════════════════════════════════════════
                  // CÓMO TOMARLO (dosis)
                  // ═══════════════════════════════════════════════
                  if (receta.dosis.isNotEmpty) ...[
                    _buildSection(
                      icon: TablerIcons.medical_cross,
                      title: 'Cómo tomarlo',
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
                  ],

                  // ═══════════════════════════════════════════════
                  // ALMACENAMIENTO
                  // ═══════════════════════════════════════════════
                  if (receta.almacenamiento.isNotEmpty) ...[
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
                    const SizedBox(height: 12),
                  ],

                  // ═══════════════════════════════════════════════
                  // DISCLAIMER FIJO
                  // ═══════════════════════════════════════════════
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.sageGreenCard.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          TablerIcons.info_circle,
                          size: 16,
                          color: AppConstants.textTertiary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Información tradicional, no reemplaza la indicación '
                            'de un profesional de la salud.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppConstants.textTertiary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Banner publicitario
          const BannerAdWidget(),
        ],
      ),
    );
  }

  /// Placeholder "hero": color semántico por tipo de preparación.
  Widget _buildHeroPlaceholder(PreparacionStyle style) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: Icon(style.icon, size: 56, color: style.fg),
    );
  }

  /// Sección blanca estándar (misma que RemedyDetailScreen).
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
                color:
                    isWarning ? AppConstants.alertAmber : AppConstants.sageGreenTitle,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isWarning ? AppConstants.alertAmber : AppConstants.textPrimary,
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
