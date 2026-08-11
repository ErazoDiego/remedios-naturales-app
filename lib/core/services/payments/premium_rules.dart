import '../../constants/app_constants.dart';

/// Reglas puras del plan premium (freemium) — sin estado, testeables.
///
/// Plan FREE: 5 favoritos + 5 recetas propias. Premium: ilimitado.
/// Las recetas "gratis por sistema" (muestreo) se resuelven aparte
/// con [recetasGratisPorSistema] (lista de IDs libres por sistema).
class PremiumRules {
  PremiumRules._();

  /// ¿Puede el usuario guardar otro favorito?
  static bool canAddFavorite({
    required bool isPremium,
    required int currentFavorites,
  }) =>
      isPremium || currentFavorites < AppConstants.freeFavoritosLimit;

  /// ¿Puede el usuario crear otra receta propia?
  static bool canCreateReceta({
    required bool isPremium,
    required int currentRecetas,
  }) =>
      isPremium || currentRecetas < AppConstants.freeMisRecetasLimit;

  /// ¿La receta pertenece al muestreo gratuito del plan FREE?
  static bool esRecetaGratuita(String recipeId) =>
      recetasGratisPorSistema.contains(recipeId);

  /// Sistema corporal de una receta a partir de su ID
  /// ('digestivo_03' → 'digestivo').
  static String sistemaDeReceta(String recipeId) {
    final guion = recipeId.indexOf('_');
    return guion == -1 ? recipeId : recipeId.substring(0, guion);
  }

  /// ID del pack de un sistema ('digestivo' → 'yuyo_pack_digestivo').
  static String packIdDeSistema(String sistemaId) =>
      AppConstants.packProductId(sistemaId);

  /// Sistema al que pertenece un pack ('yuyo_pack_digestivo' → 'digestivo').
  static String sistemaIdDePack(String packId) =>
      packId.replaceFirst('yuyo_pack_', '');

  /// ¿El usuario posee el pack del sistema?
  static bool tienePackDeSistema(List<String> packs, String sistemaId) =>
      packs.contains(packIdDeSistema(sistemaId));

  /// ¿Puede el usuario abrir el detalle de la receta?
  ///
  /// FREE: solo las [recetasGratisPorSistema]. Premium: todas.
  /// Con packs: todas las recetas del sistema comprado.
  static bool puedeAccederAReceta({
    required bool isPremium,
    required String recipeId,
    List<String> packs = const [],
  }) =>
      isPremium ||
      esRecetaGratuita(recipeId) ||
      tienePackDeSistema(packs, sistemaDeReceta(recipeId));

  /// ¿Puede el usuario abrir una receta de una colección de la biblioteca?
  ///
  /// Premium incluye TODAS las colecciones, presentes y futuras
  /// (decisión de producto 2026-08-11). Sin premium, se necesita el
  /// pack de la colección ('yuyo_pack_<coleccionId>', mismo formato que
  /// los packs por sistema).
  static bool puedeAccederRecetaColeccion({
    required String coleccionId,
    required bool isPremium,
    required List<String> packs,
  }) =>
      isPremium || packs.contains(packIdDeSistema(coleccionId));

