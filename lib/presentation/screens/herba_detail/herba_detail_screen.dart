import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/payments/premium_rules.dart';
import '../../../data/models/hierba.dart';
import '../../../data/models/preparacion_tradicional.dart';
import '../../providers/hierbas_provider.dart';
import '../../providers/premium_provider.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/hierba_avatar.dart';
import '../../widgets/loading_error_empty.dart';
import '../../widgets/premium/premium_dialog.dart';

/// Pantalla de detalle de una hierba del herbolario.
///
/// Ficha enriquecida (Fase A del herbolario): identificación botánica,
/// uso tradicional (sin claims terapéuticos), precauciones, aviso de
/// multiespecie, preparación tradicional y recetas que la contienen.
class HerbaDetailScreen extends StatefulWidget {
  final String herbaId;

  const HerbaDetailScreen({super.key, required this.herbaId});

  @override
  State<HerbaDetailScreen> createState() => _HerbaDetailScreenState();
}

class _HerbaDetailScreenState extends State<HerbaDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final provider = context.read<HierbasProvider>();
    if (provider.hierbas.isEmpty) {
      await provider.loadHierbas();
    }
    final hierba = provider.hierbas
        .where((h) => h.id == widget.herbaId)
        .toList();

    if (hierba.isNotEmpty) {
      await provider.loadRecetasConHierba(hierba.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HierbasProvider>(
      builder: (context, provider, child) {
        // Buscar la hierba por ID en la lista cargada
        Hierba? hierba;
        for (final h in provider.hierbas) {
          if (h.id == widget.herbaId) {
            hierba = h;
            break;
          }
        }

        return Scaffold(
          backgroundColor: AppConstants.backgroundCream,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(TablerIcons.arrow_left),
              onPressed: () {
                // Defensivo: si llegaron por go()/deep link sin pila,
                // pop() haría nada y la pantalla quedaría pegada (bug de
                // testers). Con pila → pop; sin pila → herbolario.
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/herbolario');
                }
              },
            ),
            title: Text(
              hierba?.tituloVisible ?? 'Hierba',
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppConstants.headerBeige,
            foregroundColor: AppConstants.textPrimary,
          ),
          body: Column(
            children: [
              Expanded(
                child: LoadingErrorEmpty(
                  isLoading: provider.isLoading && hierba == null,
                  error: provider.error,
                  isEmpty: hierba == null,
                  emptyMessage: 'Hierba no encontrada',
                  child: hierba != null ? _buildDetail(hierba, provider) : null,
                ),
              ),
              // Banner publicitario (si el usuario no es premium)
              const BannerAdWidget(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetail(Hierba hierba, HierbasProvider provider) {
    // Gating del plan FREE: las recetas fuera del muestreo gratis (5 por
    // sistema) muestran candado en la ficha de la hierba y el callout
    // único de desbloqueo (mismo patrón que search_result_card).
    final premium = context.watch<PremiumProvider>();
    final recetas = provider.recetasConHierba;
    final bloqueadas = recetas
        .where((item) =>
            !premium.puedeAccederAReceta((item['receta'] as dynamic).id))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════
          // HERO IMAGE: banner panorámico si la hierba tiene imagen.
          // Mismo patrón que las recetas; si el asset no existe aún,
          // no pinta nada y la cabecera queda como siempre.
          // ═══════════════════════════════════════════════════════════
          if (hierba.imagen != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child: Image.asset(
                  HierbaAvatar.assetDe(hierba.id),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          const SizedBox(height: 12),
          // ═══════════════════════════════════════════════════════════
          // CABECERA: icono + nombre + tags
          // ═══════════════════════════════════════════════════════════
          _buildCabecera(hierba, provider),

          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════════════
          // IDENTIFICACIÓN (dato botánico, educativo)
          // ═══════════════════════════════════════════════════════════
          _buildIdentificacion(hierba),

          // ═══════════════════════════════════════════════════════════
          // AVISO DE NOMBRE COMÚN AMBIGUO (honestidad taxonómica)
          // ═══════════════════════════════════════════════════════════
          if (hierba.esMultiespecie) ...[
            const SizedBox(height: 16),
            _buildAvisoIdentificacion(hierba),
          ],

          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════════════
          // USO TRADICIONAL (ex "Propiedades medicinales")
          // ═══════════════════════════════════════════════════════════
          _buildUsoTradicional(hierba),

          // ═══════════════════════════════════════════════════════════
          // PREPARACIÓN TRADICIONAL (si existe para esta hierba)
          // ═══════════════════════════════════════════════════════════
          if (provider.preparacionDe(hierba.id) != null) ...[
            const SizedBox(height: 20),
            _buildPreparacionTradicional(
              provider.preparacionDe(hierba.id)!,
            ),
          ],

          // ═══════════════════════════════════════════════════════════
          // PRECAUCIÓN (contraindicaciones / advertencias)
          // ═══════════════════════════════════════════════════════════
          if (hierba.precauciones != null &&
              hierba.precauciones!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildPrecaucion(hierba),
          ],

          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════════════════
          // RECETAS QUE LA CONTIENEN
          // ═══════════════════════════════════════════════════════════
          Text(
            'Recetas con ${hierba.nombre}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (provider.recetasConHierba.isNotEmpty)
            Text(
              _contadorRecetas(
                provider.recetasConHierba.length,
                bloqueadas.length,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppConstants.textTertiary,
              ),
            ),
          const SizedBox(height: 10),
          if (provider.recetasConHierba.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.borderLight,
                  width: 0.5,
                ),
              ),
              child: Text(
                provider.preparacionDe(hierba.id) != null
                    ? 'Esta hierba no aparece en las recetas de la app — '
                        'su preparación tradicional está arriba.'
                    : 'Consultá en el herbolario tradicional. '
                        'Esta hierba es parte del conocimiento popular '
                        'y aún no está integrada en nuestras recetas.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppConstants.textSecondary,
                  height: 1.4,
                ),
              ),
            )
          else ...[
            ...recetas.map((item) {
              final receta = item['receta'] as dynamic;
              final sistemaId = item['sistemaId'] as String;
              return _buildRecetaTile(receta, sistemaId, premium);
            }),
            // Callout ÚNICO de desbloqueo (regla de densidad: un solo CTA
            // de compra por pantalla, en el momento de mayor intención —
            // el usuario ya está leyendo sobre la hierba que necesita).
            if (bloqueadas.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDesbloquearCallout(hierba, bloqueadas, premium),
            ],
          ],

          // ═══════════════════════════════════════════════════════════
          // FUENTES + disclaimer educativo
          // ═══════════════════════════════════════════════════════════
          const SizedBox(height: 24),
          _buildFuentes(hierba),
        ],
      ),
    );
  }

  /// Cabecera: chips de tags visibles.
  /// (El nombre ya vive en el AppBar y el hero image; el círculo y el
  /// texto repetido se quitaron por pedido del usuario.)
  Widget _buildCabecera(Hierba hierba, HierbasProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: hierba.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.sageGreenCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  provider.tagLabel(tag),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.sageGreenTitle,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Sección "Identificación": nombre científico, familia, origen y
  /// rasgos visuales. Puro dato botánico — sin claims terapéuticos.
  Widget _buildIdentificacion(Hierba hierba) {
    final cientifico = hierba.nombreCientifico;
    final familia = hierba.familia;
    final origen = hierba.origenDistribucion;
    final reconocer = hierba.comoReconocerla;

    if (cientifico == null &&
        familia == null &&
        origen == null &&
        reconocer == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              TablerIcons.flower,
              size: 18,
              color: AppConstants.sageGreenTitle,
            ),
            const SizedBox(width: 8),
            const Text(
              'Identificación',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.borderLight,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cientifico != null) ...[
                Text(
                  cientifico,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (familia != null) ...[
                _buildInfoFila(
                  icono: TablerIcons.leaf,
                  texto: 'Familia: $familia',
                ),
                const SizedBox(height: 6),
              ],
              if (origen != null) ...[
                _buildInfoFila(
                  icono: TablerIcons.point,
                  texto: origen,
                ),
                const SizedBox(height: 6),
              ],
              if (reconocer != null) ...[
                _buildInfoFila(
                  icono: TablerIcons.eye,
                  texto: reconocer,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Aviso cuando el nombre común agrupa varias especies según la región.
  /// Honestidad taxonómica: no afirmamos una especie que no es.
  Widget _buildAvisoIdentificacion(Hierba hierba) {
    final mensaje = switch (hierba.tipoIdentificacion) {
      TipoIdentificacion.nombreComunMultiespecie =>
        'Este nombre agrupa varias especies según la región. '
            'Verificá qué especie corresponde en tu país.',
      TipoIdentificacion.varianteRegional =>
        'Variante regional: el nombre comercial puede referir '
            'a otra especie según el país.',
      TipoIdentificacion.productoProcesado =>
        'Producto procesado: la presentación comercial '
            'difiere de la planta fresca.',
      TipoIdentificacion.especieDefinida => '',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.alertAmberBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.alertAmber.withValues(alpha: 0.3),
        ),
      ),
      child: _buildInfoFila(
        icono: TablerIcons.info_circle,
        color: AppConstants.alertAmber,
        texto: mensaje,
      ),
    );
  }

  /// Sección "Uso tradicional": el texto revisado de la tabla maestra.
  /// Se presenta como tradición, nunca como eficacia clínica.
  Widget _buildUsoTradicional(Hierba hierba) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              TablerIcons.history,
              size: 18,
              color: AppConstants.sageGreenTitle,
            ),
            const SizedBox(width: 8),
            const Text(
              'Uso tradicional',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.borderLight,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hierba.parteUtilizada != null &&
                  hierba.parteUtilizada!.isNotEmpty) ...[
                _buildModoChip(hierba.parteUtilizada!, icono: TablerIcons.leaf),
                const SizedBox(height: 10),
              ],
              Text(
                hierba.usoTradicional,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Sección "Precaución": contraindicaciones o advertencias.
  /// Ámbar para precauciones; rojo para riesgo crítico.
  Widget _buildPrecaucion(Hierba hierba) {
    final esCritico = hierba.nivelRiesgo == RiesgoHerba.critico;
    final color = esCritico ? AppConstants.alertRed : AppConstants.alertAmber;
    final fondo = esCritico
        ? AppConstants.alertRed.withValues(alpha: 0.06)
        : AppConstants.alertAmberBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              TablerIcons.alert_triangle,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              esCritico ? 'Advertencia importante' : 'Precaución',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: _buildInfoFila(
            icono: TablerIcons.alert_triangle,
            color: color,
            texto: hierba.precauciones!,
          ),
        ),
      ],
    );
  }

  /// Pie de ficha: fuentes institucionales + disclaimer educativo.
  Widget _buildFuentes(Hierba hierba) {
    final dominios = hierba.fuentes
        .map((url) {
          try {
            final uri = Uri.parse(url);
            return uri.host.replaceFirst('www.', '');
          } catch (_) {
            return url;
          }
        })
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dominios.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                TablerIcons.book,
                size: 16,
                color: AppConstants.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Fuentes: ${dominios.join(' · ')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.warmGrayCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Contenido educativo. La información de esta ficha no '
            'reemplaza la consulta con un profesional de la salud.',
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textTertiary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// Sección "Preparación tradicional" de la ficha de hierba: modos como
  /// etiquetas, texto literal del herbolario, dosis y advertencia específica.
  Widget _buildPreparacionTradicional(PreparacionTradicional preparacion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              TablerIcons.teapot,
              size: 18,
              color: AppConstants.sageGreenTitle,
            ),
            const SizedBox(width: 8),
            const Text(
              'Preparación tradicional',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Parte usada + modos como etiquetas
        if (preparacion.modos.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (preparacion.parte.isNotEmpty)
                _buildModoChip(preparacion.parte, icono: TablerIcons.leaf),
              ...preparacion.modos.map(
                (modo) => _buildModoChip(modo, icono: TablerIcons.flask),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.borderLight,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preparacion.texto,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                  height: 1.5,
                ),
              ),
              if (preparacion.dosis.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildInfoFila(
                  icono: TablerIcons.clock,
                  texto: 'Tomar ${preparacion.dosis.toLowerCase()}',
                ),
              ],
            ],
          ),
        ),
        if (preparacion.advertencia.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.alertAmberBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.alertAmber.withValues(alpha: 0.3),
              ),
            ),
            child: _buildInfoFila(
              icono: TablerIcons.alert_triangle,
              color: AppConstants.alertAmber,
              texto: preparacion.advertencia,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModoChip(String etiqueta, {required IconData icono}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppConstants.sageGreenCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: AppConstants.sageGreenTitle),
          const SizedBox(width: 4),
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstants.sageGreenTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFila({
    required IconData icono,
    required String texto,
    Color color = AppConstants.textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              color: color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecetaTile(
    dynamic receta,
    String sistemaId,
    PremiumProvider premium,
  ) {
    final bloqueada = !premium.puedeAccederAReceta(receta.id as String);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          if (bloqueada) {
            // Candado pasivo → el CTA vive en el diálogo (mismo patrón
            // que search_result_card: no navega, abre el muro).
            showPremiumDialog(
              context,
              title: 'Receta Premium',
              message: 'Esta receta forma parte de Yuyo Premium. '
                  'Con el plan gratis tenés acceso a 5 recetas '
                  'de cada sistema.',
              sistemaId: sistemaId,
            );
            return;
          }
          context.push('/remedy/${receta.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.borderLight,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.backgroundCream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  TablerIcons.soup,
                  size: 20,
                  color: AppConstants.sageGreenTitle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receta.nombre as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ideal para: ${(receta.idealPara as List).take(2).join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              bloqueada
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
            ],
          ),
        ),
      ),
    );
  }

  /// Contador honesto de recetas: "2 recetas, 1 premium" cuando hay
  /// bloqueadas (no dice "disponibles" si no lo están).
  String _contadorRecetas(int total, int premium) {
    final recetasTxt = '$total receta${total == 1 ? '' : 's'}';
    if (premium == 0) return '$recetasTxt disponible${total == 1 ? '' : 's'}';
    return '$recetasTxt, $premium premium';
  }

  /// Callout ÚNICO de desbloqueo al final de la ficha de la hierba.
  ///
  /// Ofrece el pack del sistema más representado entre las recetas
  /// bloqueadas (mismo `showPremiumDialog` que el resto de la app, con
  /// la compra directa del pack + opción Premium).
  Widget _buildDesbloquearCallout(
    Hierba hierba,
    List<Map<String, dynamic>> bloqueadas,
    PremiumProvider premium,
  ) {
    // Sistema con más recetas bloqueadas (si hay varios, el diálogo
    // ofrece además Premium completo como alternativa).
    final conteo = <String, int>{};
    for (final item in bloqueadas) {
      final sid = item['sistemaId'] as String;
      conteo[sid] = (conteo[sid] ?? 0) + 1;
    }
    var sistemaPrincipal = conteo.keys.first;
    var maximo = 0;
    conteo.forEach((sid, cantidad) {
      if (cantidad > maximo) {
        maximo = cantidad;
        sistemaPrincipal = sid;
      }
    });

    final total = bloqueadas.length;
    final nombreHierba = hierba.nombre;
    final packId = PremiumRules.packIdDeSistema(sistemaPrincipal);
    final precio = premium.priceFor(packId);

    return Material(
      color: AppConstants.alertAmberBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => showPremiumDialog(
          context,
          title: 'Recetas premium',
          message: 'Hay $total receta${total == 1 ? '' : 's'} premium '
              'con $nombreHierba. Desbloqueá '
              '${AppConstants.sistemasNombres[sistemaPrincipal] ?? sistemaPrincipal} '
              'o sumate a Yuyo Premium.',
          sistemaId: sistemaPrincipal,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.alertAmber.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                TablerIcons.lock,
                size: 20,
                color: AppConstants.alertAmber,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total receta${total == 1 ? '' : 's'} premium '
                      'con $nombreHierba',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      precio == null
                          ? 'Desbloquear sistema'
                          : 'Desbloquear sistema · $precio',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.alertAmber,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                TablerIcons.chevron_right,
                size: 18,
                color: AppConstants.alertAmber,
              ),
            ],
          ),
        ),
      ),
    );
  }
}