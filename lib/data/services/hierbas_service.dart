import '../models/hierba.dart';
import '../models/preparacion_tradicional.dart';
import '../repositories/hierbas_repository.dart';
import '../repositories/preparaciones_repository.dart';
import 'recetas_service.dart';

/// Servicio de lógica de negocio para el herbolario
class HierbasService {
  final HierbasRepository _repository;
  final RecetasService _recetasService;
  final PreparacionesRepository _preparacionesRepository;

  HierbasService({
    HierbasRepository? repository,
    RecetasService? recetasService,
    PreparacionesRepository? preparacionesRepository,
  })  : _repository = repository ?? HierbasRepository(),
        _recetasService = recetasService ?? RecetasService(),
        _preparacionesRepository =
            preparacionesRepository ?? PreparacionesRepository();

  /// Obtiene todas las hierbas ordenadas alfabéticamente
  Future<List<Hierba>> getHierbas() async {
    final hierbas = await _repository.getHierbas();
    hierbas.sort((a, b) => a.nombre.compareTo(b.nombre));
    return hierbas;
  }

  /// Obtiene una hierba por ID
  Future<Hierba?> getHierbaById(String id) async {
    return _repository.getHierbaById(id);
  }

  /// Obtiene todas las preparaciones tradicionales del herbolario
  Future<List<PreparacionTradicional>> getPreparaciones() async {
    return _preparacionesRepository.getPreparaciones();
  }

  /// Busca hierbas por texto
  Future<List<Hierba>> buscarHierbas(String query) async {
    if (query.trim().isEmpty) return getHierbas();
    return _repository.buscarHierbas(query);
  }

  /// Filtra hierbas por propiedad (tag)
  Future<List<Hierba>> getHierbasByTag(String tag) async {
    return _repository.getHierbasByTag(tag);
  }

  /// Tags únicos ordenados por frecuencia
  Future<List<String>> getTagsPopulares() async {
    return _repository.getTagsPopulares();
  }

  /// Resuelve los nombres de tags a etiquetas legibles.
  ///
  /// Solo los tags VISIBLES del schema enriquecido (Fase A). Los tags
  /// riesgosos/internos de la tabla (precaucion_alta, toxicidad…) no se
  /// muestran como chips: van a `nivelRiesgo`.
  static const Map<String, String> tagLabels = {
    'cardiovascular': 'Cardiovascular',
    'circulacion': 'Circulación',
    'digestivo': 'Digestivo',
    'diuretico': 'Diurético',
    'dolor_articular': 'Dolor articular',
    'laxante': 'Laxante',
    'nutricional': 'Nutricional',
    'piel': 'Piel',
    'relajacion': 'Relajación',
    'respiratorio': 'Respiratorio',
    'sueño': 'Sueño',
    'uso_externo': 'Uso externo',
    'vias_urinarias': 'Vías urinarias',
  };

  /// Convierte un tag interno a su etiqueta legible
  String tagLabel(String tag) => tagLabels[tag] ?? tag;

  /// Devuelve (sistemaId, receta) de todas las recetas que contienen
  /// la hierba en sus ingredientes.
  ///
  /// Matchea por substring del nombre + aliases: una hierba con nombre
  /// "Amargón (Diente de león)" y alias ["Diente de león"] encuentra recetas
  /// cuyo ingrediente diga "diente de león" (o "amargón").
  Future<List<Map<String, dynamic>>> getRecetasConHierba(
    String hierbaNombre, {
    List<String> aliases = const [],
  }) async {
    if (hierbaNombre.trim().isEmpty) return [];

    final sistemas = await _recetasService.getSistemas();
    final nombres =
        [hierbaNombre, ...aliases].map((n) => n.toLowerCase().trim()).toList();
    final recetasConHierba = <Map<String, dynamic>>[];

    for (final sistema in sistemas) {
      for (final receta in sistema.recetas) {
        if (receta.ingredientes.any((ing) {
          final ingrediente = ing.toLowerCase();
          return nombres.any((n) => n.isNotEmpty && ingrediente.contains(n));
        })) {
          recetasConHierba.add({
            'receta': receta,
            'sistemaId': sistema.id,
          });
        }
      }
    }

    return recetasConHierba;
  }
}
