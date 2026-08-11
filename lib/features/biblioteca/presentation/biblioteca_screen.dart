import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../presentation/providers/biblioteca_provider.dart';
import '../../biblioteca/domain/coleccion.dart';
import 'widgets/coleccion_visual.dart';

/// Pantalla Biblioteca: lo que el usuario ADQUIRIÓ (colecciones
/// descargadas) + buscador propio + entrada a la Tienda.
///
/// Cero mezcla con el buscador global del núcleo: acá se busca SOLO
/// dentro de las recetas de las colecciones descargadas.
class BibliotecaScreen extends StatefulWidget {
  const BibliotecaScreen({super.key});

  @override
  State<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends State<BibliotecaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final biblioteca = context.watch<BibliotecaProvider>();

    final descargadas = biblioteca.catalogo
        .where((c) => biblioteca.coleccionesDescargadas.contains(c.id))
        .toList();

    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        // Sin botón atrás: es una tab del bottom nav (rama del shell).
        title: const Text(
          'Biblioteca',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (descargadas.isEmpty) ...[
                  // Sin contenido: la tienda manda (promo-first).
                  _buildTiendaBanner(biblioteca),
                  const SizedBox(height: 20),

                  // ── MIS COLECCIONES (vacías) ──
                  const Row(
                    children: [
                      Icon(
                        TablerIcons.download,
                        size: 18,
                        color: AppConstants.sageGreenTitle,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Mis colecciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEmptyState(),
                ] else ...[
                  // Con contenido: el buscador es la acción primaria
                  // (search-first).

                  // ── BUSCADOR PROPIO (solo colecciones descargadas) ──
                  const Row(
                    children: [
                      Icon(
                        TablerIcons.search,
                        size: 18,
                        color: AppConstants.sageGreenTitle,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Buscar en tus colecciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Jugo, energía, defensas...',
                      prefixIcon: const Icon(
                        TablerIcons.search,
                        size: 20,
                        color: AppConstants.textTertiary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppConstants.borderLight,
                          width: 0.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppConstants.borderLight,
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty) _buildResultados(descargadas),
                  const SizedBox(height: 20),

                  // ── MIS COLECCIONES ──
                  const Row(
                    children: [
                      Icon(
                        TablerIcons.download,
                        size: 18,
                        color: AppConstants.sageGreenTitle,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Mis colecciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final coleccion in descargadas)
                    _buildColeccionCard(coleccion),
                  const SizedBox(height: 20),

                  // La tienda queda al final (promoción, no navegación).
                  _buildTiendaBanner(biblioteca),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Banner destacado que lleva a la Tienda.
  Widget _buildTiendaBanner(BibliotecaProvider biblioteca) {
    final disponibles = biblioteca.catalogo
        .where((c) => !biblioteca.coleccionesDescargadas.contains(c.id))
        .length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.sageGreenCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(
              TablerIcons.building_store,
            size: 28,
            color: AppConstants.sageGreenTitle,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tienda de colecciones',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  disponibles == 0
                      ? 'Ya tenés todo lo disponible.'
                      : '$disponibles colecciones nuevas para sumar.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/biblioteca/tienda'),
            icon: const Icon(
              TablerIcons.arrow_right,
              color: AppConstants.sageGreenTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: const Column(
        children: [
          Icon(
            TablerIcons.book_off,
            size: 32,
            color: AppConstants.textTertiary,
          ),
          SizedBox(height: 8),
          Text(
            'Todavía no tenés colecciones.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Visitá la tienda para descubrir las que hay disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColeccionCard(Coleccion coleccion) {
    final accent = colorDeColeccion(coleccion.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/biblioteca/${coleccion.id}'),
        child: Row(
          children: [
            Icon(iconoDeColeccion(coleccion.icono), size: 24, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coleccion.nombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  Text(
                    '${coleccion.recetas.length} recetas',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
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
    );
  }

  /// Resultados del buscador propio: filtra las recetas de las
  /// colecciones descargadas por nombre, descripción, idealPara y
  /// keywords (todo normalizado sin tildes/ñ).
  Widget _buildResultados(List<Coleccion> descargadas) {
    final normalizada = normalizarTexto(_query);
    final terminos = normalizada
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final resultados = <(Coleccion, RecetaColeccion)>[];
    for (final coleccion in descargadas) {
      for (final rc in coleccion.recetas) {
        final receta = rc.receta;
        final haystack = normalizarTexto([
          receta.nombre,
          receta.descripcion,
          ...receta.idealPara,
          ...rc.keywords,
        ].join(' '));
        if (terminos.every(haystack.contains)) {
          resultados.add((coleccion, rc));
        }
      }
    }

    if (resultados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Sin resultados para "$_query".',
          style: const TextStyle(
            fontSize: 13,
            color: AppConstants.textSecondary,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          for (final (coleccion, rc) in resultados)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Icon(
                iconoDeColeccion(coleccion.icono),
                color: colorDeColeccion(coleccion.color),
              ),
              title: Text(
                rc.receta.nombre,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textPrimary,
                ),
              ),
              subtitle: Text(
                coleccion.nombre,
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
              onTap: () => context.push(
                '/biblioteca/${coleccion.id}/${rc.receta.id}',
              ),
            ),
        ],
      ),
    );
  }
}
