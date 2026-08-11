# Diseño: Biblioteca de Colecciones (módulo aislado)

Estado: **diseño para validar** (agosto 2026). Nada de esto está implementado.
Decisiones abiertas al final.

## 1. Objetivo y no-objetivos

**Qué es**: un módulo AISLADO dentro de Yuyo donde el usuario compra y
accede a **colecciones de recetas nuevas** (ej: "Jugos naturales", "Sin
TACC") que viven en **Supabase** y se **descargan al comprar**. La app
puede crecer por grupos SIN publicar release por cada grupo nuevo.

**Qué NO es / NO toca**:
- ❌ NO toca el núcleo embebido (10 sistemas, 133 recetas en assets)
- ❌ NO mezcla recetas de colección con la búsqueda global (buscador propio)
- ❌ NO son tags transversales (eso es otro diseño futuro, ver §11)
- ❌ NO es una app hermana (decisión diferida: los datos en Supabase
  permiten extraerla después sin rehacer nada)
- ❌ NO modifica el modelo premium existente (premium sigue siendo premium)

**Decisión de negocio tomada**: biblioteca DENTRO de Yuyo con identidad
visual y buscador propios (el "ala con puerta propia" del mismo edificio).

## 2. Arquitectura general

```
┌──────────────────────────────┐     ┌───────────────────────────────┐
│ NÚCLEO EMBEBIDO (hoy)        │     │ BIBLIOTECA DINÁMICA (nueva)   │
│ 10 sistemas + 133 recetas    │     │ lib/features/biblioteca/      │
│ assets/data/*.json           │     │                              │
│ SearchIndex estático         │     │ Catálogo: Supabase (tabla     │
│ Gating: PremiumRules         │     │   colecciones, pública)       │
│                              │     │ Compra: IAP existente         │
│ NO SE TOCA                   │     │ Descarga: JSONB → cache local │
└──────────────────────────────┘     │ Buscador PROPIO de biblioteca │
                                    └───────────────────────────────┘
        ▲                                          ▲
        │        REUSAN (sin duplicar):            │
        ├────── modelo Receta (Receta.fromJson) ───┤
        ├────── remedy_detail (cuerpo compartido) ─┤
        └────── perfiles.packs + purchasePack ─────┘
```

## 3. Modelo de datos Supabase (migración v6)

### Tabla `colecciones` — el catálogo

```sql
create table public.colecciones (
  id text primary key,                -- 'jugos', 'sin_tacc' (≠ ids de sistemas)
  nombre text not null,
  descripcion text not null default '',
  icono text not null default 'leaf', -- nombre de ícono TablerIcons
  color text not null default 'verde',-- familia visual: 'verde' | 'gris'
  activa boolean not null default true,
  orden int not null default 0,       -- posición en la tienda
  recetas jsonb not null default '[]',-- array de recetas (formato Receta + keywords)
  version int not null default 1,     -- sube al actualizar contenido → la app re-descarga
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);
```

**RLS** (con la v4 ya hay patrón en el proyecto):
- `SELECT` para `anon` y `authenticated` → el catálogo es visible sin login
  (la tienda funciona anónima; la compra persiste igual: local o cloud)
- `INSERT/UPDATE/DELETE` SOLO `service_role` → nadie modifica colecciones
  desde la app; el dueño las sube por SQL Editor / dashboard

### Formato de cada receta en `recetas` (JSONB)

El MISMO del modelo `Receta` actual + un campo nuevo opcional:

```json
{
  "id": "jugos_01",
  "nombre": "Jugo verde matinal",
  "descripcion": "...",
  "idealPara": ["digestion ligera", "energia por la manana"],
  "tipo": "interno",
  "tipoPreparacion": "bebida",
  "cuandoUsar": "...",
  "precaucion": "...",
  "ingredientes": ["..."],
  "preparacion": ["..."],
  "dosis": "...",
  "almacenamiento": "...",
  "imagen": null,
  "imagenPlaceholder": null,
  "keywords": ["jugo verde", "apio", "energia matinal"]
}
```

- `id` = `<coleccion_id>_NN` (2 dígitos). Sin colisión con el núcleo:
  la regla de negocio es que `id` de colección ≠ `sistemasIds`.
- `keywords` es OPCIONAL y SOLO para el buscador propio de la biblioteca.
  NO entra a `SearchIndex` (que es estático del núcleo).
- `imagen` puede ser `null` (la UI ya tiene placeholder de color).

**Por qué recetas embebidas en JSONB y no tabla normalizada**: el
contenido es de solo lectura (se sube, no se edita desde la app) y la app
baja la colección COMPLETA de una. Normalizar (tabla recetas + join)
serviría si varias colecciones COMPARTIERAN recetas — no es el caso hoy.
Deuda documentada: si algún día una colección "selecciona" recetas de
otra, ahí se normaliza (ver §11).

## 4. Flujo de usuario

```
1. Home → sección "Biblioteca" (tarjeta de entrada)
2. Biblioteca → lista "Mis colecciones" (compradas) + "Tienda" (resto)
3. Tienda → colecciones activas con precio (desde Play Console)
4. Tap "Comprar" → IAP existente (Mock en debug / Google Play en release)
5. Compra confirmada → perfiles.packs += 'yuyo_pack_<id>' (existe)
6. Descarga → la app baja la colección del catálogo → cache local
7. "Mis colecciones" → la nueva colección aparece → recetas → detalle
8. Buscador de la biblioteca → filtra SOLO las recetas descargadas
```

**Restore**: `perfiles.packs` ya persiste (v5). Al reinstalar, la app
sabe qué colecciones están compradas y re-descarga del catálogo.

## 5. Módulo en la app — `lib/features/biblioteca/`

```
lib/features/biblioteca/
├── data/
│   ├── coleccion.dart              ← modelo (id, nombre, icono, recetas, version)
│   └── biblioteca_repository.dart  ← catálogo (Supabase) + cache local
├── presentation/
│   ├── biblioteca_provider.dart    ← estado: catálogo, compradas, descarga
│   ├── biblioteca_screen.dart      ← Mis colecciones + entrada Tienda + buscador
│   ├── tienda_screen.dart          ← catálogo con precios y botón comprar
│   ├── coleccion_screen.dart       ← recetas de una colección
│   └── coleccion_search.dart       ← buscador propio (filtro en memoria)
└── README.md
```

**Cache local**: `SharedPreferences` (ya es dependencia, cero nuevas) con
clave `biblioteca_cache_<id>` = JSON crudo de la colección. Es suficiente:
una colección de decenas de recetas pesa KBs. Si las colecciones crecen a
cientos de recetas, se migra a archivos con `path_provider`/Hive (deuda
documentada, no hoy).

## 6. Rutas nuevas (app_router.dart — GoRoutes full-screen, patrón existente)

| Ruta | Pantalla |
|---|---|
| `/biblioteca` | Biblioteca: mis colecciones + buscador + entrada tienda |
| `/biblioteca/tienda` | Tienda: catálogo con precios |
| `/biblioteca/:coleccionId` | Recetas de la colección |
| `/biblioteca/:coleccionId/:recetaId` | Detalle de receta de colección |

**Entrada en home**: una tarjeta/sección "Biblioteca" en HomeScreen (el
único toque visual al núcleo, intencional y acotado).

## 7. Gating (reglas puras)

Nueva regla, NO se toca la existente:

```dart
// PremiumRules — agregar (sin modificar puedeAccederAReceta):
static bool puedeAccederRecetaColeccion({
  required String coleccionId,
  required bool isPremium,
  required List<String> packs,
}) => isPremium || packs.contains('yuyo_pack_$coleccionId');
```

**Decisión de negocio a validar**: premium incluye TODAS las colecciones
(actuales y futuras). Coherente con "premium = todo desbloqueado" y no
complica el mensaje. Los packs por colección siguen existiendo para quien
no quiere premium completo.

## 8. Detalle de receta de colección — el punto más delicado

El `RemedyDetailScreen` actual mezcla gating por sistema + historial +
intersticial. Para las recetas de colección:

- **Extraer** el cuerpo del detalle (`_buildRecipeDetail`) a un widget
  compartido (`RecipeDetailBody`) — cambio acotado en el archivo actual.
- La nueva pantalla `/biblioteca/:coleccionId/:recetaId` usa el widget
  compartido y su propio gating (regla del §7).
- Sin intersticial para recetas de colección en el MVP (decision: la
  biblioteca no toca AdsService).

## 9. Buscador propio

Filtro en memoria sobre las colecciones descargadas: nombre, descripción,
`idealPara`, ingredientes y `keywords` de cada receta. NO usa `SearchIndex`
ni `RecetasService.search` (que viven en el núcleo). Simple y aislado.

## 10. Precios en la tienda — requisito previo

La tienda muestra el precio de cada colección. Eso requiere el trabajo
pendiente de precios dinámicos (`PaymentService.getProducts()` →
`queryProductDetails` → `ProductDetails.price`; Mock con precios fake de
desarrollo). Es PREREQUISITO de la pantalla tienda (sin precios, la
tienda no vende).

## 11. Plan de implementación (pasos commiteables)

1. **Migración v6** (`colecciones` + RLS) + SQL de la colección de prueba
   "jugos naturales" (5 recetas) → el usuario la aplica en SQL Editor
2. **Precios dinámicos**: `PaymentService.getProducts()` + Mock con
   precios fake + GooglePlay con queryProductDetails + UI de precios en
   PremiumScreen y diálogo (desbloquea la tienda)
3. **Modelo + repositorio**: `Coleccion`, `BibliotecaRepository`
   (catálogo desde Supabase + cache SharedPreferences)
4. **Provider**: `BibliotecaProvider` (catálogo, compradas desde
   perfiles.packs, descarga, restore, notifica)
5. **Gating + reglas puras**: `puedeAccederRecetaColeccion` + tests
6. **Pantallas**: Biblioteca (home entry + mis colecciones + buscador) →
   Tienda → Colección → detalle con `RecipeDetailBody` extraído
7. **Tests**: modelo, repositorio (mock Supabase), provider, gating,
   widget básico; suite completa verde
8. **Build + instalar en S908E + copiar a D:\** + prueba end-to-end con
   la colección "jugos"

## 12. Decisiones abiertas (validar con el usuario)

1. **Premium ¿incluye colecciones?** (recomendación: SÍ — "premium = todo")
2. **Colección de prueba**: "Jugos naturales" — ¿quién escribe las 5
   recetas? ¿las extraemos del libro? ¿el usuario las redacta?
3. **Intersticiales**: ¿la biblioteca muestra anuncios si no es premium?
   (recomendación MVP: NO, para mantenerla aislada)
4. **Buscador de biblioteca**: ¿solo en la pantalla Biblioteca o también
   integrado a la tab Buscar con un toggle? (recomendación: solo en
   Biblioteca, cero mezcla)
5. **Nombre de la sección en home**: "Biblioteca" vs "Colecciones"
   (recomendación: "Biblioteca")

## 13. Qué NO se hace en este diseño

- Tags transversales ("sin TACC como etiqueta de recetas existentes") —
  requeriría normalizar recetas y es otro diseño
- Integrar recetas de colección a la búsqueda global (se puede decidir
  después, aislado)
- App hermana (diferida: los datos en Supabase la habilitan sin rehacer)
- Editar colecciones desde la app (solo lectura; se suben por SQL/dashboard)
