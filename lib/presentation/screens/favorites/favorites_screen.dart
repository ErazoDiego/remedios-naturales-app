import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/receta.dart';
import '../../../data/models/receta_usuario.dart';
import '../../../data/services/recetas_usuario_service.dart';
import '../../providers/recetas_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/ads/banner_ad_widget.dart';

/// Pantalla de favoritos — Muestra las recetas guardadas con el mismo layout que CategoryScreen.
///
/// Soporta dos fuentes:
/// - Recetas del catálogo (IDs legibles tipo "digestivo_remedio_x")
/// - Recetas propias del usuario (IDs UUID) — requieren sesión
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

/// Item unificado de favoritos: envuelve una receta del catálogo o una
/// propia para que la card sea agnóstica del origen.
class _FavoriteItem {
  final String id;
  final String nombre;
  final String tipoPreparacion;
  final String? imagen;
  final List<String> idealPara;
  final bool esPropia;
  final RecetaUsuario? recetaPropia;

  _FavoriteItem.fromCatalogo(Receta r)
      : id = r.id,
        nombre = r.nombre,
        tipoPreparacion = r.tipoPreparacion,
        imagen = r.imagen,
        idealPara = r.idealPara,
        esPropia = false,
        recetaPropia = null;

  _FavoriteItem.fromPropia(RecetaUsuario r)
      : id = r.id,
        nombre = r.nombre,
        tipoPreparacion = r.tipoPreparacion,
        imagen = r.imagen,
        idealPara = r.idealPara,
        esPropia = true,
        recetaPropia = r;
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<_FavoriteItem> _favoriteItems = [];
  bool _isLoading = true;
  List<String> _lastFavoritos = const [];

  /// Referencias capturadas en initState (NO usar `context` en dispose:
  /// el Element ya está deactivated y Provider._inheritedElementOf
  /// devuelve null → "Null check operator used on a null value" al
  /// desmontar (lo destapa el remount que causa el interstitial de AdMob).
  late final UserProvider _userProvider;
  late final RecetasProvider _recetasProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _recetasProvider = context.read<RecetasProvider>();
    _loadFavorites();
    // El tab vive en un indexedStack: initState NO vuelve a correr al
    // volver, así que escuchamos al UserProvider y recargamos SOLO si
    // cambió la lista de favoritos (no en cada notify de historial/error).
    _userProvider.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    _userProvider.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (!mounted) return;
    final favorites = _userProvider.profile?.favoritos ?? [];
    if (!_sameList(_lastFavoritos, favorites)) {
      _lastFavoritos = favorites;
      _loadFavorites();
    }
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _loadFavorites() async {
    final favorites = _userProvider.profile?.favoritos ?? [];

    if (favorites.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Separar por origen: UUID = receta propia, resto = catálogo
    final catalogIds = favorites
        .where((id) => !RecetasUsuarioService.isRecetaPropiaId(id))
        .toList();
    final propiaIds = favorites
        .where(RecetasUsuarioService.isRecetaPropiaId)
        .toList();

    final itemsById = <String, _FavoriteItem>{};

    // ── Catálogo ──
    if (catalogIds.isNotEmpty) {
      try {
        final recetas = await _recetasProvider.getRecetasByIds(catalogIds);
        for (final r in recetas) {
          itemsById[r.id] = _FavoriteItem.fromCatalogo(r);
        }
      } catch (_) {
        // IDs de catálogo que no resuelven se omiten
      }
    }

    // ── Recetas propias (solo con sesión; sin sesión no existen) ──
    if (propiaIds.isNotEmpty && _userProvider.isLoggedIn) {
      try {
        final todas = await RecetasUsuarioService().getMisRecetas();
        for (final r in todas) {
          if (propiaIds.contains(r.id)) {
            itemsById[r.id] = _FavoriteItem.fromPropia(r);
          }
        }
      } catch (_) {
        // Offline o sin permisos: se omiten; se reintenta al recargar
      }
    }

    // Preservar el orden en que el usuario las marcó
    final items = [
      for (final id in favorites)
        if (itemsById[id] != null) itemsById[id]!,
    ];

    if (mounted) {
      setState(() {
        _favoriteItems = items;
        _isLoading = false;
      });
    }
  }

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(TablerIcons.heart, size: 20, color: AppConstants.sageGreenTitle),
            const SizedBox(width: 8),
            Text(
              'Mis Favoritos${_favoriteItems.isNotEmpty ? ' (${_favoriteItems.length})' : ''}',
            ),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.sageGreenTitle,
                      strokeWidth: 2,
                    ),
                  )
                : _favoriteItems.isEmpty
                    ? _buildEmptyState()
                    : _buildRecipeList(),
          ),
          // Banner publicitario (si el usuario no es premium)
          const BannerAdWidget(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LISTA DE RECETAS — Mismo layout que CategoryScreen
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRecipeList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _favoriteItems.length,
      itemBuilder: (context, index) {
        return _buildRecipeCard(_favoriteItems[index]);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CARD DE RECETA — Mismo layout que CategoryScreen, con badge "Propia"
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRecipeCard(_FavoriteItem item) {
    final preparacionStyle = AppConstants.getPreparacionStyle(item.tipoPreparacion);

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
        onTap: () {
          if (item.esPropia) {
            context.push('/mis-recetas/${item.id}', extra: item.recetaPropia);
          } else {
            context.go('/remedy/${item.id}');
          }
        },
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
                  child: item.imagen != null
                      ? Image.asset(
                          item.imagen!,
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
                    Row(
                      children: [
                        if (item.tipoPreparacion.isNotEmpty) ...[
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
                              item.tipoPreparacion,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: preparacionStyle.fg,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (item.esPropia)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.sageGreenCard,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Propia',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.sageGreenTitle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (item.tipoPreparacion.isNotEmpty || item.esPropia)
                      const SizedBox(height: 8),

                    // Título de la receta
                    Text(
                      item.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),

                    // Tags "ideal para" — máx 3 visibles
                    if (item.idealPara.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.idealPara.take(3).map<Widget>((condicion) {
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
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
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
