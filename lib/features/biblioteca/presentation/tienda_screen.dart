import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../presentation/providers/biblioteca_provider.dart';
import '../../biblioteca/domain/coleccion.dart';
import 'widgets/coleccion_visual.dart';

/// Tienda de colecciones: catálogo público con precios y compra.
///
/// Los precios vienen de la tienda (Play Console en release; fake en
/// debug vía MockPaymentService). Solo se muestran las colecciones NO
/// adquiridas ([BibliotecaProvider.tiendaVisible]): las que ya se poseen
/// (pack comprado, gratis reclamada o cubiertas por Premium) desaparecen
/// de la tienda y viven en "Mis colecciones". Si no queda nada por
/// adquirir, la tienda muestra un estado vacío con el motivo.
class TiendaScreen extends StatelessWidget {
  const TiendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final biblioteca = context.watch<BibliotecaProvider>();

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
        title: const Text(
          'Tienda',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: biblioteca.catalogo.isEmpty
          ? const _TiendaVacia(
              icono: TablerIcons.shopping_cart_off,
              mensaje: 'La tienda no tiene colecciones disponibles.',
            )
          : biblioteca.tiendaVisible.isEmpty
              ? _TiendaVacia(
                  icono: TablerIcons.check,
                  mensaje: biblioteca.esPremium
                      ? 'Ya tenés todas las colecciones con Premium.'
                      : 'Compraste todas las colecciones disponibles.',
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Colecciones nuevas para tu Yuyo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Colecciones gratis y de pago. Comprás una vez y '
                      'queda asociada a tu cuenta. Premium ya incluye todo.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppConstants.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final coleccion in biblioteca.tiendaVisible)
                      _TiendaCard(coleccion: coleccion),
                  ],
                ),
    );
  }
}

class _TiendaCard extends StatelessWidget {
  final Coleccion coleccion;

  const _TiendaCard({required this.coleccion});

  @override
  Widget build(BuildContext context) {
    final biblioteca = context.watch<BibliotecaProvider>();
    final accent = colorDeColeccion(coleccion.color);
    final esGratis = coleccion.gratis;
    final reclamada = biblioteca.esGratisReclamada(coleccion.id);
    final laTiene = biblioteca.puedeAcceder(coleccion.id);
    final precio = biblioteca.precio(coleccion.id);
    final isLoading = biblioteca.isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: InkWell(
        // La tarjeta navega al "índice" de la colección: sin acceso es
        // la vista previa con candados (ayuda a decidir la compra);
        // con acceso, la lista normal. El botón Comprar captura su
        // propio tap (no propaga la navegación).
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/biblioteca/${coleccion.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                coleccionThumb(coleccion, accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coleccion.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${coleccion.recetas.length} recetas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        coleccion.descripcion,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppConstants.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppConstants.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    esGratis
                        ? (reclamada ? 'Gratis' : 'Recetas gratis')
                        : laTiene
                            ? _estadoComprada(context)
                            : precio == null
                                ? 'Disponible'
                                : precio,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: laTiene || esGratis
                          ? AppConstants.sageGreenTitle
                          : AppConstants.textPrimary,
                    ),
                  ),
                ),
                if (esGratis && !reclamada)
                  FilledButton(
                    onPressed: isLoading ? null : () => _reclamar(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConstants.sageGreenTitle,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Gratis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (laTiene)
                  const Icon(
                    TablerIcons.check,
                    size: 18,
                    color: AppConstants.sageGreenTitle,
                  )
                else
                  FilledButton(
                    onPressed: isLoading
                        ? null
                        : () => _comprar(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConstants.sageGreenTitle,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      precio == null ? 'Comprar' : 'Comprar · $precio',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  String _estadoComprada(BuildContext context) {
    final biblioteca = context.read<BibliotecaProvider>();
    // "Descargada" solo con el PACK comprado; "Gratis" cuando la
    // colección gratuita fue reclamada; con premium sin pack es
    // "Incluida en Premium" (acceso por suscripción, no descarga).
    if (biblioteca.tienePack(coleccion.id)) return 'Descargada';
    if (coleccion.gratis) return 'Gratis';
    return 'Incluida en Premium';
  }

  Future<void> _reclamar(BuildContext context) async {
    final biblioteca = context.read<BibliotecaProvider>();
    await biblioteca.reclamarGratis(coleccion.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${coleccion.nombre} descargada en tu biblioteca',
        ),
      ),
    );
  }

  Future<void> _comprar(BuildContext context) async {
    final biblioteca = context.read<BibliotecaProvider>();
    final ok = await biblioteca.comprar(coleccion.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${coleccion.nombre} descargada en tu biblioteca'
              : 'La compra se canceló o no está disponible',
        ),
      ),
    );
  }
}

class _TiendaVacia extends StatelessWidget {
  final IconData icono;
  final String mensaje;

  const _TiendaVacia({required this.icono, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: 44,
              color: AppConstants.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
