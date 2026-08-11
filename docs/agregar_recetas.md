# Cómo agregar una receta a un sistema existente

Guía verificada contra el código (agosto 2026). Agregar una receta a un
sistema que ya existe (ej: `digestivo_17`) es un cambio **localizado**:
un JSON, un par de archivos Dart y un test. No requiere tocar Supabase ni
la base de datos.

> Para un **grupo nuevo** (ej: "jugos naturales") o **tags transversales**
> (ej: "aptas para diabéticos") NO sigas esta guía: es otra arquitectura.
> Consúltalo primero (ver sección "Qué NO es esto" al final).

---

## 1. Mapa del pipeline

```
assets/data/<sistema>.json          ← FUENTE DE VERDAD de la receta
        │  (recetas[] + totalRecetas)
        ▼
RecetasRepository.getSistemas()     ← carga los 10 JSONs (lib/data/repositories/)
        ▼
RecetasService.search()             ← búsqueda con score (lib/data/services/)
        ▼
UI: home / categoría / detalle / buscador

Además (por separado):
  lib/data/services/search_index.dart   ← keywords de búsqueda coloquial
  test/search_index_test.dart           ← validación "lote completo por sistema"
```

**NO toques** estos archivos al agregar una receta:
- `assets/data/todas_las_recetas.json` — artifact de desarrollo, la app NO lo lee
- `assets/data/sintomas_cruzados.json` — idem
- `assets/data/condiciones_index.json` — solo si la receta introduce condiciones
  de búsqueda por síntoma NUEVAS (ver paso 6)

---

## 2. Paso a paso

### Paso 1 — Agregar la receta al JSON del sistema

Editar `assets/data/<sistema>.json` (ej: `digestivo.json`) y agregar al
array `recetas` un objeto con ESTE formato exacto:

```json
{
  "id": "digestivo_17",
  "nombre": "Infusión de manzanilla y anís para después de comer",
  "descripcion": "Infusión suave que ayuda a calmar la pesadez y favorece una digestión ligera tras comidas abundantes.",
  "idealPara": [
    "pesadez después de comer",
    "digestión pesada",
    "comidas abundantes"
  ],
  "tipo": "interno",
  "tipoPreparacion": "infusión",
  "cuandoUsar": "después del almuerzo o la cena.",
  "precaucion": "evitar si hay alergia a la manzanilla o al anís.",
  "ingredientes": [
    "1 taza de agua",
    "1 cucharadita de manzanilla seca",
    "½ cucharadita de anís en grano"
  ],
  "preparacion": [
    "Hierve el agua. ",
    "Añade la manzanilla y el anís, tapa y deja reposar 5 minutos. ",
    "Cuela y bebe tibia. "
  ],
  "dosis": "1 taza después de cada comida pesada.",
  "almacenamiento": "preparar fresca cada vez.",
  "evidencia": "",
  "categoria": "digestivo",
  "imagen": "assets/images/recetas/digestivo_17.webp",
  "imagenPlaceholder": "assets/images/recetas/digestivo_17_placeholder.webp"
}
```

**Reglas del ID**: `<sistema>_NN` con NN de 2 dígitos (`digestivo_17`, no
`digestivo_7`). Usá el siguiente número libre del sistema. `categoria`
debe ser el id del sistema.

**`tipoPreparacion` OBLIGATORIO**: debe ser un valor ya mapeado en
`lib/core/constants/app_constants.dart` (`_preparacionStyles`): infusión,
tónico, jarabe, tintura, compresa, cataplasma, baño, spray, etc. Si usás
uno nuevo, la card cae al estilo por defecto (hoja verde) — o mapealo
antes. Los valores se buscan en minúsculas (el parser hace `.toLowerCase()`).

### Paso 2 — Actualizar `totalRecetas` del sistema

En el MISMO JSON, arriba del array:

```json
{
  "sistema": "Sistema Digestivo",
  "emoji": "🫁",
  "id": "digestivo",
  "totalRecetas": 17,
  "recetas": [ ... ]
}
```

Este número se muestra en la UI (`"16 recetas"` en home y en los
resultados de búsqueda). Desincronizarlo = la app miente.

### Paso 3 — Imagen (opcional pero convención)

