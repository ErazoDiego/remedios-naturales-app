import 'package:flutter/material.dart';
import 'package:tabler_icons/tabler_icons.dart';

/// Constantes de la aplicación Remedios Naturales
class AppConstants {
  // Nombre de la aplicación
  static const String appName = 'Remedios Naturales';
  static const String appVersion = '1.0.0';
  
  // Descripción
  static const String appDescription = 'Tu guía de bienestar natural';
  
  // IDs de sistemas corporales
  static const List<String> sistemasIds = [
    'digestivo',
    'nervioso',
    'respiratorio',
    'inmunitario',
    'cardiovascular',
    'hormonal',
    'musculoesqueletico',
    'urinario',
    'dermico',
    'sensorial',
  ];

  // Nombres completos de sistemas
  static const Map<String, String> sistemasNombres = {
    'digestivo': 'Sistema Digestivo',
    'nervioso': 'Sistema Nervioso y Mental',
    'respiratorio': 'Sistema Respiratorio',
    'inmunitario': 'Sistema Inmunitario',
    'cardiovascular': 'Sistema Cardiovascular y Metabólico',
    'hormonal': 'Sistema Hormonal y Reproductivo',
    'musculoesqueletico': 'Sistema Músculo-Esquelético',
    'urinario': 'Sistema Urinario y Renal',
    'dermico': 'Sistema Dérmico (Piel y Cabello)',
    'sensorial': 'Sistema Sensorial y Bucal',
  };

  // Emojis de sistemas (LEGACY - mantener para fallback)
  static const Map<String, String> sistemasEmojis = {
    'digestivo': '🫁',
    'nervioso': '🧠',
    'respiratorio': '🌬️',
    'inmunitario': '🛡️',
    'cardiovascular': '❤️',
    'hormonal': '♀️',
    'musculoesqueletico': '💪',
    'urinario': '💧',
    'dermico': '🧴',
    'sensorial': '👁️',
  };

  // ═══════════════════════════════════════════════════════════════════
  // NUEVA PALETA DE COLORES - TIERRA / HERBAL
  // ═══════════════════════════════════════════════════════════════════

  // Fondo general
  static const Color backgroundCream = Color(0xFFF6F3EC);
  
  // Header
  static const Color headerBeige = Color(0xFFEFEAE0);
  
  // Familia principal - Verde Salvia (físico/orgánico)
  static const Color sageGreenCard = Color(0xFFEAF3DE);
  static const Color sageGreenTitle = Color(0xFF27500A);
  static const Color sageGreenSubtitle = Color(0xFF3B6D11);
  
  // Familia secundaria - Gris Cálido (sistémico)
  static const Color warmGrayCard = Color(0xFFF1EFE8);
  static const Color warmGrayTitle = Color(0xFF2C2C2A);
  static const Color warmGraySubtitle = Color(0xFF5F5E5A);
  
