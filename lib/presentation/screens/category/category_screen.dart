import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/recetas_provider.dart';
import '../../widgets/loading_error_empty.dart';

/// Pantalla de categoría — Muestra las recetas de un sistema corporal
///
/// Layout de card:
///   [Ícono tipo] [Badge + Título + Tags] [▸]
///   Todo en una fila, sin descripción (queda en detalle)
class CategoryScreen extends StatefulWidget {
  final String systemId;

  const CategoryScreen({super.key, required this.systemId});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecetasProvider>().loadSistema(widget.systemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecetasProvider>(
      builder: (context, provider, child) {
        final sistema = provider.currentSistema;
        final titleColor = AppConstants.getCardTitleColor(widget.systemId);
        final icon = SystemIcons.getIcon(widget.systemId);

        return Scaffold(
          backgroundColor: AppConstants.backgroundCream,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(TablerIcons.arrow_left),
              onPressed: () => context.go('/'),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: titleColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    sistema?.nombre ?? widget.systemId,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppConstants.headerBeige,
            foregroundColor: AppConstants.textPrimary,
          ),
          body: LoadingErrorEmpty(
            isLoading: provider.isLoading,
            error: provider.error,
            isEmpty: sistema?.recetas.isEmpty ?? true,
            emptyMessage: 'No hay recetas disponibles',
            onRetry: () => provider.loadSistema(widget.systemId),
            child: _buildRecipeList(sistema?.recetas ?? []),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LISTA DE RECETAS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRecipeList(List<dynamic> recetas) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: recetas.length,
      itemBuilder: (context, index) {
        final receta = recetas[index];
        return _buildRecipeCard(receta);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CARD DE RECETA — Layout horizontal
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRecipeCard(dynamic receta) {
    final tipo = receta.tipoPreparacion ?? receta.tipo ?? '';
    final preparacionStyle = AppConstants.getPreparacionStyle(tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.borderLight,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => context.go('/remedy/${receta.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Imagen de la receta (con placeholder de color) ───
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: receta.imagen != null
                      ? Image.asset(
                          receta.imagen!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildColorPlaceholder(preparacionStyle);
                          },
                        )
                      : _buildColorPlaceholder(preparacionStyle),
                ),
              ),
              const SizedBox(width: 14),

              // ─── Columna de texto (badge + título + tags) ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de tipo de preparación
                    if (tipo.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: preparacionStyle.bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tipo,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: preparacionStyle.fg,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    if (tipo.isNotEmpty) const SizedBox(height: 8),

                    // Título de la receta — se muestra completo, envuelve en 2 líneas
                    Text(
                      receta.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),

                    // Tags "ideal para" — máx 3 visibles
                    if (receta.idealPara.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: receta.idealPara.take(3).map<Widget>((condicion) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.warmGrayCard,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              condicion,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppConstants.warmGraySubtitle,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // ─── Chevron de navegación ───
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 16),
                child: Icon(
                  TablerIcons.chevron_right,
                  size: 18,
                  color: AppConstants.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Placeholder de color con ícono (fallback si no hay imagen) ───
  Widget _buildColorPlaceholder(PreparacionStyle style) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        style.icon,
        size: 28,
        color: style.fg,
      ),
    );
  }
}
