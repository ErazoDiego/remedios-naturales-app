import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/services/payments/premium_rules.dart';
import '../../providers/premium_provider.dart';
import '../../providers/recetas_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/loading_error_empty.dart';
import '../../widgets/premium/premium_dialog.dart';
import '../../widgets/recipe_detail_body.dart';

/// Pantalla de detalle de receta del NÚCLEO embebido.
///
/// El cuerpo (secciones, ingredientes, preparación...) vive en
/// [RecipeDetailBody], compartido con las recetas de colección de la
/// Biblioteca. Acá queda el gating por sistema + historial + intersticial.
class RemedyDetailScreen extends StatefulWidget {
  final String recipeId;

  const RemedyDetailScreen({super.key, required this.recipeId});

  @override
  State<RemedyDetailScreen> createState() => _RemedyDetailScreenState();
}

class _RemedyDetailScreenState extends State<RemedyDetailScreen> {
  /// Momento en que el usuario abrió la receta.
  /// Se usa para filtrar visitas accidentales (< 3s).
  DateTime? _enteredAt;

  @override
  void initState() {
    super.initState();
    _enteredAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // La receta siempre se carga (si el usuario compra desde el muro,
      // el contenido aparece al instante).
      context.read<RecetasProvider>().loadReceta(widget.recipeId);

      // Receta bloqueada por el plan FREE: sin historial ni intersticial.
      final premium = context.read<PremiumProvider>();
      if (!premium.puedeAccederAReceta(widget.recipeId)) {
        return;
      }

      context.read<UserProvider>().addToHistory(widget.recipeId);

      // Registra la apertura para la política de espaciado del intersticial.
      // El intersticial se muestra al VOLVER de la receta (back button),
      // no al abrirla — Google prohíbe intersticiales al inicio de contenido.
      AdsService.instance.registerRecipeOpen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecetasProvider>(
      builder: (context, provider, child) {
        final receta = provider.currentReceta;
        final sistemaId = widget.recipeId.split('_')[0];
        final titleColor = AppConstants.getCardTitleColor(sistemaId);

        // Acceso al detalle: FREE solo al muestreo, Premium a todas.
        final premium = context.watch<PremiumProvider>();
        final accesoPermitido = premium.puedeAccederAReceta(widget.recipeId);

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) return;
            // System back button — misma lógica que el botón de la UI.
            final elapsed = _enteredAt != null
                ? DateTime.now().difference(_enteredAt!).inSeconds
                : 0;
            if (elapsed >= 3) {
              AdsService.instance.maybeShowInterstitial();
            }
          },
          child: Scaffold(
          backgroundColor: AppConstants.backgroundCream,
            appBar: AppBar(
            leading: IconButton(
              icon: const Icon(TablerIcons.arrow_left),
              onPressed: () {
                // Solo muestra interstitial si el usuario permaneció ≥ 3s
                // en la receta — evita interrumpir por taps accidentales.
                final elapsed = _enteredAt != null
                    ? DateTime.now().difference(_enteredAt!).inSeconds
                    : 0;
                if (elapsed >= 3) {
                  AdsService.instance.maybeShowInterstitial();
                }
                // Volver al ORIGEN real (buscador, favoritos, home...):
                // pop respeta la pila; go() como fallback si llegaron por
                // deep link sin pila (mismo bug de "quedarse atrapado"
                // que tenía la ficha de hierba).
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/category/$sistemaId');
                }
              },
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
                              _toggleFavorito(context, userProvider, receta.id);
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
                child: !accesoPermitido
                    ? _buildPremiumWall()
                    : LoadingErrorEmpty(
                        isLoading: provider.isLoading,
                        error: provider.error,
                        isEmpty: receta == null,
                        emptyMessage: 'Receta no encontrada',
                        child: receta != null
                            ? RecipeDetailBody(receta: receta)
                            : null,
                      ),
              ),
              // Banner publicitario (si el usuario no es premium)
              const BannerAdWidget(),
            ],
          ),
        ),
        );
      },
    );
  }

  /// Agrega un favorito respetando el límite del plan FREE (5).
  /// Premium: sin límite. Al llegar al tope muestra el CTA de compra.
  Future<void> _toggleFavorito(
    BuildContext context,
    UserProvider userProvider,
    String recetaId,
  ) async {
    final premium = context.read<PremiumProvider>();
    final favoritosActuales = userProvider.profile?.favoritos.length ?? 0;

    if (PremiumRules.canAddFavorite(
      isPremium: premium.isPremium,
      currentFavorites: favoritosActuales,
    )) {
      await userProvider.addFavorite(recetaId);
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

  /// Muro de receta premium: la receta no está en el muestreo gratis
  /// y el usuario no tiene Premium. CTA directo a la pantalla de compra.
  Widget _buildPremiumWall() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppConstants.warmGrayCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              TablerIcons.lock,
              size: 44,
              color: AppConstants.alertAmber,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Receta Premium',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Esta receta forma parte de Yuyo Premium. Con el plan '
            'gratis tenés acceso a 5 recetas de cada sistema.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/premium'),
            icon: const Icon(TablerIcons.crown, size: 18),
            label: const Text('Ver Premium'),
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
