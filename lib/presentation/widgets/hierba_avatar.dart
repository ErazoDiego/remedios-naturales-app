import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Avatar de hierba medicinal (rectangular, como recetas y sistemas).
///
/// Carga la imagen `assets/images/hierbas/<id>.webp` (mismo patrón que
/// recetas y sistemas). Si el asset no existe todavía (hierba sin imagen),
/// muestra un rectángulo con la inicial del nombre — el layout NUNCA se rompe.
class HierbaAvatar extends StatelessWidget {
  const HierbaAvatar({
    super.key,
    required this.hierbaId,
    required this.nombre,
    this.size = 44,
  });

  /// Id de la hierba (define el nombre del archivo webp).
  final String hierbaId;

  /// Nombre de la hierba (inicial del fallback).
  final String nombre;

  /// Lado del recuadro. Lista/grid: 44.
  final double size;

  /// Ruta canónica del asset: `assets/images/hierbas/<id>.webp`.
  static String assetDe(String hierbaId) =>
      'assets/images/hierbas/$hierbaId.webp';

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppConstants.backgroundCream,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        _inicial,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: AppConstants.sageGreenTitle,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          assetDe(hierbaId),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }

  String get _inicial {
    final t = nombre.trim();
    if (t.isEmpty) return '?';
    return t.substring(0, 1).toUpperCase();
  }
}