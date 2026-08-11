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
/// debug vía MockPaymentService). Si una colección ya se tiene
/// (premium o pack), se muestra como descargada/incluida.
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
          ? const _TiendaVacia()
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
                  'Comprás una vez y queda asociada a tu cuenta. '
                  'Premium ya incluye todo.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppConstants.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                for (final coleccion in biblioteca.catalogo)
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
    final background = colorFondoDeColeccion(coleccion.color);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    iconoDeColeccion(coleccion.icono),
                    size: 26,
                    color: accent,
                  ),
                ),
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
                    laTiene
                        ? _estadoComprada(context)
                        : precio == null
                            ? 'Disponible'
                            : precio,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: laTiene
                          ? AppConstants.sageGreenTitle
                          : AppConstants.textPrimary,
                    ),
                  ),
                ),
                if (laTiene)
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
    );
  }

  String _estadoComprada(BuildContext context) {
    final biblioteca = context.read<BibliotecaProvider>();
    return biblioteca.puedeAcceder(coleccion.id) &&
            !biblioteca.coleccionesDescargadas.contains(coleccion.id)
        ? 'Incluida en Premium'
        : 'Descargada';
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
  const _TiendaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              TablerIcons.shopping_cart_off,
              size: 44,
              color: AppConstants.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              'La tienda no tiene colecciones disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
