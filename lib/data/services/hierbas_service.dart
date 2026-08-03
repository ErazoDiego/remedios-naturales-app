import '../models/hierba.dart';
import '../repositories/hierbas_repository.dart';
import 'recetas_service.dart';

/// Servicio de lógica de negocio para el herbolario
class HierbasService {
  final HierbasRepository _repository;
  final RecetasService _recetasService;

  HierbasService({
    HierbasRepository? repository,
    RecetasService? recetasService,
  })  : _repository = repository ?? HierbasRepository(),
        _recetasService = recetasService ?? RecetasService();

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

  /// Resuelve los nombres de tags a etiquetas legibles
  static const Map<String, String> tagLabels = {
    'digestivo': 'Digestivo',
    'diuretico': 'Diurético',
    'respiratorio': 'Respiratorio',
    'antiinflamatorio': 'Antiinflamatorio',
    'energizante': 'Energizante',
    'sedante': 'Sedante',
    'metabolico': 'Metabólico',
    'depurativo': 'Depurativo',
    'hormonal': 'Hormonal',
    'circulacion': 'Circulación',
    'diaforetico': 'Diaforético',
    'antiséptico': 'Antiséptico',
    'inmunologico': 'Inmunológico',
    'piel': 'Piel',
    'antioxidante': 'Antioxidante',
    'vision': 'Visión',
    'memoria': 'Memoria',
    'hemostatico': 'Hemostático',
    'antialcoholico': 'Antialcohólico',
    'edulcorante': 'Edulcorante',
  };

  /// Convierte un tag interno a su etiqueta legible
  String tagLabel(String tag) => tagLabels[tag] ?? tag;

  /// Devuelve (sistemaId, receta) de todas las recetas que contienen
  /// la hierba en sus ingredientes (matcheo por substring del nombre)
  Future<List<Map<String, dynamic>>> getRecetasConHierba(
      String hierbaNombre) async {
    if (hierbaNombre.trim().isEmpty) return [];

    final sistemas = await _recetasService.getSistemas();
    final nombreLower = hierbaNombre.toLowerCase().trim();
    final recetasConHierba = <Map<String, dynamic>>[];

    for (final sistema in sistemas) {
      for (final receta in sistema.recetas) {
        if (receta.ingredientes.any(
          (ing) => ing.toLowerCase().contains(nombreLower),
        )) {
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
