import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/receta.dart';
import '../../../data/models/receta_usuario.dart';
import '../../../data/services/recetas_usuario_service.dart';
import '../../../features/biblioteca/domain/coleccion.dart';
import '../../../features/biblioteca/domain/favorito_coleccion.dart';
import '../../providers/biblioteca_provider.dart';
import '../../providers/recetas_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/ads/banner_ad_widget.dart';

/// Pantalla de favoritos — Muestra las recetas guardadas con el mismo layout que CategoryScreen.
///
/// Soporta tres fuentes (todas conviven mezcladas, en el orden en que
/// el usuario las marcó):
/// - Recetas del catálogo (IDs legibles tipo "digestivo_remedio_x")
/// - Recetas de colecciones (IDs con prefijo "col:", ver [FavoritoColeccion])
/// - Recetas propias del usuario (IDs UUID) — requieren sesión
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

/// Item unificado de favoritos: envuelve una receta del catálogo, de
/// colección o propia para que la card sea agnóstica del origen.
/// `grupo` es el header de agrupación (nombre de colección, sistema
/// corporal o "Mis recetas").
class _FavoriteItem {
  final String id;
  final String nombre;
  final String tipoPreparacion;
  final String? imagen;
  final List<String> idealPara;
  final bool esPropia;
  final RecetaUsuario? recetaPropia;
  final bool esColeccion;
  final String? coleccionId;
  final String grupo;

  _FavoriteItem.fromCatalogo(Receta r)
      : id = r.id,
        nombre = r.nombre,
        tipoPreparacion = r.tipoPreparacion,
        imagen = r.imagen,
        idealPara = r.idealPara,
        esPropia = false,
        recetaPropia = null,
        esColeccion = false,
        coleccionId = null,
        grupo = _grupoDeSistema(r.id);

  _FavoriteItem.fromPropia(RecetaUsuario r)
      : id = r.id,
        nombre = r.nombre,
        tipoPreparacion = r.tipoPreparacion,
        imagen = r.imagen,
        idealPara = r.idealPara,
        esPropia = true,
        recetaPropia = r,
        esColeccion = false,
        coleccionId = null,
        grupo = 'Mis recetas';

  _FavoriteItem.fromColeccion(
    RecetaColeccion rc,
    this.coleccionId,
    String nombreColeccion,
  )   : id = rc.receta.id,
        nombre = rc.receta.nombre,
        tipoPreparacion = rc.receta.tipoPreparacion,
        imagen = rc.receta.imagen,
        idealPara = rc.receta.idealPara,
        esPropia = false,
        recetaPropia = null,
        esColeccion = true,
        grupo = nombreColeccion;

  /// Sistema corporal de un ID de catálogo ("digestivo_remedio_x" →
  /// "Sistema Digestivo"). Fallback para IDs desconocidos.
  static String _grupoDeSistema(String id) {
    final prefijo = id.split('_').first;
    return AppConstants.sistemasNombres[prefijo] ?? 'Recetas';
  }
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
  late final BibliotecaProvider _bibliotecaProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _recetasProvider = context.read<RecetasProvider>();
    _bibliotecaProvider = context.read<BibliotecaProvider>();
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

    // Separar por origen: UUID = receta propia, "col:" = colección,
    // resto = catálogo
    final propiaIds = favorites
        .where(RecetasUsuarioService.isRecetaPropiaId)
        .toList();
    final coleccionIds = favorites
        .where(FavoritoColeccion.esDeColeccion)
        .toList();
    final catalogIds = favorites
        .where((id) =>
            !RecetasUsuarioService.isRecetaPropiaId(id) &&
            !FavoritoColeccion.esDeColeccion(id))
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

    // ── Colecciones (biblioteca descargada) ──
    if (coleccionIds.isNotEmpty) {
      for (final favId in coleccionIds) {
        final descompuesto = FavoritoColeccion.descomponer(favId);
        if (descompuesto == null) continue;
        final (coleccionId, recetaId) = descompuesto;
        Coleccion? coleccion;
        for (final c in _bibliotecaProvider.catalogo) {
          if (c.id == coleccionId) {
            coleccion = c;
            break;
          }
        }
        final rc = coleccion?.recetaPorId(recetaId);
        if (rc == null) continue;
        itemsById[favId] = _FavoriteItem.fromColeccion(
          rc,
          coleccionId,
          coleccion!.nombre,
        );
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
        actions: [
          // Atajo a la lista de compras (las recetas favoritas alimentan la lista)
          IconButton(
            icon: const Icon(
              TablerIcons.shopping_cart,
              size: 20,
              color: AppConstants.sageGreenTitle,
            ),
            tooltip: 'Lista de compras',
            onPressed: () => context.go('/lista-compras'),
          ),
        ],
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
  // AGRUPACIÓN — Favoritos agrupados por origen (colecciones, sistemas
  // corporales, recetas propias). El orden de los grupos sigue la
  // PRIMERA aparición de cada uno en la lista de marcado del usuario;
  // dentro de cada grupo se mantiene ese mismo orden.
  // ═══════════════════════════════════════════════════════════════════
  List<({String grupo, List<_FavoriteItem> items})> get _secciones {
    final secciones = <({String grupo, List<_FavoriteItem> items})>[];
    final indice = <String, int>{};

    for (final item in _favoriteItems) {
      final i = indice[item.grupo];
      if (i == null) {
        indice[item.grupo] = secciones.length;
        secciones.add((grupo: item.grupo, items: [item]));
      } else {
        secciones[i].items.add(item);
      }
    }
    return secciones;
  }

  // ═══════════════════════════════════════════════════════════════════
  // LISTA DE RECETAS — Mismo layout que CategoryScreen
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRecipeList() {
    final secciones = _secciones;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final seccion in secciones) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              seccion.grupo.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppConstants.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          for (final item in seccion.items) _buildRecipeCard(item),
        ],
      ],
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
          if (item.esColeccion) {
            context.push('/biblioteca/${item.coleccionId}/${item.id}');
          } else if (item.esPropia) {
            context.push('/mis-recetas/${item.id}', extra: item.recetaPropia);
          } else {
            context.push('/remedy/${item.id}');
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
                        if (item.esColeccion)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.warmGrayCard,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Colección',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.warmGraySubtitle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (item.tipoPreparacion.isNotEmpty ||
                        item.esPropia ||
                        item.esColeccion)
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
