import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/payments/premium_rules.dart';
import '../../../data/models/hierba.dart';
import '../../providers/hierbas_provider.dart';
import '../../providers/premium_provider.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/loading_error_empty.dart';
import '../../widgets/premium/premium_dialog.dart';

/// Pantalla de detalle de una hierba del herbolario
/// Muestra nombre, propiedades, tags y recetas que la contienen
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
      await provider.loadRecetasConHierba(hierba.first.nombre);
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
              onPressed: () => context.pop(),
            ),
            title: Text(
              hierba?.nombre ?? 'Hierba',
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

  Widget _buildDetail(dynamic hierba, HierbasProvider provider) {
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
          // CABECERA: icono + nombre + tags
          // ═══════════════════════════════════════════════════════════
          Container(
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundCream,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    TablerIcons.leaf,
                    size: 30,
                    color: AppConstants.sageGreenTitle,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hierba.nombre as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: (hierba.tags as List).map((tag) {
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
                        provider.tagLabel(tag as String),
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
          ),

          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════════════
          // PROPIEDADES
          // ═══════════════════════════════════════════════════════════
          const Text(
            'Propiedades medicinales',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimary,
            ),
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
            child: Text(
              hierba.propiedades as String,
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
                height: 1.5,
              ),
            ),
          ),

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
          Text(
            provider.recetasConHierba.isEmpty
                ? 'Esta hierba no aparece en ninguna receta de la app'
                : _contadorRecetas(
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
              child: const Text(
                'Consultá en el herbolario tradicional. '
                'Esta hierba es parte del conocimiento popular '
                'y aún no está integrada en nuestras recetas.',
                style: TextStyle(
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
        ],
      ),
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
    dynamic hierba,
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
    final nombreHierba = hierba.nombre as String;
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
