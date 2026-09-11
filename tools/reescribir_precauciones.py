#!/usr/bin/env python3
"""Reescribe las precauciones (col 10) de la tabla maestra: lenguaje para el
usuario final. Notas de edición ('no fijar', 'presentar como', 'no afirmar',
'no prometer', 'no mantener tag'...) se convierten al mensaje de la ficha o
se vacían si no había riesgo real documentado. Backup ya hecho aparte.
"""
import openpyxl

XLSX = '/mnt/d/DAE/APPs/Medicina_natural/herbolario/tabla_maestra_hierbas_app.xlsx'
OUT = '/tmp/opencode/tabla_maestra_editada.xlsx'

# nombre_comun exacto (col 0) -> nueva precaución ('' = vaciar celda)
NUEVAS = {
    # ── Riesgo real documentado: texto para el usuario ──────────────────
    'Alcachofa': 'La parte utilizada es la hoja; no confundir con el capítulo comestible (la alcachofa de mesa).',
    'Amargón (Diente de león)': 'Consultar a un profesional en caso de obstrucción biliar.',
    'Borraja': 'Contiene alcaloides pirrolizidínicos, con riesgo de toxicidad hepática; evitar su uso prolongado.',
    'Cardo mariano': 'No sustituye la evaluación ni el tratamiento de afecciones hepáticas.',
    'Castaño de indias': 'No consumir las semillas crudas ni preparados caseros.',
    'Crataegus': 'No sustituye la evaluación médica de afecciones cardíacas.',
    'Cáscara sagrada': 'No usar de forma prolongada; riesgo de alteraciones del equilibrio de electrolitos.',
    'Damiana': 'No hay evidencia clínica sólida de un efecto afrodisíaco.',
    'Estigma de maíz': 'No sustituye la evaluación médica de síntomas urinarios persistentes.',
    'Eucaliptus': 'El aceite esencial no equivale a la infusión y requiere precauciones adicionales.',
    'Garcinia': 'Se han reportado casos de hepatotoxicidad; no hay evidencia sólida de efecto adelgazante. Consultar a un profesional antes de su uso.',
    'Graviola': 'No hay evidencia clínica de que trate o cure el cáncer; posibles efectos neurotóxicos. No usar sin supervisión profesional.',
    'Harpagofito': 'La parte utilizada es la raíz, no el fruto; consultar por interacciones y contraindicaciones.',
    'Higuera': 'El látex es irritante y fototóxico; no aplicar preparados caseros de látex.',
    'Hisopo': 'El aceite esencial es mucho más concentrado que la infusión; no equiparar.',
    'Lapacho': 'No hay evidencia que lo respalde como tratamiento oncológico; verificar la especie comercial.',
    'Menta': "El nombre 'menta' abarca varias especies (Mentha); el aceite esencial no equivale a la hoja.",
    'Ortiga': 'Evitar su uso diurético si hay indicación médica de restricción de líquidos; distinguir la raíz de las hojas.',
    'Palo santo': 'No asumir el uso interno; distinguir el sahumerio (uso ceremonial) del preparado medicinal.',
    'Pezuña de vaca': 'No sustituye los antidiabéticos; puede provocar hipoglucemia. Consultar a un profesional.',
    'Romerillo': 'Identificar la especie exacta antes de su uso: algunos taxones pueden ser tóxicos.',
    'Romero': 'El aceite esencial no equivale a la hoja seca o la infusión.',
    'Rompepiedra': "No hay evidencia de que 'rompa' o disuelva cálculos; verificar la especie (Phyllanthus).",
    'Ruda': 'Tóxica en dosis altas; contraindicada durante el embarazo. Evitar su uso interno.',
    'Salvia blanca': "El nombre 'salvia blanca' puede designar otras especies: verificar la planta exacta.",
    'Sen': 'No usar más de una semana sin supervisión médica; el abuso puede alterar el equilibrio de líquidos y electrolitos.',
    'Sombra de toro': 'No es un tratamiento de la dependencia alcohólica.',
    'Té rojo': 'Los extractos concentrados no equivalen a la bebida; no hay evidencia sólida de efecto adelgazante.',
    'Té verde': 'Los extractos concentrados no equivalen a la infusión; consultar a un profesional antes de usarlos.',
    'Uva ursi': 'No sustituye el tratamiento de las infecciones urinarias; limitar su uso a periodos cortos.',
    'Vira vira': 'Identificar la especie regional exacta antes de su uso.',
    'Yerba carnicera': 'La parte utilizada y la preparación varían según la región.',
    'Yerba del pollo': 'El nombre común varía según la región.',
    # ── Solo notas de edición, sin riesgo real: se vacían ────────────────
    'Achicoria': '',
    'Ambay': '',
    'Cedrón': '',
    'Centella asiática': '',
    'Chañar': '',
    'Chía': '',
    'Congorosa': '',
    'Fresno': '',
    'Fumaria': '',
    'Ginseng': '',
    'Maca': '',
    'Marcela': '',
    'Marrubio': '',
    'Melisa': '',
    'Palo pichi': '',
    'Té del burro': '',
    'Tusca': '',
    'Boldo': '',  # solo nota de redacción ('evitar depurativo como afirmación')
    'Naranjo hojas': 'Las hojas vendidas como "naranjo" pueden proceder de otros cítricos; verificar la especie antes de su uso.',
    # ── Segunda pasada: notas que quedaron del barrido amplio ────────────
    'Angélica': 'Verificar la especie exacta: el nombre puede aplicarse a otras plantas.',
    'Palo azul': 'Dos plantas distintas comparten el nombre; identificar la especie regional.',
    'Canchalagua': 'El nombre se aplica a numerosas especies según la región.',
    'Arándano': "El nombre 'arándano' incluye varios Vaccinium; verificar la especie del producto.",
    'Cuasia': 'Quassia también puede referir a Picrasma excelsa; verificar el producto.',
    'Mático': 'La especie regional varía: identificar antes de su uso.',
    'Cola de caballo': 'En América Latina puede comercializarse Equisetum giganteum; verificar la especie.',
    'Zarzaparrilla': 'Numerosas especies comparten el nombre; verificar la procedencia.',
    'Poleo': 'El aceite esencial de Mentha pulegium puede ser gravemente hepatotóxico; identificar la especie exacta.',
}

wb = openpyxl.load_workbook(XLSX)
ws = wb['Maestro']

editadas = 0
saltadas = []
for fila in range(2, ws.max_row + 1):
    nombre = (ws.cell(row=fila, column=1).value or '').strip()
    if nombre in NUEVAS:
        anterior = (ws.cell(row=fila, column=11).value or '')
        ws.cell(row=fila, column=11).value = NUEVAS[nombre] or None
        editadas += 1
        print(f'[{fila:>3}] {nombre}')
        print(f'    ANTES: {anterior[:100]}')
        print(f'    AHORA: {(NUEVAS[nombre] or "<vacío>")[:100]}')
    elif nombre:
        saltadas.append(nombre)

wb.save(OUT)
print(f'\nEditadas: {editadas} -> {OUT} | Fila por nombre no matcheada: {saltadas}')