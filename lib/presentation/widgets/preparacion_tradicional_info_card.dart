import 'package:flutter/material.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../core/constants/app_constants.dart';

/// Tarjeta informativa colapsable "Preparación tradicional" del herbolario.
/// Contiene las notas generales del usuario:
/// - Métodos básicos (Infusión / Decocción / Maceración)
/// - Combinaciones tradicionales (mates de yuyos)
/// - Variación de nombres populares según la región
///
/// Es contenido de referencia, no recetas — por eso vive en el herbolario
/// y no en las fichas de hierba individuales.
class PreparacionTradicionalInfoCard extends StatefulWidget {
  const PreparacionTradicionalInfoCard({super.key});

  @override
  State<PreparacionTradicionalInfoCard> createState() =>
      _PreparacionTradicionalInfoCardState();
}

class _PreparacionTradicionalInfoCardState
    extends State<PreparacionTradicionalInfoCard> {
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.borderLight,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expandida = !_expandida),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
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
                        TablerIcons.teapot,
                        size: 20,
                        color: AppConstants.sageGreenTitle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preparación tradicional',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Infusión · Decocción · Maceración',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expandida ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        TablerIcons.chevron_down,
                        size: 18,
                        color: AppConstants.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: const _ContenidoInfo(),
              crossFadeState: _expandida
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenidoInfo extends StatelessWidget {
  const _ContenidoInfo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppConstants.borderLight),
          const SizedBox(height: 12),
          const _BloqueMetodos(),
          const _Seccion(
            titulo: 'Combos tradicionales',
            icono: TablerIcons.coffee,
            texto:
                'Muchas de estas hierbas se combinan tradicionalmente en '
                '"mates de yuyos" o composiciones digestivas y hepáticas. '
                'Por ejemplo, achicoria + alcachofa + amargón + cardo '
                'mariano es una combinación clásica hepatoprotectora.',
          ),
          const _Seccion(
            titulo: 'Ojo con los nombres',
            icono: TablerIcons.info_circle,
            texto:
                'Algunos nombres populares (mil hombres, yerba carnicera, '
                'yerba del pollo, romerillo, té del burro) varían de especie '
                'según la región de Argentina/Latinoamérica. Confirmá la '
                'especie botánica exacta antes de preparar, especialmente si '
                'hay antecedentes de embarazo, lactancia o tratamiento '
                'médico en curso.',
          ),
        ],
      ),
    );
  }
}

/// Bloques de métodos básicos con descripción breve
class _BloqueMetodos extends StatelessWidget {
  const _BloqueMetodos();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Metodo(
          etiqueta: 'Infusión',
          descripcion:
              'Para hojas y flores delicadas: se vierte agua recién hervida '
              'sobre la planta y se tapa unos minutos.',
        ),
        const SizedBox(height: 8),
        const _Metodo(
          etiqueta: 'Decocción',
          descripcion:
              'Para raíces, cortezas y semillas duras: se hierven '
              'directamente unos minutos.',
        ),
        const SizedBox(height: 8),
        const _Metodo(
          etiqueta: 'Maceración',
          descripcion:
              'Extracción en frío: la planta reposa en agua o alcohol por '
              'horas, sin calor.',
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _Metodo extends StatelessWidget {
  final String etiqueta;
  final String descripcion;

  const _Metodo({required this.etiqueta, required this.descripcion});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          TablerIcons.droplet,
          size: 14,
          color: AppConstants.sageGreenTitle,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$etiqueta: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                TextSpan(
                  text: descripcion,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final String texto;

  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 14, color: AppConstants.sageGreenTitle),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              color: AppConstants.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}