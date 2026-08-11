import 'package:flutter/material.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../../core/constants/app_constants.dart';

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
