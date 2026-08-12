import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../presentation/providers/biblioteca_provider.dart';
import '../../../presentation/widgets/premium/premium_dialog.dart';
import '../../biblioteca/domain/coleccion.dart';
import 'widgets/coleccion_visual.dart';

/// Recetas de una colección.
///
/// Sin acceso (ni premium ni el pack de la colección) muestra una
/// VISTA PREVIA: el "índice del libro" con las recetas candadas
/// (lock ámbar, como las recetas premium del núcleo) + banner de
/// compra arriba. Ver el índice antes de pagar ayuda a decidir.
///
/// Con acceso: lista normal que navega al detalle.
///
/// El desbloqueo reutiliza showPremiumDialog con `sistemaId` = la
/// colección (el "Desbloquear sistema" compra 'yuyo_pack_<coleccionId>').
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
              ? _buildVistaPrevia(context, coleccion)
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

  /// Vista previa (sin acceso): header de la colección + banner de
  /// compra + índice de recetas con candado. Es el "índice del libro":
  /// se ve qué contiene antes de pagar.
  Widget _buildVistaPrevia(BuildContext context, Coleccion coleccion) {
    final biblioteca = context.read<BibliotecaProvider>();
    final precio = biblioteca.precio(coleccionId);
    final accent = colorDeColeccion(coleccion.color);
    final background = colorFondoDeColeccion(coleccion.color);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ─── Header de la colección ───
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconoDeColeccion(coleccion.icono),
                size: 28,
                color: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coleccion.nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  Text(
                    '${coleccion.recetas.length} recetas',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          coleccion.descripcion,
          style: const TextStyle(
            fontSize: 13,
            color: AppConstants.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // ─── Banner de desbloqueo ───
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppConstants.sageGreenCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderLight, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta colección no está desbloqueada. Comprá el pack '
                'para descargarla, o con Premium ya la tenés.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
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
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Índice de recetas (candadas) ───
        for (final rc in coleccion.recetas)
          _buildRecetaCard(context, coleccion, rc, accent, bloqueada: true),
      ],
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
          _buildRecetaCard(context, coleccion, rc, accent, bloqueada: false),
      ],
    );
  }

  /// Card de receta — mismo layout que el listado de un sistema del
  /// núcleo (category_screen): imagen 72x72 + badge de preparación +
  /// título + tags "ideal para" + chevron/candado.
  ///
  /// La imagen se muestra siempre (bloqueada o no, como el núcleo); el
  /// bloqueo se comunica con el candado del lado derecho.
  Widget _buildRecetaCard(
    BuildContext context,
    Coleccion coleccion,
    RecetaColeccion rc,
    Color accent, {
    required bool bloqueada,
  }) {
    final tipo = rc.receta.tipoPreparacion.isNotEmpty
        ? rc.receta.tipoPreparacion
        : rc.receta.tipo;
    final preparacionStyle = AppConstants.getPreparacionStyle(tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (bloqueada) {
            showPremiumDialog(
              context,
              message:
                  'Desbloqueá "${coleccion.nombre}" para leer '
                  '"${rc.receta.nombre}" y el resto de sus recetas.',
              sistemaId: coleccionId,
            );
            return;
          }
          context.push(
            '/biblioteca/${coleccion.id}/${rc.receta.id}',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Imagen (siempre si la receta tiene; el bloqueo se
              // comunica con el candado del lado derecho, como el núcleo) ───
              _buildThumbReceta(rc, preparacionStyle),
              const SizedBox(width: 14),

              // ─── Columna de texto (badge + título + tags) ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de tipo de preparación.
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

                    // Título de la receta (envuelve en 2 líneas).
                    Text(
                      rc.receta.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),

                    // Tags "ideal para" — máx 3 visibles.
                    if (rc.receta.idealPara.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: rc.receta.idealPara.take(3).map((condicion) {
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

              // ─── Chevron de navegación / candado premium ───
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 16),
                child: bloqueada
                    ? const Icon(
                        TablerIcons.lock,
                        size: 18,
                        color: AppConstants.alertAmber,
                      )
                    : const Icon(
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

  /// Thumbnail 72x72 de la receta — mismo comportamiento que el listado
  /// del núcleo (category_screen): la imagen se muestra SIEMPRE que la
  /// receta la tenga, esté bloqueada o no. El bloqueo se comunica con el
  /// candado del lado derecho (lock/chevron), nunca ocultando la foto.
  /// Si no hay imagen o el asset falla → placeholder de color con el
  /// ícono de la preparación (mismo fallback que el núcleo).
  Widget _buildThumbReceta(
    RecetaColeccion rc,
    PreparacionStyle preparacionStyle,
  ) {
    final Widget colorPlaceholder = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: preparacionStyle.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        preparacionStyle.icon,
        size: 28,
        color: preparacionStyle.fg,
      ),
    );

    final imagen = rc.receta.imagen;
    if (imagen == null || imagen.isEmpty) return colorPlaceholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        imagen,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => colorPlaceholder,
      ),
    );
  }
}