  /// IDs de recetas gratis por sistema (muestreo visible del plan FREE).
  ///
  /// Definidas por el usuario (recetas_mas_buscadas_por_sistema.xlsx):
  /// las 5 recetas más buscadas por sistema, mapeadas a los IDs reales
  /// de la app por ingrediente + función + tipo de preparación.
  static const Set<String> recetasGratisPorSistema = {
    // Digestivo
    'digestivo_03', // Te calmante para la acidez (idealPara: acidez)
    'digestivo_12', // Cataplasma de menta para gases (externa, menta)
    'digestivo_02', // Tónico herbal postcomida (tónico, comidas abundantes)
    'digestivo_15', // Infusión de menta y cardamomo (menta+cardamomo)
    'digestivo_14', // Shot matinal de jengibre y limón (jengibre+limón)
    // Nervioso
    'nervioso_13', // Baño de hierbas para ansiedad (pasiflora, ansiedad)
    'nervioso_11', // Spray aromático para insomnio (spray, insomnio)
    'nervioso_10', // Compresa de menta para cefaleas (compresa, menta)
    'nervioso_02', // Tintura de pasiflora antiestrés (tintura, pasiflora)
    'nervioso_04', // Té de avena verde para concentración (avena, enfoque)
    // Respiratorio
    'respiratorio_05', // Gárgaras de salvia (gárgaras, salvia)
    'respiratorio_10', // Pastillas de limón y jengibre (pastillas)
    'respiratorio_01', // Jarabe de tomillo y miel (jarabe, tomillo+miel)
    'respiratorio_06', // Vaporización con eucalipto (inhalación aromática)
    'respiratorio_07', // Té expectorante con regaliz y malva (LITERAL)
    // Inmunitario
    'inmunitario_03', // Shot inmunitario de jengibre y miel (shot)
    'inmunitario_08', // Infusión preventiva para el invierno (LITERAL)
    'inmunitario_01', // Infusión de equinácea y saúco (LITERAL)
    'inmunitario_05', // Tónico adaptógeno de reishi (reishi)
    'inmunitario_10', // Tónico con cúrcuma y vinagre (tónico LITERAL)
    // Cardiovascular
    'cardiovascular_01', // Infusión de espino blanco (LITERAL)
    'cardiovascular_07', // Mezcla de semillas energéticas (semillas)
    'cardiovascular_03', // Tónico de ajo y limón (LITERAL)
    'cardiovascular_02', // Agua de canela (agua medicinal, canela)
    'cardiovascular_04', // Té de hibisco con jengibre (LITERAL)
    // Hormonal
    'hormonal_01', // Infusión reguladora con salvia y melisa (LITERAL)
    'hormonal_03', // Baño relajante para cólicos (baño, cólicos)
    'hormonal_05', // Infusión de trébol rojo (LITERAL)
    'hormonal_02', // Tintura equilibrante de vitex (tintura, vitex)
    'hormonal_09', // Tónico herbal para libido (baja libido)
    // Músculo-esquelético
    'musculoesqueletico_03', // Tintura de cúrcuma (LITERAL)
    'musculoesqueletico_16', // Infusión de laurel (laurel)
    'musculoesqueletico_02', // Compresa caliente de jengibre (LITERAL)
    'musculoesqueletico_12', // Jarabe antiinflamatorio (jarabe, inflamación)
    'musculoesqueletico_08', // Cataplasma para esguinces leves (LITERAL)
    // Urinario
    'urinario_03', // Agua de cebada con caléndula (LITERAL)
    'urinario_12', // Infusión para vejiga sensible (irritación suave)
    'urinario_01', // Infusión diurética de ortiga (ortiga, líquidos)
    'urinario_02', // Tónico depurativo con perejil (perejil, depurar)
    'urinario_10', // Infusión de gayuba y cola de caballo (LITERAL)
    // Dérmico
    'dermico_03', // Gel de aloe y menta (gel LITERAL)
    'dermico_12', // Crema hidratante con caléndula (crema, caléndula)
    'dermico_02', // Mascarilla purificante de arcilla y avena (LITERAL)
    'dermico_06', // Spray calmante post-solar (spray, enrojecimiento sol)
    'dermico_09', // Champú de romero y ortiga (champú LITERAL)
    // Sensorial
    'sensorial_07', // Roll-on para mareo y vértigo (roll-on LITERAL)
    'sensorial_03', // Enjuague bucal con salvia y clavo (enjuague LITERAL)
    'sensorial_02', // Compresa ocular refrescante (compresa, ojos)
    'sensorial_10', // Tónico ocular (ojos cansados)
    'sensorial_06', // Gotas para oído con ajo y oliva (gotas LITERAL)
  };
}
