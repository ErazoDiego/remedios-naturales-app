import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/receta_usuario.dart';
import '../../providers/mis_recetas_provider.dart';

/// Pantalla "Mis Recetas": lista de recetas propias del usuario (premium).
///
/// - FAB "+" para crear.
/// - Tap en una card → detalle.
/// - Menú de cada card → editar / eliminar (con confirmación).
class MisRecetasScreen extends StatefulWidget {
  const MisRecetasScreen({super.key});

  @override
  State<MisRecetasScreen> createState() => _MisRecetasScreenState();
}

class _MisRecetasScreenState extends State<MisRecetasScreen> {
  @override
  void initState() {
    super.initState();
    // Carga diferida: espera a que el provider esté disponible en build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MisRecetasProvider>().load();
    });
  }

  Future<void> _confirmDelete(RecetaUsuario receta) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          TablerIcons.trash,
          size: 36,
          color: AppConstants.alertRed,
        ),
        title: const Text('Eliminar receta'),
        content: Text(
          '¿Seguro que querés eliminar "${receta.nombre}"?\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.alertRed,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<MisRecetasProvider>();
    final ok = await provider.eliminar(receta.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Receta eliminada' : (provider.error ?? 'Error')),
        backgroundColor: ok ? AppConstants.sageGreenTitle : AppConstants.alertRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MisRecetasProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.notes, size: 20),
            SizedBox(width: 8),
            Text('Mis recetas'),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      floatingActionButton: provider.isLoggedIn
          ? FloatingActionButton(
              onPressed: () => context.push('/mis-recetas/nueva'),
              backgroundColor: AppConstants.sageGreenTitle,
              foregroundColor: Colors.white,
              tooltip: 'Nueva receta',
              child: const Icon(TablerIcons.plus),
            )
          : null,
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(MisRecetasProvider provider) {
    // Sin sesión: la feature premium requiere cuenta
    if (!provider.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                TablerIcons.lock,
                size: 48,
                color: AppConstants.sageGreenTitle,
              ),
              const SizedBox(height: 16),
              const Text(
                'Iniciá sesión para guardar tus propias recetas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    // Primer carga
    if (provider.isLoading && provider.recetas.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppConstants.sageGreenTitle,
          strokeWidth: 2,
        ),
      );
    }

    // Error sin datos cargados
    if (provider.error != null && provider.recetas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                TablerIcons.cloud_off,
                size: 48,
                color: AppConstants.alertAmber,
              ),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.read<MisRecetasProvider>().load(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Vacío
    if (provider.recetas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                TablerIcons.notes_off,
                size: 48,
                color: AppConstants.sageGreenTitle,
              ),
              const SizedBox(height: 16),
              const Text(
                'Todavía no creaste recetas propias',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tocá el botón + para crear tu primera receta '
                'personalizada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
      itemCount: provider.recetas.length,
      itemBuilder: (context, index) {
        final receta = provider.recetas[index];
        return _buildRecipeCard(receta);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CARD — misma estructura que CategoryScreen
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRecipeCard(RecetaUsuario receta) {
    final tipo = receta.tipoPreparacion.isNotEmpty
        ? receta.tipoPreparacion
        : receta.tipo;
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
        onTap: () => context.push(
          '/mis-recetas/${receta.id}',
          extra: receta,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Placeholder de color por tipo de preparación ───
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 72,
                  height: 72,
                  color: preparacionStyle.bg,
                  child: Icon(
                    preparacionStyle.icon,
                    size: 32,
                    color: preparacionStyle.fg,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // ─── Texto: badge + nombre + descripción ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      receta.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),
                    if (receta.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        receta.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppConstants.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ─── Menú: editar / eliminar ───
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push(
                      '/mis-recetas/${receta.id}/editar',
                      extra: receta,
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(receta);
                  }
                },
                icon: const Icon(
                  TablerIcons.dots_vertical,
                  size: 18,
                  color: AppConstants.textTertiary,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(TablerIcons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          TablerIcons.trash,
                          size: 16,
                          color: AppConstants.alertRed,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Eliminar',
                          style: TextStyle(color: AppConstants.alertRed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
