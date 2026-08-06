import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/recetas_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading_error_empty.dart';

/// Pantalla principal - Muestra los 10 sistemas corporales
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecetasProvider>().loadSistemas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final sistemas = context.read<RecetasProvider>().sistemas;
    final queryLower = query.toLowerCase();
    List<Map<String, dynamic>> matches = [];

    for (final sistema in sistemas) {
      if (sistema.nombre.toLowerCase().contains(queryLower) ||
          sistema.id.toLowerCase().contains(queryLower)) {
        matches.add({
          'id': sistema.id,
          'title': sistema.nombre,
          'subtitle': '${sistema.totalRecetas} recetas',
          'isSistema': true,
        });
      }
      for (final receta in sistema.recetas) {
        if (receta.nombre.toLowerCase().contains(queryLower) ||
            receta.idealPara.any((c) => c.toLowerCase().contains(queryLower))) {
          matches.add({
            'id': receta.id,
            'title': receta.nombre,
            'subtitle': 'Ideal para: ${receta.idealPara.join(", ")}',
            'isSistema': false,
          });
        }
      }
    }

    setState(() => _searchResults = matches.take(10).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════
          // HEADER - Beige neutro, sin gradiente
          // ═══════════════════════════════════════════════════════════
          Container(
            color: AppConstants.headerBeige,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título con ícono de hoja + avatar de usuario arriba a la derecha
                    Stack(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TablerIcons.leaf,
                              size: 24,
                              color: AppConstants.sageGreenTitle,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Remedios Naturales',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: _buildProfileButton(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: const Text(
                        'Tu guía de bienestar natural',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ═══════════════════════════════════════════════════
                    // BUSCADOR - Fondo blanco, borde fino gris
                    // ═══════════════════════════════════════════════════
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _performSearch,
                      decoration: InputDecoration(
                        hintText: 'Buscar por condición, síntoma...',
                        hintStyle: const TextStyle(
                          color: AppConstants.textTertiary,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          TablerIcons.search,
                          size: 20,
                          color: AppConstants.textTertiary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  TablerIcons.x,
                                  size: 18,
                                  color: AppConstants.textTertiary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppConstants.borderLight,
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppConstants.borderLight,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppConstants.sageGreenTitle,
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 14,
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          context.go('/search?q=${Uri.encodeQueryComponent(value.trim())}');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════
          // CONTENIDO SCROLLEABLE
          // ═══════════════════════════════════════════════════════════
          Expanded(
            child: _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // RESULTADOS DE BÚSQUEDA
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final isSistema = result['isSistema'] as bool;
        
        return ListTile(
          leading: Icon(
            isSistema ? TablerIcons.category : TablerIcons.pill,
            size: 20,
            color: AppConstants.sageGreenTitle,
          ),
          title: Text(
            result['title'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textPrimary,
            ),
          ),
          subtitle: Text(
            result['subtitle'],
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
          ),
          trailing: const Icon(
            TablerIcons.chevron_right,
            size: 18,
            color: AppConstants.textTertiary,
          ),
          onTap: () {
            if (isSistema) {
              context.go('/category/${result['id']}');
            } else {
              context.go('/remedy/${result['id']}');
            }
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONTENIDO PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMainContent() {
    return Consumer<RecetasProvider>(
      builder: (context, provider, child) {
        return LoadingErrorEmpty(
          isLoading: provider.isLoading && provider.sistemas.isEmpty,
          error: provider.error,
          isEmpty: provider.sistemas.isEmpty,
          emptyMessage: 'No se encontraron sistemas',
          onRetry: () => provider.loadSistemas(),
          child: CustomScrollView(
            slivers: [
              // ═══════════════════════════════════════════════════════
              // HEADER DE SISTEMAS
              // ═══════════════════════════════════════════════════════
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    'Sistemas del cuerpo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),

              // ═══════════════════════════════════════════════════════
              // GRID DE SISTEMAS - Layout manual 2 columnas
              // ═══════════════════════════════════════════════════════
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final i = index * 2;
                      final sistema1 = provider.sistemas[i];
                      final sistema2 = i + 1 < provider.sistemas.length
                          ? provider.sistemas[i + 1]
                          : null;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < (provider.sistemas.length + 1) ~/ 2 - 1
                              ? 12
                              : 0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSistemaCard(sistema1)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: sistema2 != null
                                  ? _buildSistemaCard(sistema2)
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: (provider.sistemas.length + 1) ~/ 2,
                  ),
                ),
              ),

              // ═══════════════════════════════════════════════════════
              // ENLACES RÁPIDOS - Fondo blanco, borde fino
              // ═══════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enlaces rápidos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildProfileQuickLink(),
                      const SizedBox(height: 8),
                      _buildQuickLink(
                        icon: TablerIcons.heart,
                        title: 'Mis Favoritos',
                        subtitle: 'Recetas guardadas',
                        onTap: () => context.go('/favorites'),
                      ),
                      const SizedBox(height: 8),
                      _buildQuickLink(
                        icon: TablerIcons.book,
                        title: 'Fundamentos',
                        subtitle: 'Principios de la medicina natural',
                        onTap: () => context.go('/fundamentals'),
                      ),
                      const SizedBox(height: 8),
                      _buildQuickLink(
                        icon: TablerIcons.leaf,
                        title: 'Herbolario',
                        subtitle: 'Directorio de hierbas medicinales',
                        onTap: () => context.go('/herbolario'),
                      ),
                      const SizedBox(height: 8),
                      _buildQuickLink(
                        icon: TablerIcons.alert_triangle,
                        title: 'Seguridad',
                        subtitle: 'Precauciones importantes',
                        onTap: () => context.go('/safety'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CARD DE SISTEMA - Altura auto-calculada, 0 overflow
  // ═══════════════════════════════════════════════════════════════════
  /// Altura fija del área de texto (garantizado para 2 líneas + subtítulo)
  static const double _textAreaHeight = 90;

  Widget _buildSistemaCard(dynamic sistema) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.backgroundCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.borderLight,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.go('/category/${sistema.id}'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen del sistema
              AspectRatio(
                aspectRatio: 1 / 0.7,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/sistemas/sistema_${sistema.id}.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppConstants.backgroundCream,
                        child: Icon(
                          SystemIcons.getIcon(sistema.id),
                          size: 32,
                          color: AppConstants.textPrimary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Texto — altura fija para 2 líneas
              SizedBox(
                height: _textAreaHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        sistema.nombre,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.textPrimary,
                          letterSpacing: -0.1,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sistema.totalRecetas} recetas',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppConstants.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOTÓN DE PERFIL - arriba a la derecha del header
  // Logueado: avatar con la inicial del nombre. Anónimo: ícono simple.
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProfileButton() {
    final userProvider = context.watch<UserProvider>();
    final isLoggedIn = userProvider.isLoggedIn;
    final nombre = userProvider.profile?.nombre ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return InkWell(
      onTap: () => context.go('/profile'),
      borderRadius: BorderRadius.circular(20),
      child: Tooltip(
        message: 'Mi cuenta',
        child: isLoggedIn
            ? CircleAvatar(
                radius: 17,
                backgroundColor: AppConstants.sageGreenTitle,
                child: Text(
                  inicial,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )
            : const Icon(
                TablerIcons.user_circle,
                size: 28,
                color: AppConstants.sageGreenTitle,
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ENLACE RÁPIDO DE PERFIL - refleja estado de sesión
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProfileQuickLink() {
    final userProvider = context.watch<UserProvider>();
    final isLoggedIn = userProvider.isLoggedIn;
    final email = userProvider.userEmail ?? '';
    final nombre = userProvider.profile?.nombre ?? '';

    final title = isLoggedIn
        ? (nombre.isNotEmpty ? nombre : 'Mi cuenta')
        : 'Mi cuenta';
    final subtitle = isLoggedIn
        ? 'Sincronizado · $email'
        : 'Iniciá sesión para sincronizar tus datos';

    return _buildQuickLink(
      icon: isLoggedIn ? TablerIcons.user_circle : TablerIcons.user_plus,
      title: title,
      subtitle: subtitle,
      onTap: () => context.go('/profile'),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ENLACE RÁPIDO - Fondo blanco, borde fino, íconos Tabler
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildQuickLink({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.borderLight,
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: AppConstants.sageGreenTitle,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondary,
          ),
        ),
        trailing: const Icon(
          TablerIcons.chevron_right,
          size: 18,
          color: AppConstants.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }
}
