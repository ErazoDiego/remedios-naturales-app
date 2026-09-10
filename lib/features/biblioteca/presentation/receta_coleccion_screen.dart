import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/payments/premium_rules.dart';
import '../../../presentation/providers/biblioteca_provider.dart';
import '../../../presentation/providers/premium_provider.dart';
import '../../../presentation/providers/user_provider.dart';
import '../../../presentation/widgets/ads/banner_ad_widget.dart';
import '../../../presentation/widgets/premium/premium_dialog.dart';
import '../../../presentation/widgets/recipe_detail_body.dart';
import '../../biblioteca/domain/coleccion.dart';
import '../../biblioteca/domain/favorito_coleccion.dart';
import 'widgets/coleccion_visual.dart';

/// Detalle de una receta de colección.
///
/// Reusa [RecipeDetailBody] (el mismo cuerpo del núcleo). Gating propio
/// de colección: premium o pack 'yuyo_pack_<coleccionId>'. SIN
/// historial ni intersticiales — la biblioteca queda como isla limpia;
/// el banner sí aparece para no-premium, consistente con el resto de la
/// app. SÍ tiene favoritos: los usuarios quieren TODAS sus recetas (del
/// catálogo, de colecciones y propias) mezcladas en el tab Favoritos;
/// el ID guardado usa el prefijo `col:` (ver [FavoritoColeccion]).
class RecetaColeccionScreen extends StatelessWidget {
  final String coleccionId;
  final String recetaId;

  const RecetaColeccionScreen({
    super.key,
    required this.coleccionId,
    required this.recetaId,
  });

  @override
  Widget build(BuildContext context) {
    final biblioteca = context.watch<BibliotecaProvider>();
    final coleccion = _buscarColeccion(biblioteca);
    final rc = coleccion?.recetaPorId(recetaId);
    final acceso = biblioteca.puedeAcceder(coleccionId);

    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/biblioteca/$coleccionId');
            }
          },
        ),
        title: Text(
          rc?.receta.nombre ?? 'Receta',
          style: TextStyle(
            color: colorDeColeccion(coleccion?.color ?? 'verde'),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
        actions: [
          // Corazón de favorito (mismo patrón que RemedyDetailScreen).
          // El favorito guarda el ID compuesto `col:<coleccionId>:<recetaId>`
          // para que el tab Favoritos lo resuelva contra la colección.
          if (rc != null)
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final favId = FavoritoColeccion.idDe(coleccionId, recetaId);
                return FutureBuilder<bool>(
                  future: userProvider.isFavorite(favId),
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
                          userProvider.removeFavorite(favId);
                        } else {
                          _toggleFavorito(context, userProvider, favId);
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
            child: rc == null || coleccion == null
                ? const Center(
                    child: Text(
                      'Receta no encontrada',
                      style: TextStyle(color: AppConstants.textSecondary),
                    ),
                  )
                : !acceso
                    ? _buildMuro(context, coleccion)
                    : RecipeDetailBody(receta: rc.receta),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  /// Agrega un favorito respetando el límite del plan FREE (5).
  /// Premium: sin límite. Al llegar al tope muestra el CTA de compra.
  /// (Mismo comportamiento que RemedyDetailScreen.)
  Future<void> _toggleFavorito(
    BuildContext context,
    UserProvider userProvider,
    String favId,
  ) async {
    final premium = context.read<PremiumProvider>();
    final favoritosActuales = userProvider.profile?.favoritos.length ?? 0;

    if (PremiumRules.canAddFavorite(
      isPremium: premium.isPremium,
      currentFavorites: favoritosActuales,
    )) {
      await userProvider.addFavorite(favId);
      return;
    }

    if (!context.mounted) return;
    await showPremiumDialog(
      context,
      title: 'Llegaste al límite de favoritos',
      message: 'En el plan gratis podés guardar '
          '${AppConstants.freeFavoritosLimit} recetas. Con Premium '
          'guardás todas las que quieras.',
    );
  }

  Coleccion? _buscarColeccion(BibliotecaProvider biblioteca) {
    for (final c in biblioteca.catalogo) {
      if (c.id == coleccionId) return c;
    }
    return null;
  }

  /// Muro: la colección está en la tienda pero no desbloqueada.
  Widget _buildMuro(BuildContext context, Coleccion coleccion) {
    final biblioteca = context.read<BibliotecaProvider>();
    final precio = biblioteca.precio(coleccionId);
    final accent = colorDeColeccion(coleccion.color);
    final background = colorFondoDeColeccion(coleccion.color);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconoDeColeccion(coleccion.icono),
              size: 44,
              color: accent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Colección bloqueada',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Esta receta pertenece a una colección que todavía no '
            'desbloqueaste.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => showPremiumDialog(
              context,
              message:
                  'Desbloqueá "${coleccion.nombre}" con su pack, '
                  'o con Premium accedés a todas las colecciones.',
              sistemaId: coleccionId,
            ),
            icon: const Icon(TablerIcons.lock_open, size: 18),
            label: Text(
              precio == null ? 'Desbloquear' : 'Desbloquear · $precio',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.sageGreenTitle,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
