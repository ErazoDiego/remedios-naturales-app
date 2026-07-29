import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/receta.dart';
import '../../providers/recetas_provider.dart';
import '../../providers/user_provider.dart';

/// Pantalla de favoritos — Muestra las recetas guardadas con el mismo layout que CategoryScreen
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Receta> _favoriteRecetas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final userProvider = context.read<UserProvider>();
    final recetasProvider = context.read<RecetasProvider>();
    final favorites = userProvider.profile?.favoritos ?? [];

    if (favorites.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final recetas = await recetasProvider.getRecetasByIds(favorites);
      if (mounted) {
        setState(() {
          _favoriteRecetas = recetas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const Icon(TablerIcons.heart, size: 20, color: AppConstants.sageGreenTitle),
            const SizedBox(width: 8),
            Text(
              'Mis Favoritos${_favoriteRecetas.isNotEmpty ? ' (${_favoriteRecetas.length})' : ''}',
            ),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppConstants.sageGreenTitle,
                strokeWidth: 2,
              ),
            )
          : _favoriteRecetas.isEmpty
              ? _buildEmptyState()
              : _buildRecipeList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LISTA DE RECETAS — Mismo layout que CategoryScreen
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRecipeList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _favoriteRecetas.length,
      itemBuilder: (context, index) {
        final receta = _favoriteRecetas[index];
        return _buildRecipeCard(receta);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CARD DE RECETA — Copy de CategoryScreen._buildRecipeCard
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRecipeCard(Receta receta) {
    final tipo = receta.tipoPreparacion;
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

                    // Título de la receta
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              TablerIcons.heart_off,
              size: 48,
              color: AppConstants.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No tenés favoritos aún',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tocá el corazón en una receta para guardarla aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.sageGreenTitle,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Explorar recetas'),
            ),
          ],
        ),
      ),
    );
  }
}