  // Color de alerta - Ámbar
  static const Color alertAmber = Color(0xFFBA7517);
  static const Color alertAmberBackground = Color(0xFFFFF8E1);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF2C2C2A);
  static const Color textSecondary = Color(0xFF5F5E5A);
  static const Color textTertiary = Color(0xFF8A8A88);
  
  // Colores de borde
  static const Color borderLight = Color(0xFFE5E2DB);
  static const Color borderMedium = Color(0xFFD1CEC7);

  // ═══════════════════════════════════════════════════════════════════
  // MAPEO DE SISTEMAS A FAMILIAS DE COLOR
  // ═══════════════════════════════════════════════════════════════════
  
  // Familia por sistema: true = verde salvia, false = gris cálido
  static const Map<String, bool> sistemasFamiliaVerde = {
    'digestivo': true,        // Físico
    'nervioso': false,        // Sistémico
    'respiratorio': true,     // Físico
    'inmunitario': false,     // Sistémico
    'cardiovascular': true,   // Físico
    'hormonal': false,        // Sistémico
    'musculoesqueletico': true, // Físico
    'urinario': false,        // Sistémico
    'dermico': true,          // Físico
    'sensorial': false,       // Sistémico
  };

  // Helper: obtener color de fondo de card por sistema
  static Color getCardBackgroundColor(String sistemaId) {
    return sistemasFamiliaVerde[sistemaId] == true
        ? sageGreenCard
        : warmGrayCard;
  }

  // Helper: obtener color de título por sistema
  static Color getCardTitleColor(String sistemaId) {
    return sistemasFamiliaVerde[sistemaId] == true
        ? sageGreenTitle
        : warmGrayTitle;
  }

  // Helper: obtener color de subtítulo por sistema
  static Color getCardSubtitleColor(String sistemaId) {
    return sistemasFamiliaVerde[sistemaId] == true
        ? sageGreenSubtitle
        : warmGraySubtitle;
  }

  // ═══════════════════════════════════════════════════════════════════
  // ESTILO POR TIPO DE PREPARACIÓN (colores semánticos fijos)
  // ═══════════════════════════════════════════════════════════════════
  // Cada tipo de preparación tiene su propio color + ícono.
  // Los colores NO dependen del sistema corporal — son universales.

  static final Map<String, PreparacionStyle> _preparacionStyles = {
    // ─── Bebida / infusión (teal) ───
    'infusión':         PreparacionStyle(
      bg: Color(0xFFE1F5EE), fg: Color(0xFF085041), icon: TablerIcons.cup),
    'agua medicinal':   PreparacionStyle(
      bg: Color(0xFFE1F5EE), fg: Color(0xFF085041), icon: TablerIcons.glass),
    'bebida':           PreparacionStyle(
      bg: Color(0xFFE1F5EE), fg: Color(0xFF085041), icon: TablerIcons.cup),
    'bebida caliente':  PreparacionStyle(
      bg: Color(0xFFE1F5EE), fg: Color(0xFF085041), icon: TablerIcons.coffee),
    'caldo':            PreparacionStyle(
      bg: Color(0xFFE1F5EE), fg: Color(0xFF085041), icon: TablerIcons.cup),
    'shot':             PreparacionStyle(
      bg: Color(0xFFE1F5EE), fg: Color(0xFF085041), icon: TablerIcons.glass),
    'mezcla seca':      PreparacionStyle(
      bg: Color(0xFFE1F5EE), fg: Color(0xFF085041), icon: TablerIcons.leaf),
    'mezcla dulce':     PreparacionStyle(
      bg: Color(0xFFE1F5EE), fg: Color(0xFF085041), icon: TablerIcons.candy),

    // ─── Tónico (violeta) ───
    'tónico':           PreparacionStyle(
      bg: Color(0xFFEEEDFE), fg: Color(0xFF3C3489), icon: TablerIcons.bottle),
    'tónico líquido':   PreparacionStyle(
      bg: Color(0xFFEEEDFE), fg: Color(0xFF3C3489), icon: TablerIcons.bottle),
    'tónico caliente':  PreparacionStyle(
      bg: Color(0xFFEEEDFE), fg: Color(0xFF3C3489), icon: TablerIcons.bottle),

    // ─── Jarabe (ámbar) ───
    'jarabe':           PreparacionStyle(
      bg: Color(0xFFFAEEDA), fg: Color(0xFF633806), icon: TablerIcons.medicine_syrup),
    'jarabe suave':     PreparacionStyle(
      bg: Color(0xFFFAEEDA), fg: Color(0xFF633806), icon: TablerIcons.medicine_syrup),
    'gotas':            PreparacionStyle(
      bg: Color(0xFFFAEEDA), fg: Color(0xFF633806), icon: TablerIcons.droplet),
    'extracto líquido': PreparacionStyle(
      bg: Color(0xFFFAEEDA), fg: Color(0xFF633806), icon: TablerIcons.flask_2),
    'elixir líquido':   PreparacionStyle(
      bg: Color(0xFFFAEEDA), fg: Color(0xFF633806), icon: TablerIcons.flask),

    // ─── Tintura (rosa) ───
    'tintura':          PreparacionStyle(
      bg: Color(0xFFFBEAF0), fg: Color(0xFF72243E), icon: TablerIcons.flask_2),
    'tintura combinada':PreparacionStyle(
      bg: Color(0xFFFBEAF0), fg: Color(0xFF72243E), icon: TablerIcons.flask_2),

    // ─── Tópico / compresa (coral) ───
    'compresa':         PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.first_aid_kit),
    'compresas o lavado superficial': PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.first_aid_kit),
    'cataplasma':       PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.leaf),
    'bálsamo':          PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.hand_move),
    'ungüento':         PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.brush),
    'crema':            PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.brush),
    'gel':              PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.droplet_half),
    'pasta':            PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.brush),
    'loción':           PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.droplet_half),
    'sérum':            PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.droplet),
    'aceite de masaje': PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.hand_move),
    'aceite':           PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.droplet_filled),
    'aceite corporal':  PreparacionStyle(
      bg: Color(0xFFFAECE7), fg: Color(0xFF712B13), icon: TablerIcons.droplet_filled),

    // ─── Baño / higiene (ámbar oscuro) ───
    'baño':             PreparacionStyle(
      bg: Color(0xFFFFF8E1), fg: Color(0xFFBA7517), icon: TablerIcons.bath),
    'baño herbal':      PreparacionStyle(
      bg: Color(0xFFFFF8E1), fg: Color(0xFFBA7517), icon: TablerIcons.bath),
    'champú':           PreparacionStyle(
      bg: Color(0xFFFFF8E1), fg: Color(0xFFBA7517), icon: TablerIcons.brush),
    'acondicionador líquido': PreparacionStyle(
      bg: Color(0xFFFFF8E1), fg: Color(0xFFBA7517), icon: TablerIcons.brush),
    'enjuague':         PreparacionStyle(
      bg: Color(0xFFFFF8E1), fg: Color(0xFFBA7517), icon: TablerIcons.mug),
    'enjuague con aceite': PreparacionStyle(
      bg: Color(0xFFFFF8E1), fg: Color(0xFFBA7517), icon: TablerIcons.mug),
    'mascarilla':       PreparacionStyle(
      bg: Color(0xFFFFF8E1), fg: Color(0xFFBA7517), icon: TablerIcons.face_id),

    // ─── Spray / inhalación (índigo) ───
    'spray':            PreparacionStyle(
      bg: Color(0xFFEDEEFE), fg: Color(0xFF2D3580), icon: TablerIcons.spray),
    'spray nasal':      PreparacionStyle(
      bg: Color(0xFFEDEEFE), fg: Color(0xFF2D3580), icon: TablerIcons.spray),
    'roll-on':          PreparacionStyle(
      bg: Color(0xFFEDEEFE), fg: Color(0xFF2D3580), icon: TablerIcons.droplet),
    'inhalación de vapor': PreparacionStyle(
      bg: Color(0xFFEDEEFE), fg: Color(0xFF2D3580), icon: TablerIcons.wind),
    'inhalación aromática': PreparacionStyle(
      bg: Color(0xFFEDEEFE), fg: Color(0xFF2D3580), icon: TablerIcons.wind),
    'gárgaras':         PreparacionStyle(
      bg: Color(0xFFEDEEFE), fg: Color(0xFF2D3580), icon: TablerIcons.mug),
    'aromaterapia en spray': PreparacionStyle(
      bg: Color(0xFFEDEEFE), fg: Color(0xFF2D3580), icon: TablerIcons.spray),
    'aromaterapia en roll-on': PreparacionStyle(
      bg: Color(0xFFEDEEFE), fg: Color(0xFF2D3580), icon: TablerIcons.droplet),
    'aplicación aromática': PreparacionStyle(
      bg: Color(0xFFEDEEFE), fg: Color(0xFF2D3580), icon: TablerIcons.leaf),
  };

  // Fallback por defecto (si aparece un tipo no mapeado)
  static final PreparacionStyle _defaultStyle = PreparacionStyle(
    bg: sageGreenCard, fg: sageGreenTitle, icon: TablerIcons.leaf);

  /// Obtener estilo visual completo para un tipo de preparación
  static PreparacionStyle getPreparacionStyle(String? tipo) {
    if (tipo == null || tipo.isEmpty) return _defaultStyle;
    return _preparacionStyles[tipo.toLowerCase()] ?? _defaultStyle;
  }

  /// Obtener solo el color de fondo del badge
  static Color getPreparacionBadgeBg(String? tipo) =>
      getPreparacionStyle(tipo).bg;

  /// Obtener solo el color de texto del badge
  static Color getPreparacionBadgeFg(String? tipo) =>
      getPreparacionStyle(tipo).fg;

  /// Obtener solo el ícono del tipo de preparación
  static IconData getPreparacionIcon(String? tipo) =>
      getPreparacionStyle(tipo).icon;
}

/// Estilo visual por tipo de preparación (color + ícono)
class PreparacionStyle {
  final Color bg;
  final Color fg;
  final IconData icon;
  const PreparacionStyle({
    required this.bg,
    required this.fg,
    required this.icon,
  });
}
