import 'package:flutter/material.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../constants/app_constants.dart';

/// Mapa de íconos Tabler para cada sistema corporal
class SystemIcons {
  static const Map<String, IconData> icons = {
    'digestivo': TablerIcons.pill,
    'nervioso': TablerIcons.brain,
    'respiratorio': TablerIcons.lungs,
    'inmunitario': TablerIcons.shield_check,
    'cardiovascular': TablerIcons.heartbeat,
    'hormonal': TablerIcons.flower,
    'musculoesqueletico': TablerIcons.bone,
    'urinario': TablerIcons.droplet,
    'dermico': TablerIcons.face_id,
    'sensorial': TablerIcons.eye,
  };

  static IconData getIcon(String sistemaId) {
    return icons[sistemaId] ?? TablerIcons.leaf;
  }
}

/// Tema de la aplicación Remedios Naturales
class AppTheme {
  // Colores de la paleta
  static const Color primaryGreen = AppConstants.sageGreenTitle;
  static const Color backgroundCream = AppConstants.backgroundCream;
  static const Color headerBeige = AppConstants.headerBeige;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: AppConstants.sageGreenSubtitle,
        surface: backgroundCream,
      ),
      scaffoldBackgroundColor: backgroundCream,
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBeige,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        centerTitle: true,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AppConstants.borderLight,
            width: 0.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppConstants.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppConstants.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppConstants.textTertiary),
        prefixIconColor: AppConstants.textTertiary,
      ),
    );
  }
}
