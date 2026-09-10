import 'package:flutter/material.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/coleccion.dart';

/// Visuales de una colección según la metadata del catálogo.
/// El ícono viene como nombre (ej: 'glass-full'); el color define la
/// familia visual ('verde' | 'gris').
IconData iconoDeColeccion(String icono) {
  switch (icono) {
    case 'glass-full':
    case 'glass_full':
      return TablerIcons.glass_full;
    case 'book':
      return TablerIcons.book;
    case 'salad':
      return TablerIcons.salad;
    case 'bottle':
      return TablerIcons.bottle;
    case 'milk':
      return TablerIcons.milk;
    default:
      return TablerIcons.leaf;
  }
}

/// Color de acento de la colección (familia visual del catálogo).
Color colorDeColeccion(String color) {
  switch (color) {
    case 'gris':
      return AppConstants.warmGrayTitle;
    default:
      return AppConstants.sageGreenTitle;
  }
}

/// Fondo suave del acento (para badges y tarjetas).
Color colorFondoDeColeccion(String color) {
  switch (color) {
    case 'gris':
      return AppConstants.warmGrayCard;
    default:
      return AppConstants.sageGreenCard;
  }
}

/// Portada de la colección: thumbnail cuadrado si hay `imagen` en el
/// catálogo; si no (o si el asset falla), fallback al ícono + color de
/// la familia visual. Así las tarjetas quedan parejas siempre.
Widget coleccionThumb(Coleccion coleccion, Color accent, {double size = 72}) {
  final Widget iconoFallback = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: colorFondoDeColeccion(coleccion.color),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(
      iconoDeColeccion(coleccion.icono),
      size: size * 0.4,
      color: accent,
    ),
  );

  final imagen = coleccion.imagen;
  if (imagen == null || imagen.isEmpty) return iconoFallback;

  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.asset(
      imagen,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => iconoFallback,
    ),
  );
}
