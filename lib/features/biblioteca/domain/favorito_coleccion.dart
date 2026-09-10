/// Helper de favoritos de recetas de colección.
///
/// Los favoritos del usuario se guardan como IDs planos en
/// `UserProfile.favoritos` y el tab Favoritos los resuelve por origen:
/// - Recetas propias del usuario → UUID (RecetasUsuarioService)
/// - Recetas del catálogo → IDs del catálogo ("digestivo_remedio_x")
/// - Recetas de colección → prefijo `col:` para no colisionar con las
///   anteriores: `col:<coleccionId>:<recetaId>` (ej: "col:jugos:jugos_01").
/// El prefijo permite a FavoritesScreen resolver la colección y navegar
/// a `/biblioteca/:coleccionId/:recetaId`.
class FavoritoColeccion {
  static const String prefijo = 'col:';

  /// ID plano a guardar en favoritos para una receta de colección.
  static String idDe(String coleccionId, String recetaId) =>
      '$prefijo$coleccionId:$recetaId';

  /// ¿El ID plano corresponde a una receta de colección?
  static bool esDeColeccion(String id) => descomponer(id) != null;

  /// Descompone un ID de favorito de colección en (coleccionId,
  /// recetaId). Devuelve null si el ID no es de colección o está mal
  /// formado.
  static (String, String)? descomponer(String id) {
    if (!id.startsWith(prefijo)) return null;
    final resto = id.substring(prefijo.length);
    final sep = resto.indexOf(':');
    if (sep <= 0 || sep == resto.length - 1) return null;
    return (resto.substring(0, sep), resto.substring(sep + 1));
  }
}