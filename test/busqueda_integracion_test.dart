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
    // Lote libro (respiratorio completo): vocabulario coloquial real
    'vapor de eucalipto': 'respiratorio_02',
    'abrir la nariz': 'respiratorio_02',
    'respirar mejor': 'respiratorio_02',
    'bronquios': 'respiratorio_03',
    'pecho con flema': 'respiratorio_03',
    'opresion en el pecho': 'respiratorio_04',
    'pecho tapado': 'respiratorio_04',
    'spray nasal': 'respiratorio_08',
    'nariz seca': 'respiratorio_08',
    'jarabe de cebolla': 'respiratorio_09',
    'remedio de la abuela': 'respiratorio_09',
    'sauco': 'respiratorio_11',
    'romper el resfriado': 'respiratorio_11',
    'cabeza pesada': 'respiratorio_12',
    'despejar la nariz': 'respiratorio_12',
    // Inmunitario
    'resfriado': 'inmunitario_03',
    'bajon de defensas': 'inmunitario_01',
    'fatiga': 'inmunitario_05',
    // Lote libro (inmunitario completo): vocabulario coloquial real
    'leche dorada': 'inmunitario_02',
    'curcuma y pimienta': 'inmunitario_02',
    'dias frios': 'inmunitario_02',
    'frutos rojos': 'inmunitario_04',
    'despues de la gripe': 'inmunitario_04',
    'caldo de ajo': 'inmunitario_06',
    'sopa para el resfriado': 'inmunitario_06',
    'estoy debil': 'inmunitario_06',
    'cambio de estacion': 'inmunitario_07',
    'limpiar la sangre': 'inmunitario_07',
    'antiviral': 'inmunitario_09',
    'ajo y limon': 'inmunitario_09',
    'combatir virus': 'inmunitario_09',
    'antes de salir de casa': 'inmunitario_11',
    'ambientes cargados': 'inmunitario_11',
    'astragalo': 'inmunitario_12',
    'energia sostenida': 'inmunitario_12',
    'propolis': 'inmunitario_13',
    'reforzar defensas': 'inmunitario_13',
    // Cardiovascular
    'circulacion': 'cardiovascular_01',
    'retencion': 'cardiovascular_02',
    'cansancio metabolico': 'cardiovascular_04',
    // Lote libro (cardiovascular completo): vocabulario coloquial real
    'extracto de curcuma': 'cardiovascular_05',
    'proteger el corazon': 'cardiovascular_05',
    'presion alta': 'cardiovascular_06',
    'hojas de olivo': 'cardiovascular_06',
    'tension alta': 'cardiovascular_06',
    'batido verde': 'cardiovascular_08',
    'empezar el dia con energia': 'cardiovascular_08',
    'ajo negro': 'cardiovascular_09',
    'colesterol': 'cardiovascular_09',
    'piernas cansadas': 'cardiovascular_10',
    'pies frios': 'cardiovascular_10',
    'mente nublada': 'cardiovascular_11',
    'despertar cansado': 'cardiovascular_12',
    'vinagre de manzana': 'cardiovascular_12',
    // Hormonal
    'sindrome premenstrual': 'hormonal_01',
    'sofocos': 'hormonal_05',
    'ciclos irregulares': 'hormonal_02',
    'libido': 'hormonal_09',
    // Lote libro (hormonal completo): vocabulario coloquial real
    'aceite para colicos': 'hormonal_04',
    'panza adolorida': 'hormonal_04',
    'elixir de maca': 'hormonal_06',
    'levanta el animo': 'hormonal_06',
    'diente de leon': 'hormonal_07',
    'periodo hinchada': 'hormonal_07',
    'batido de avena': 'hormonal_08',
    'levantar energia': 'hormonal_08',
    'canela y miel': 'hormonal_10',
    'bajon de animo': 'hormonal_10',
    'postparto': 'hormonal_11',
    'despues del parto': 'hormonal_11',
    'regla irregular': 'hormonal_12',
    'atraso menstrual': 'hormonal_12',
    'cansancio hormonal': 'hormonal_13',
    'agotamiento menstrual': 'hormonal_13',
    'tension premenstrual': 'hormonal_14',
    'irritable con la regla': 'hormonal_14',
    // Músculo-esquelético
    'dolor articular': 'musculoesqueletico_03',
    'tension muscular': 'musculoesqueletico_02',
    'esguinces': 'musculoesqueletico_08',
    // Lote libro (musculoesqueletico completo): vocabulario coloquial real
    'arnica': 'musculoesqueletico_01',
    'chichon': 'musculoesqueletico_01',
    'me di un golpe': 'musculoesqueletico_01',
    'sales de magnesio': 'musculoesqueletico_04',
    'musculos cansados': 'musculoesqueletico_04',
    'cayena': 'musculoesqueletico_05',
    'dolor de rodilla': 'musculoesqueletico_05',
    'agujetas': 'musculoesqueletico_06',
    'musculos doloridos': 'musculoesqueletico_06',
    'cola de caballo': 'musculoesqueletico_07',
    'tendones': 'musculoesqueletico_07',
    'cuerpo pesado': 'musculoesqueletico_09',
    'musculos tensos': 'musculoesqueletico_10',
    'calcio': 'musculoesqueletico_11',
    'huesos debiles': 'musculoesqueletico_11',
    'dolor de cuello': 'musculoesqueletico_13',
    'contractura en el cuello': 'musculoesqueletico_13',
    'dolor de espalda': 'musculoesqueletico_14',
    'lumbago': 'musculoesqueletico_14',
    'sales de bano': 'musculoesqueletico_15',
    'bano muscular': 'musculoesqueletico_15',
    // Lote libro (urinario completo): vocabulario coloquial real
    'depurativa': 'urinario_04',
    'colico renal': 'urinario_05',
    'dolor de riñones': 'urinario_05',
    'drenar liquidos': 'urinario_06',
    'jarabe de apio': 'urinario_07',
    'malvavisco': 'urinario_08',
    'hinchazon al final del dia': 'urinario_09',
    'tintura de riñones': 'urinario_11',
    // Lote libro (dermico completo): vocabulario coloquial real
    'hamamelis': 'dermico_01',
    'arrugas': 'dermico_04',
    'pie de atleta': 'dermico_05',
    'hongos en los pies': 'dermico_05',
    'labios partidos': 'dermico_07',
    'aceite de almendra': 'dermico_08',
    'se me cae el pelo': 'dermico_09',
    'enjuague de vinagre': 'dermico_10',
    'pepino': 'dermico_11',
    'uñas debiles': 'dermico_13',
    'cuero cabelludo': 'dermico_14',
    // Lote libro (sensorial completo): vocabulario coloquial real
    'eufrasia': 'sensorial_01',
    'bicarbonato': 'sensorial_04',
    'oil pulling': 'sensorial_05',
    'boca seca': 'sensorial_05',
    'spray bucal': 'sensorial_08',
    'tomillo': 'sensorial_08',
    'hidratar labios': 'sensorial_09',
    'tirantez': 'sensorial_09',
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
