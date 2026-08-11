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
    // Lote libro (digestivo completo): vocabulario coloquial real
    'me cae pesada la comida': 'digestivo_01',
    'no digiero bien': 'digestivo_01',
    'sensacion de llenura': 'digestivo_01',
    'dolor de panza': 'digestivo_04',
    'frio en el estomago': 'digestivo_04',
    'panza hinchada': 'digestivo_04',
    'jarabe para la digestion': 'digestivo_05',
    'me quema la panza': 'digestivo_05',
    'acidez despues de comer': 'digestivo_05',
    'no tengo hambre': 'digestivo_06',
    'sin apetito': 'digestivo_06',
    'limpiar el organismo': 'digestivo_07',
    'desintoxicar': 'digestivo_07',
    'no puedo ir al bano': 'digestivo_08',
    'estoy estrenido': 'digestivo_08',
    'me lleno rapido': 'digestivo_09',
    'sin ganas de comer': 'digestivo_09',
    'panza dura': 'digestivo_10',
    'no me salen los gases': 'digestivo_10',
    'higado': 'digestivo_11',
    'me cae mal la grasa': 'digestivo_11',
    'comidas grasosas': 'digestivo_11',
    'vientre hinchado': 'digestivo_13',
    'agua digestiva': 'digestivo_13',
    'para viajar': 'digestivo_16',
    'comer fuera de casa': 'digestivo_16',
    'polvo digestivo': 'digestivo_16',
    // Nervioso
    'ansiedad': 'nervioso_13',
    'insomnio': 'nervioso_11',
    'dolor de cabeza': 'nervioso_10',
    'estres': 'nervioso_02',
    'falta de enfoque': 'nervioso_04',
    // Lote libro (nervioso completo): vocabulario coloquial real
    'dia agitado': 'nervioso_01',
    'desconectar': 'nervioso_01',
    'relajarse despues del trabajo': 'nervioso_01',
    'conciliar el sueno': 'nervioso_03',
    'sueno profundo': 'nervioso_03',
    'dormir mejor': 'nervioso_03',
    'dia de nervios': 'nervioso_05',
    'relajarse en el bano': 'nervioso_05',
    'despejar la mente': 'nervioso_06',
    'energia mental': 'nervioso_06',
    'valeriana': 'nervioso_07',
    'calma profunda': 'nervioso_07',
    'jarabe para dormir': 'nervioso_08',
    'dormir tranquilo': 'nervioso_08',
    'ashwagandha': 'nervioso_09',
    'recuperar energia': 'nervioso_09',
    'memoria': 'nervioso_12',
    'desanimo': 'nervioso_12',
    'tristeza': 'nervioso_14',
    'sobrecarga emocional': 'nervioso_14',
    'flores de bach': 'nervioso_14',
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
