import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../presentation/providers/biblioteca_provider.dart';
import '../../../presentation/widgets/premium/premium_dialog.dart';
import '../../biblioteca/domain/coleccion.dart';
import 'widgets/coleccion_visual.dart';

/// Recetas de una colección. Si el usuario no tiene acceso (ni premium
/// ni el pack de la colección) muestra el muro con CTA de compra —
/// reutiliza showPremiumDialog con `sistemaId` = la colección (el
/// "Desbloquear sistema" compra el pack 'yuyo_pack_<coleccionId>').
class ColeccionScreen extends StatelessWidget {
  final String coleccionId;

  const ColeccionScreen({super.key, required this.coleccionId});

  @override
  Widget build(BuildContext context) {
    final biblioteca = context.watch<BibliotecaProvider>();
    final coleccion = _buscarColeccion(biblioteca);
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
              context.go('/biblioteca');
            }
          },
        ),
        title: Text(
          coleccion?.nombre ?? 'Colección',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: coleccion == null
          ? _buildNoEncontrada(context)
          : !acceso
              ? _buildMuro(context, coleccion)
              : _buildListaRecetas(context, coleccion),
    );
  }

  Coleccion? _buscarColeccion(BibliotecaProvider biblioteca) {
    for (final c in biblioteca.catalogo) {
      if (c.id == coleccionId) return c;
    }
    return null;
  }

  Widget _buildNoEncontrada(BuildContext context) {
    return const Center(
      child: Text(
        'Colección no encontrada',
        style: TextStyle(color: AppConstants.textSecondary),
      ),
    );
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
          const SizedBox(height: 40),
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
          Text(
            coleccion.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Esta colección no está desbloqueada. Comprá el pack '
            'para descargarla, o con Premium ya la tenés.',
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
              precio == null
                  ? 'Desbloquear'
                  : 'Desbloquear · $precio',
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

  Widget _buildListaRecetas(BuildContext context, Coleccion coleccion) {
    final accent = colorDeColeccion(coleccion.color);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorFondoDeColeccion(coleccion.color),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderLight, width: 0.5),
          ),
          child: Text(
            coleccion.descripcion,
            style: const TextStyle(
              fontSize: 13,
              color: AppConstants.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final rc in coleccion.recetas)
          _buildRecetaCard(context, coleccion, rc, accent),
      ],
    );
  }

  Widget _buildRecetaCard(
    BuildContext context,
    Coleccion coleccion,
    RecetaColeccion rc,
    Color accent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '/biblioteca/${coleccion.id}/${rc.receta.id}',
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(iconoDeColeccion(coleccion.icono), size: 22, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rc.receta.nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rc.receta.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                TablerIcons.chevron_right,
                size: 18,
                color: AppConstants.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
