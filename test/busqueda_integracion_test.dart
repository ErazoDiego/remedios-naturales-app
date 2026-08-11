import 'package:flutter_test/flutter_test.dart';
import 'package:remedios_naturales_app/data/services/recetas_service.dart';

/// Test de INTEGRACIÓN con los datos REALES de la app (assets/data/*.json).
///
/// Valida el objetivo del usuario: cada dolencia/motivo de la columna del
/// Excel recetas_mas_buscadas_por_sistema.xlsx debe encontrar SU receta
/// con el motor de búsqueda nuevo (normalización + sinónimos + keywords).
///
/// Nota: se usa `any` (no `first`) porque en el mundo real una dolencia
/// puede matchear varias recetas; lo importante es que la elegida por el
/// usuario esté en los resultados.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = RecetasService();

  // Dolencia del Excel → receta elegida por el usuario (mapeo verificado).
  const casos = {
    // Digestivo
    'acidez': 'digestivo_03',
    'acidez de estomago': 'digestivo_03',
    'ardor': 'digestivo_03',
    'gases': 'digestivo_12',
    'digestion lenta': 'digestivo_02',
    'pesadez postcomida': 'digestivo_02',
    'pesadez abdominal': 'digestivo_15',
    'nauseas': 'digestivo_14',
    // Nervioso
    'ansiedad': 'nervioso_13',
    'insomnio': 'nervioso_11',
    'dolor de cabeza': 'nervioso_10',
    'estres': 'nervioso_02',
    'falta de enfoque': 'nervioso_04',
    // Respiratorio
    'dolor de garganta': 'respiratorio_05',
    'tos': 'respiratorio_01',
    'congestion nasal': 'respiratorio_06',
    'mucosidad': 'respiratorio_07',
    // Inmunitario
    'resfriado': 'inmunitario_03',
    'bajon de defensas': 'inmunitario_01',
    'fatiga': 'inmunitario_05',
    // Cardiovascular
    'circulacion': 'cardiovascular_01',
    'retencion': 'cardiovascular_02',
    'cansancio metabolico': 'cardiovascular_04',
    // Hormonal
    'sindrome premenstrual': 'hormonal_01',
    'sofocos': 'hormonal_05',
    'ciclos irregulares': 'hormonal_02',
    'libido': 'hormonal_09',
    // Músculo-esquelético
    'dolor articular': 'musculoesqueletico_03',
    'tension muscular': 'musculoesqueletico_02',
    'esguinces': 'musculoesqueletico_08',
    // Urinario
    'cistitis': 'urinario_03',
    'pesadez renal': 'urinario_10',
    // Dérmico
    'acne': 'dermico_02',
    'quemadura solar': 'dermico_06',
    'cabello debil': 'dermico_09',
    // Sensorial
    'mareo': 'sensorial_07',
    'halitosis': 'sensorial_03',
    'ojos cansados': 'sensorial_02',
    'oido': 'sensorial_06',
  };

  for (final entry in casos.entries) {
    test('"${entry.key}" encuentra ${entry.value} (datos reales)', () async {
      final results = await service.search(entry.key);

      final ids = results.map((r) => r.id).toList();
      expect(ids, contains(entry.value),
          reason: 'Resultados de "${entry.key}": $ids');
    });
  }
}
