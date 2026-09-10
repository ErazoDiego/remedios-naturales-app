#!/usr/bin/env python3
"""
Genera assets/data/hierbas.json (schema enriquecido) a partir de la
tabla maestra del herbolario (xlsx) y del hierbas.json actual.

Fase A del plan del herbolario:
  - Schema nuevo (12 campos) tomado de tabla_maestra_hierbas_app.xlsx
  - Los IDs del JSON actual se conservan (referenciados por recetas,
    preparaciones, favoritos, etc.)
  - Los alias se fusionan: alias actuales + otros_nombres_comunes
  - Los tags visibles salen de una whitelist (los tags de riesgo/metadata
    NO se muestran como chips de filtro; van a 'nivelRiesgo' o se ignoran)
  - 'nivelRiesgo' se deriva de los tags internos de la tabla
    (toxicidad/evitar_uso -> critico; precaucion_alta -> precaucion)

Uso:
  python3 tools/generar_hierbas_json.py \
      [--xlsx <ruta.xlsx>] [--out <ruta.json>]
"""
import argparse
import json
import re
import unicodedata
from collections import Counter

import openpyxl

# Whitelist de tags que se muestran como chips de filtro en el herbolario.
# El resto de los tags_corregidos de la tabla son internos (riesgo,
# identificacion, uso_tradicional*) y NO deben verse como filtros.
TAGS_VISIBLES = {
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
}

# Tags internos de la tabla que codifican riesgo (se mapean a nivelRiesgo).
TAG_RIESGO_CRITICO = {'toxicidad', 'evitar_uso'}
TAG_RIESGO_PRECAUCION = {'precaucion_alta'}

TIPO_IDENTIFICACION_VALIDOS = {
    'especie_definida',
    'nombre_comun_multiespecie',
    'variante_regional',
    'producto_procesado',
}


def normalizar(texto: str) -> str:
    """Lowercase + sin tildes + colapsa espacios + quita paréntesis."""
    s = texto.strip().lower()
    s = ''.join(
        c for c in unicodedata.normalize('NFD', s)
        if unicodedata.category(c) != 'Mn'
    )
    s = re.sub(r'[()]', ' ', s)
    return re.sub(r'\s+', ' ', s).strip()


def dividir_alias(texto: str | None) -> list[str]:
    """Separa nombres comunes por coma, ';' o '/' — preserva frases con
    espacio ('Diente de león', 'White sage')."""
    if not texto:
        return []
    partes = re.split(r'[,;/]+', texto)
    return [p.strip() for p in partes if p.strip()]


def dividir_fuentes(texto: str | None) -> list[str]:
    """Separa URLs por espacio."""
    if not texto:
        return []
    return [p.strip() for p in texto.split() if p.strip()]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--xlsx',
        default='/mnt/d/DAE/APPs/Medicina_natural/herbolario/tabla_maestra_hierbas_app.xlsx',
        help='Ruta a la tabla maestra (xlsx)',
    )
    parser.add_argument(
        '--out',
        default='/home/pc_dae/remedios_naturales_app/assets/data/hierbas.json',
        help='Ruta de salida del JSON',
    )
    parser.add_argument(
        '--actual',
        default='/home/pc_dae/remedios_naturales_app/assets/data/hierbas.json',
        help='hierbas.json actual (para conservar ids y alias)',
    )
    args = parser.parse_args()

    # ── Cargar hierbas actuales (ids y alias se conservan) ────────────
    with open(args.actual, encoding='utf-8') as f:
        actuales = json.load(f)
    actuales_por_nombre = {normalizar(h['nombre']): h for h in actuales}

    # ── Cargar tabla maestra ──────────────────────────────────────────
    wb = openpyxl.load_workbook(args.xlsx, data_only=True)
    ws = wb['Maestro']
    filas = [r for r in ws.iter_rows(values_only=True)]
    header = filas[0]
    rows = filas[1:]

    assert header[0] == 'nombre_comun', f'Header inesperado: {header}'

    # ── Construir el nuevo listado ─────────────────────────────────────
    nuevas = []
    sin_id_previo = []
    for r in rows:
        nombre = (r[0] or '').strip()
        if not nombre:
            continue

        previa = actuales_por_nombre.get(normalizar(nombre))
        if previa is None:
            sin_id_previo.append(nombre)
            continue

        otros_nombres = r[1]
        # Alias = SOLO otros_nombres_comunes de la tabla (fuente de verdad).
        # Los alias previos pueden traer basura de versiones con bugs.
        alias = set()
        for otro in dividir_alias(otros_nombres):
            otro = otro.strip()
            if not otro:
                continue
            norm_otro = normalizar(otro)
            # Descartar si repite el nombre, es residual de separador
            # o ya está cubierto por el nombre (substring).
            if (
                norm_otro != normalizar(nombre)
                and ';' not in otro
                and ',' not in otro
                and norm_otro not in normalizar(nombre)
            ):
                alias.add(otro)

        tags_brutos = dividir_alias(r[11])
        tags_visibles = sorted({
            clave for clave in TAGS_VISIBLES
            if clave in tags_brutos
        })

        if any(t in tags_brutos for t in TAG_RIESGO_CRITICO):
            nivel_riesgo = 'critico'
        elif any(t in tags_brutos for t in TAG_RIESGO_PRECAUCION):
            nivel_riesgo = 'precaucion'
        else:
            nivel_riesgo = None

        tipo_ident = (r[5] or 'especie_definida').strip()
        if tipo_ident not in TIPO_IDENTIFICACION_VALIDOS:
            tipo_ident = 'especie_definida'

        nuevas.append({
            'id': previa['id'],
            'nombre': nombre,
            'alias': sorted(alias),
            'nombreCientifico': (r[2] or '').strip() or None,
            'familia': (r[3] or '').strip() or None,
            'origenDistribucion': (r[4] or '').strip() or None,
            'tipoIdentificacion': tipo_ident,
            'comoReconocerla': (r[6] or '').strip() or None,
            'parteUtilizada': (r[7] or '').strip() or None,
            'usoTradicional': (r[9] or '').strip(),
            'precauciones': (r[10] or '').strip() or None,
            'imagen': (r[12] or '').strip() or None,
            'tags': tags_visibles,
            'nivelRiesgo': nivel_riesgo,
            'fuentes': dividir_fuentes(r[16]),
        })

    # ── Orden estable (alfabético por nombre) ──────────────────────────
    nuevas.sort(key=lambda h: normalizar(h['nombre']))

    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(nuevas, f, ensure_ascii=False, indent=2)
        f.write('\n')

    tags_uso = Counter(t for h in nuevas for t in h['tags'])
    print(f'Generadas: {len(nuevas)} hierbas -> {args.out}')
    print(f'Tags visibles en uso: {dict(tags_uso)}')
    print(f'Fichas con riesgo: '
          f'{sum(1 for h in nuevas if h["nivelRiesgo"] == "critico")} critico, '
          f'{sum(1 for h in nuevas if h["nivelRiesgo"] == "precaucion")} precaucion')
    print(f'Fichas multiespecie/regional/procesado: '
          f'{sum(1 for h in nuevas if h["tipoIdentificacion"] != "especie_definida")}')
    if sin_id_previo:
        print(f'⚠️ Sin id previo (no generadas): {sin_id_previo}')


if __name__ == '__main__':
    main()