Todas las recetas actuales tienen `assets/images/recetas/<id>.webp` y
`<id>_placeholder.webp`. La carpeta completa ya está registrada en
`pubspec.yaml` (`assets/images/recetas/`) → **NO toques pubspec**,
el build la incluye sola.

Si NO tenés imagen: dejá `"imagen": null` y `"imagenPlaceholder": null`.
La UI cae al placeholder de color del tipo de preparación (verificado en
`category_screen.dart` y `search_result_card.dart`).

### Paso 4 — Keywords en el buscador coloquial

Editar `lib/data/services/search_index.dart`:

1. Agregar la entrada al mapa `keywordsPorReceta`:

```dart
'digestivo_17': ['pesadez despues de comer', 'comida abundante', 'manzanilla con anis', 'digestion pesada', 'despues de la cena'],
```

2. Actualizar la cabecera de documentación del archivo (el bloque de
   comentario con "Lote actual: ..."): sistema en cuestión `(17/17)` y el
   total de recetas (`133` → `134`).

**Reglas de keywords**:
- Vocabulario COLOQUIAL real (como habla la gente: "me cae pesada la
  comida", "no puedo ir al bano"), no términos médicos
- Normalizados: minúsculas, SIN tildes, ñ→n (el normalizador de búsqueda
  aplica la misma regla; los keywords viven ya normalizados)
- 4-6 por receta; mapean contenido (ingredientes / idealPara), no el nombre
- Fuente de inspiración: `/tmp/opencode/libro_abuela.txt`

### Paso 5 — Actualizar el test de validación del sistema

`test/search_index_test.dart`, grupo "Lotes por sistema":

```dart
test('digestivo completo: las 16 recetas tienen keywords', () {
  final ids = List.generate(16, (i) => 'digestivo_${(i + 1).toString().padLeft(2, '0')}');
```

→ `16` → `17` (en el nombre del test y en el `List.generate`).

### Paso 6 — ¿Condiciones de búsqueda por síntoma nuevas?

Si la receta trae `idealPara` con condiciones que no existen en
`assets/data/condiciones_index.json`, agregalas a la lista `condiciones`
de ese archivo para que aparezcan en el buscador de síntomas. Si la
condición ya existe (lo más común), no toques nada.

### Paso 7 — Verificar

```bash
flutter analyze
flutter test
```

La suite completa (415 tests al momento de escribir esta guía) debe pasar
verde. En particular:
- `test/search_index_test.dart` — valida keywords de TODAS las recetas por sistema
- `test/busqueda_integracion_test.dart` — casos reales de búsqueda

### Paso 8 — Distribuir

- **Pruebas**: build debug → instalar en el S908E (adb) → copiar a
  `/mnt/d/DAE/APPs/Medicina_natural/remedios_naturales_YYYYMMDD_<tag>.apk`
- **Usuarios**: release + Play Console (la receta nueva llega con el
  release; este es el costo real de agregar contenido embebido)

---

## 3. Checklist final

- [ ] `id` con formato `<sistema>_NN` (2 dígitos), siguiente número libre
- [ ] `categoria` = id del sistema
- [ ] `tipoPreparacion` es un valor ya mapeado en `_preparacionStyles`
- [ ] `totalRecetas` actualizado (se muestra en la UI)
- [ ] Imagen en `assets/images/recetas/` (o `null` explícito)
- [ ] Keywords normalizados (sin tildes, ñ→n) agregados al mapa
- [ ] Cabecera de `search_index.dart` actualizada (conteos)
- [ ] `List.generate(N)` del sistema actualizado en el test
- [ ] `flutter analyze` + `flutter test` verdes
- [ ] NO se tocaron `todas_las_recetas.json` ni `sintomas_cruzados.json`

---

## Qué NO es esto

- **Grupo nuevo** (ej: "jugos naturales"): requiere sistema nuevo
  (JSON + `AppConstants.sistemasIds` + color + ícono + pack + producto en
  Play Console). Está documentado el camino pero no es esta guía.
- **Tags transversales** (ej: "aptas para diabéticos"): NO es un grupo
  nuevo — son recetas existentes con un atributo. Si se modela como grupo
  se DUPLICAN recetas. Requiere diseñar el atributo + filtros primero.
- **Tienda de packs dinámicos** (vender contenido desde Supabase):
  arquitectura futura; hoy los packs son los 10 sistemas embebidos.
