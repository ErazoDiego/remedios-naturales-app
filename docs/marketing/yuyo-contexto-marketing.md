# Yuyo — Contexto de Marketing

> **Qué es este archivo.** Un brief de contexto autocontenido para pegar en modelos de IA (Claude, ChatGPT, etc.) y pedirles copy, anuncios, ideas de contenido o campañas. Todo lo marcado como ✅ está **verificado contra el código de la app**, no inventado. Los bloques marcados con 🔲 los tiene que completar Diego.
>
> **Cómo usarlo.** Pegá el archivo entero como contexto y después el pedido. Al final hay plantillas de prompt listas.

Última actualización: 2026-10-07 · Versión del contenido: app `1.0.3+4`

---

## 1. Snapshot

| Campo | Valor |
|---|---|
| Nombre | **Yuyo** |
| Tagline | **Tu guía de bienestar natural** |
| Paquete Android | `com.dae.yuyo` |
| Categoría Play Store | 🔲 *(confirmar la categoría real declarada en Play Console)* |
| Idioma | Español rioplatense (voseo) |
| Mercado | **Argentina** (principal) · expansión planificada a México, Colombia, Chile y Perú — ver 7.2 |
| Modelo | Freemium con anuncios |
| Link de descarga | https://play.google.com/store/apps/details?id=com.dae.yuyo |

**Qué es, en una frase:** una app que organiza remedios naturales tradicionales por sistema corporal, para que puedas buscar por síntoma, entender qué preparar y cómo, sin depender de foros sueltos ni recetas de dudosa procedencia.

**Qué NO es:** no es una app médica, no diagnostica, no receta, no reemplaza al médico. Ver sección 8 — es importante y tiene consecuencias legales.

---

## 2. Contenido disponible ✅

Números reales extraídos de `assets/data/`:

| Contenido | Cantidad |
|---|---|
| Recetas y remedios | **133** |
| Condiciones y síntomas buscables | **248** |
| Hierbas y plantas | **89** |
| Preparaciones tradicionales | **89** |
| Sistemas corporales | **10** |
| Recetas de kéfir (colaboración Mr. Bulgarito) | **37, gratis** |

### Los 10 sistemas corporales ✅

| ID | Nombre completo | Emoji |
|---|---|---|
| `digestivo` | Sistema Digestivo | 🫁 |
| `nervioso` | Sistema Nervioso y Mental | 🧠 |
| `respiratorio` | Sistema Respiratorio | 🌬️ |
| `inmunitario` | Sistema Inmunitario | 🛡️ |
| `cardiovascular` | Sistema Cardiovascular y Metabólico | ❤️ |
| `hormonal` | Sistema Hormonal y Reproductivo | ♀️ |
| `musculoesqueletico` | Sistema Músculo-Esquelético | 💪 |
| `urinario` | Sistema Urinario y Renal | 💧 |
| `dermico` | Sistema Dérmico (Piel y Cabello) | 🧴 |
| `sensorial` | Sistema Sensorial y Bucal | 👁️ |

### Tipos de preparación ✅

La app diferencia **bebidas, tónicos, jarabes, tinturas, tópicos, baños, sprays** y **cocina con kéfir**. Cada tipo tiene color e ícono propios. Ejemplos reales de preparaciones: infusión, agua medicinal, caldo, shot, tónico, jarabe, gotas, tintura, compresa, cataplasma, bálsamo, ungüento, crema, gel, sérum, aceite de masaje, baño herbal, champú, spray nasal, roll-on, gárgaras, aromaterapia.

---

## 3. Funciones de la app ✅

- **Búsqueda por síntoma o condición** — 248 condiciones indexadas; buscás "siento X" y te lleva al sistema y las preparaciones.
- **Organización por sistema corporal** — 10 sistemas, cada uno con sus recetas.
- **Ficha completa por receta** — ideal para qué sirve, cuándo usarla, precaución, ingredientes, preparación paso a paso, almacenamiento.
- **89 hierbas** con su información.
- **Colecciones temáticas** — bloques de contenido agrupado (ej: el recetario de kéfir).
- **Biblioteca personal** — guardás favoritos y podés **escribir tus propias recetas**.
- **Lista de compras** — armás la lista de ingredientes (feature `lista_compras`).
- **Sincronización de cuenta** — favoritos e historial en la nube.

---

## 4. Modelo de negocio ✅

Freemium. **Los precios los define Play Console**; acá van los productos y las reglas.

### Plan gratis
- Hasta **5 favoritos**
- Hasta **5 recetas propias**
- **Con anuncios**
- Acceso a las colecciones gratuitas (incluido el recetario de kéfir)

### Productos de pago

| Producto | ID | Efecto |
|---|---|---|
| Membresía mensual | `yuyo_mensual` | 30 días, acceso total, **sin anuncios** |
| Membresía anual | `yuyo_anual` | 365 días, acceso total, **sin anuncios** |
| Lifetime | `yuyo_lifetime` | Compra permanente, acceso total, **sin anuncios** |
| Pack por sistema | `yuyo_pack_<sistema>` | Desbloquea **ese sistema para siempre**, **NO quita anuncios** |

**Regla de producto clave:** solo la membresía y el lifetime quitan anuncios. Los packs **no**. El acceso total cubre también los sistemas y colecciones **futuros**. Los packs comprados no se pierden al vencer una membresía.

**Implicancia para el marketing:** nunca prometer "sin anuncios" asociado a un pack. Es un malentendido que genera reseñas de una estrella.

---

## 5. Identidad visual ✅

Paleta **tierra / herbal**, no clínica. Huye del verde farmacia y del blanco azulado.

| Uso | Color | Hex |
|---|---|---|
| Fondo general | Crema | `#F6F3EC` |
| Header | Beige | `#EFEAE0` |
| Card física (verde salvia) | Verde claro | `#EAF3DE` |
| Título sobre salvia | Verde profundo | `#27500A` |
| Subtítulo sobre salvia | Verde medio | `#3B6D11` |
| Card sistémica (gris cálido) | Gris cálido | `#F1EFE8` |
| Texto principal | Casi negro cálido | `#2C2C2A` |
| Texto secundario | Gris | `#5F5E5A` |
| Alerta | Ámbar | `#BA7517` |

**Detalle de diseño:** los sistemas se dividen en dos familias visuales — **físicos** (verde salvia) y **sistémicos** (gris cálido). Los colores por tipo de preparación son semánticos y universales, independientes del sistema.

**Tipografía:** la app **no define una tipografía propia** — usa la fuente por defecto de Flutter/Material (Roboto en Android). No hay `fontFamily` ni Google Fonts en el proyecto. El sitio de Mr. Bulgarito, en cambio, usa **Baloo 2** (títulos) y **Quicksand** (cuerpo), con `border-radius: 32px` y estética lila/crema. 🔲 *(decidir si el ecosistema unifica tipografía o cada marca mantiene la suya)*

---

## 6. Voz y tono ✅

Esto es lo que separa un anuncio que suena a Yuyo de uno genérico. **Los modelos necesitan ejemplos, no adjetivos.**

### Cómo habla Yuyo

- **Voseo rioplatense**, siempre: *"Consultá"*, *"podés"*, *"repetí"*. Nunca "tú", nunca "usted".
- **Cálida pero no infantiloide.** Acompaña, no hace chistes.
- **Práctica y concreta.** Dice qué hacer, cuándo y con qué cuidado.
- **Respeta la inteligencia del lector.** Explica el límite sin retarlo.
- **Nunca alarmista, nunca mesiánica.** No promete curas.

### Ejemplos reales del copy de la app (usar como referencia de voz)

> "Tu guía de bienestar natural"

> "Estos remedios han sido transmitidos de generación en generación. La abuela sabia conocía el poder de las plantas y las preparaba con cuidado y dedicación. Hoy recuperamos esa sabiduría para el bienestar moderno."

> "Consultá a tu médico"

> "En el plan gratis podés guardar..."

> "Llegaste al límite de favoritos"

> "Infusión suave que estimula la digestión y alivia la sensación de pesadez después de comer. Ideal para comidas copiosas o digestiones lentas."

> "Buscar por condición, síntoma..."

### La narrativa de marca ya está escrita

El corazón emocional de Yuyo es **la transmisión generacional del conocimiento**: la abuela sabia, las plantas preparadas con cuidado, la sabiduría que se recupera para la vida moderna. Esa es la historia. No hay que inventar otra.

---

## 7. Audiencia y segmentación

### 7.1 Mercado principal ✅

| Campo | Valor |
|---|---|
| País | **Argentina** |
| Edad | **25–60 años** |
| Segmentación | **Amplia (Advantage+)** como base |

**Intereses a testear:** té e infusiones · herboristería · vida saludable · cocina natural · mate · medicina alternativa · jardinería.

> **Nota para los modelos:** la segmentación es amplia, pero **el mensaje no puede serlo.** Advantage+ decide a quién mostrarle; el anuncio tiene que elegir a quién le habla. Un texto que intenta hablarle al mismo tiempo a alguien de 27 con problemas digestivos y a alguien de 58 con dolores articulares no le habla a ninguno. Cada pieza debe tener **una persona concreta** en la cabeza.

### 7.2 Expansión planificada ✅

**Mercados:** México, Colombia, Chile y Perú.
**Razón:** fuerte cultura de plantas medicinales y CPM presumiblemente más bajos.
**Condición:** campaña separada, con la app localizada. (No compartir campaña con Argentina — mezcla las métricas y contamina la lectura de resultados.)

⚠️ **Verificar el CPM antes de planificar con ese supuesto.** No dar por hecho que son más bajos: México suele tener CPM más alto que Argentina por ser un mercado más grande y competido. Comparar con datos reales de una campaña de test, no con estimaciones.

### 7.3 Bloqueante para la expansión: la app está en voseo rioplatense ✅

**Toda** la app está escrita en español rioplatense con voseo: interfaz, las 133 recetas, las 89 hierbas y los disclaimers ("Consultá", "podés", "elegí", "tené en cuenta").

Un usuario mexicano o colombiano lo detecta al instante como contenido extranjero. **Esto no se arregla traduciendo los anuncios: hay que localizar el producto.** El alcance real es:

- Copy de interfaz (cientos de strings)
- Los 133 remedios con sus descripciones
- Las 89 hierbas
- Los disclaimers legales (que además pueden variar por país)
- Nombres regionales de plantas, que **no son los mismos** entre países

**Recomendación: no pautar en esos mercados hasta tener la app localizada.** Prometer en local y entregar en rioplatense genera reseñas negativas y quema el presupuesto.

### 7.4 ⚠️ El nombre "Yuyo" no resuena igual en todos los mercados

Dato verificado que afecta directamente la expansión — vale revisar antes de invertir:

| País | Qué significa "yuyo" | ¿Resuena con hierba medicinal? |
|---|---|---|
| **Argentina / Uruguay** | Hierba medicinal, infusión | ✅ Fuerte — es el sentido central del nombre |
| **Chile** | Hierba / infusión de hierbas | ✅ Fuerte |
| **Perú / Ecuador / Bolivia / Paraguay** | Origen quechua (`yuyu` = hortaliza), hierba silvestre | ✅ Bueno, es palabra propia |
| **Colombia** | Hierbas usadas como condimento (sur del país) | ⚠️ Parcial |
| **México** | **No es el término habitual** para hierba medicinal | ⚠️ Débil — el nombre no comunica el producto |
| **Costa Rica** | *Hongos en los pies* | ❌ **Colisión de marca** |

**Implicancia:** el nombre funciona como marca en cualquier lado, pero la **traducción instantánea a "hierbas medicinales" solo ocurre en el Cono Sur y la región andina.** En México, el mercado más grande de la lista, "Yuyo" no dice nada por sí solo — ahí el anuncio tendría que explicar el producto desde cero.

Esto no significa descartar México. Significa que **México necesita un mensaje distinto al de Chile o Perú**, y probablemente un test de percepción del nombre antes de escalar.

### 7.5 Personas: a quién le habla el texto

> **Cómo leer esta sección.** El **dolor** de cada persona está **verificado**: sale del campo `idealPara` de las 133 recetas, contado uno por uno. El **perfil** (edad, género, situación) es **hipótesis**, no dato. La hipótesis la valida o la rompe la analítica real de usuarios o las reseñas — no la intuición.

Dolores con más peso en el contenido:

```
digestión lenta ▓▓▓▓▓▓▓▓▓▓ 10    ansiedad leve    ▓▓▓▓▓ 5
gases           ▓▓▓▓▓▓▓▓▓  9    inflamación leve ▓▓▓▓▓ 5
defensas bajas  ▓▓▓▓▓▓▓▓▓  9    tensión nerviosa ▓▓▓▓ 4
resfrío inicial ▓▓▓▓▓▓     6    irritabilidad    ▓▓▓▓ 4
circulación     ▓▓▓▓▓▓     6    cambios hormon.  ▓▓▓▓ 4
```

---

#### 🎯 PERSONA PRIMARIA — "La de la panza revuelta"

**Foco de todas las campañas de arranque.**

| Campo | Detalle |
|---|---|
| **Cluster de contenido** | Digestivo — el más profundo de la app |
| **Dolores (datos reales)** | `digestión lenta` (10x), `gases` (9x), `sensación de pesadez` (5x), `inflamación leve` (5x), `hinchazón` (4x) |
| **Perfil (hipótesis)** | 35–50 años, mayoría mujeres |
| **Dolor** | Come y se hincha. No sabe qué le cae mal. Ya probó "de todo" |
| **Alternativa actual** | Google, YouTube, grupos de WhatsApp de remedios, probióticos de farmacia |
| **Frustración** | Información contradictoria. Nadie le dice qué combina con qué ni cuánto usar |
| **Disparador de descarga** | Quiere algo ordenado para la panza **hoy**, no un listado de 500 plantas |
| **Por qué paga** | Lo usa seguido → quiere guardar favoritos y tener sus recetas a mano |
| **Ángulo de anuncio** | *"Dejá de googlear 'infusión para la panza'. Está ordenado y con la dosis."* |

**Por qué es la primera:** es el contenido más profundo, la molestia es **de alta frecuencia** (buena retención), casi todo el mundo la vivió alguna vez (universo grande) y **no es alarmante** — se puede pautar sin acercarse a los límites de la sección 8.

---

#### 🔁 PERSONA SECUNDARIA — "La que cuida a todos"

**Segunda campaña. Su ventaja es la estacionalidad.**

| Campo | Detalle |
|---|---|
| **Cluster de contenido** | Inmunitario / respiratorio |
| **Dolores (datos reales)** | `defensas bajas` (9x), `primeros signos de resfriado` (6x), `garganta irritada` (4x), `congestión nasal` (4x), `recuperación lenta` (4x) |
| **Perfil (hipótesis)** | 30–55 años, madres y cuidadores |
| **Dolor** | Empieza la temporada de resfríos y no sabe qué dar. Duda si es seguro |
| **Alternativa actual** | Farmacia, "lo que hacía mi mamá", recetas de internet sin control |
| **Frustración** | No sabe la dosis para no pasarse. No puede comprobar qué es seguro |
| **Disparador de descarga** | Tenerlo listo **antes** de que aparezca el primer síntoma |
| **Por qué paga** | Quiere tener todo armado antes de necesitarlo |
| **Ángulo de anuncio** | *"Antes de que arranque la temporada: qué preparar y con qué cuidado."* |
| **Ventaja táctica** | La gripe y los resfríos son **estacionales** → un momento de adquisición claro cada año |

---

#### 📦 Candidatas en reserva (no activas todavía)

**C — "La que no puede apagar la cabeza"** · Cluster **nervioso**
`ansiedad leve` (5x), `tensión nerviosa` (4x), `irritabilidad` (4x), `insomnio leve` (3x), `estrés` (3x). Perfil hipotético: 28–45, urbana, trabaja. **⚠️ Riesgo:** es el mercado más competido (apps de meditación, sueño, bienestar). Si se activa, diferenciar por lo **herbal**, nunca por "bienestar" genérico.

**🐴 Caballo oscuro — Hormonal** · `cambios hormonales` (4x), `ciclos irregulares` (3x), sistema hormonal con 14 recetas.
Perimenopausia y ciclo hormonal es donde la gente **más paga** — hay demanda insatisfecha y disposición a gastar. Quedó fuera de las activas solo por ser **más sensible para pautar** (cercano a atributos personales de salud). **Comercialmente puede ser el mejor de todos.** Vale probarlo cuando las dos primeras estén estables.

---

#### Cómo usar esto en los modelos

- **Toda pieza de copy debe tener UNA persona en la cabeza.** Si el texto sirve para la persona A y para la C a la vez, no sirve para ninguna.
- **El dolor sale de los datos**; no inventar síntomas que la app no cubre.
- **La edad y el género son hipótesis.** No los afirmes como hechos en el copy (y en varias plataformas, apuntar a "atributos personales de salud" está restringido — ver sección 8).
- **Arrancar por A. B como segunda campaña. C y Hormonal en reserva.**

---

## 8. Límites legales y de plataforma ⚠️ CRÍTICO

**Esto es lo más importante de todo el archivo.** Yuyo es una app de salud. Las afirmaciones de salud están reguladas y las plataformas de publicidad (Google Ads, Meta) las restringen activamente. Un anuncio creativo con el claim equivocado puede costar la cuenta publicitaria.

### Lo que la app dice de sí misma (texto real, a respetar)

> "Estos remedios son complementarios y **NO reemplazan** la consulta médica profesional."

> "Información tradicional, **no reemplaza** la indicación de un profesional de la salud."

> "Los remedios aquí descritos **no sustituyen** el consejo médico profesional."

### Prohibido en cualquier copy de marketing

- ❌ "Cura", "elimina", "trata", "revierte" + nombre de enfermedad.
- ❌ "Sustituye medicamentos", "dejá la medicación", "sin médicos".
- ❌ Antes/después de una condición médica.
- ❌ Promesas con plazos ("resultados en 7 días").
- ❌ Dirigirse a personas con condiciones graves.

### Permitido y recomendable

- ✅ Enfoque en **bienestar, hábitos, tradición y organización de la información**.
- ✅ "Conocimiento tradicional", "guía", "para acompañar", "bienestar".
- ✅ Incluir el disclaimer cuando el copy menciona una condición.

### Obligatorio según dónde pauta ✅ *(verificado 2026-10-07 contra fuentes oficiales)*

#### 🟦 Meta Ads (Facebook / Instagram) — el riesgo NO es el que se cree

Mucha gente teme que la rechacen por "claims de enfermedad". **El rechazo más común es otro: la política de *Personal Attributes*.**

| Regla verificada | Qué significa para Yuyo |
|---|---|
| **Prohibido afirmar o implicar atributos personales**, incluidos **salud física o mental (condiciones médicas)** | ❌ *"¿Cansada de la hinchazón?"* → rechazo. ✅ *"133 remedios tradicionales ordenados por sistema"* → seguro |
| Dirigirse a **personas de 18+** en productos de salud/dieta | Restringir la edad en la campaña, sin excepción |
| **Lista prohibida de "cura/elimina"** (exhaustiva): diabetes, herpes, tiroides, psoriasis, ébola, cáncer, autismo, Alzheimer, Parkinson, ELA, VIH | Nunca nombrar estas enfermedades con verbos de curación. **Ojo:** la restricción *no* aplica a hablar de **manejar síntomas** de esas condiciones — pero por prudencia, evitarlas todas |
| **Prohibido el clickbait de salud** — lenguaje sensacional, claims exagerados, promesas de resultados en un plazo sin aclaración | Adiós al "en 7 días" y al "revolucionario" |
| **Los claims deben ser veraces y estar respaldados por evidencia** | 🔴 **Conexión crítica con el código** → ver abajo |
| **Endosos de profesionales** (un médico recomendando) se rechazan seguido | No usar figuras de autoridad recomendando un resultado concreto. Sí vale contenido educativo general |

> 🔴 **Por qué esto se conecta con el código de la app.** Meta exige que los claims estén **respaldados por evidencia**. Y el campo `evidencia` de Yuyo **está vacío en las 133 recetas**. Conclusión directa: **Yuyo no puede publicar ningún claim de eficacia hoy.** No porque esté prohibido, sino porque **no tiene con qué sustentarlo**. Si algún día se completa ese campo, se abre la puerta a un claim basado en evidencia que *casi ningún competidor puede hacer*. Hasta entonces, el copy se apoya en **tradición y organización**, no en eficacia.

*(Fuentes: Meta Transparency Center — Health and Wellness, Privacy Violations and Personal Attributes, Drugs and Pharmaceuticals.)*

#### 🟨 Google Ads — es más permisivo de lo que dice el folklore

**Corrección a un dato que este mismo brief tenía mal ⚠️:** yo había escrito que *"los servicios de salud tienen certificación obligatoria en muchos países"*. **Es impreciso.** La verificación contra la política oficial y fuentes del sector lo acota:

| Regla verificada | Qué significa para Yuyo |
|---|---|
| **LegitScript / certificación obligatoria aplica a farmacias y telemedicina**, NO a marcas de suplementos | **Yuyo probablemente NO necesita LegitScript.** La certificación se dispara por términos de medicamentos con receta, no por vender un producto herbal |
| Los **suplementos dietarios son una categoría permitida pero muy regulada** — no prohibida | Se puede pautar, con cuidado |
| **Prohibidos**: efedra, hCG para bajar de peso, y productos herbales con ingredientes farmacéuticos activos o peligrosos | Yuyo no usa ninguno de estos — **está limpio** |
| **Prohibido el lenguaje de medicamentos con receta** (ads, landing pages, keywords) sin certificación | No usar palabras tipo "medicamento", "receta", "cura" |
| La mayoría de los rechazos vienen de la política de **Misrepresentation / claims no confiables**, no de una prohibición específica de suplementos | El riesgo real es **exagerar**, no el rubro en sí |
| Violaciones no graves: **aviso de 7 días antes** de suspender la cuenta | Margen para corregir si algo se rechaza |

**Conclusión estratégica:** **Google Ads es el canal más seguro para Yuyo, no el más riesgoso.** La barrera que se suele mencionar (certificación) casi no aplica al caso. El único cuidado serio es no usar lenguaje de medicamento ni claims exagerados.

*(Fuentes: Google Ads Policy Help — Healthcare and Medicines; análisis del sector sobre la política de suplementos 2026.)*

#### 🟩 Google Play (ficha) 🔲

- 🔲 Revisar la política de contenido de salud para la ficha de la tienda (descripción, capturas). Es menos restrictiva que la publicidad, pero conviene confirmarla.

### Las 3 reglas de oro para cualquier copy

1. **Hablá del producto, no de la persona.** *"Remedios ordenados por sistema"* ✅ — *"¿Sufrís de X?"* ❌
2. **Nunca prometas un resultado.** Ni plazo, ni curación, ni "sin efectos secundarios". El claim fuerte es **organización, tradición y precaución**, no eficacia.
3. **No inventes evidencia que la app no tiene.** Hoy `evidencia` está vacío → ningún claim de eficacia respaldada.

**Definir acá la política de claims de DAE:** 🔲 *(decisión de negocio: ¿se acepta el costo de que el copy sea más "flojo" a cambio de cero riesgo de baneo?)*

---

## 9. Posicionamiento

> **Estado de verificación:** el análisis de competidores de esta sección lo aportó Diego y **no está verificado uno por uno** (él mismo marcó las apps de identificación de plantas como "conocimiento general, no verificado ahora"). Lo que **sí** está verificado en esta sección es la columna de Yuyo (sección 9.4), chequeada contra el código.

### 9.1 Competidores directos: apps de "plantas medicinales / remedios naturales"

Hay muchísimas en Play Store y App Store, casi todas **genéricas y en inglés**.

**Ejemplo observado por Diego:** una app que combina identificación de plantas por foto con IA + descripciones de virtudes medicinales + recetas de infusiones y decocciones, posicionándose con la promesa de **tratar problemas de salud sin efectos secundarios**.

### 9.2 Competidores indirectos: identificadores de plantas ✅ *(verificado 2026-10-07)*

Datos reales de tiendas:

| App | Descargas | Rating | Modelo | Posicionamiento real |
|---|---|---|---|---|
| **PictureThis** (Glority) | **50M+** Android / **80M+** total | 4.5★ Android · 4.8★ iOS (1.1M reseñas) | Pago: **~USD 29,99/año** (tramos de 3,99 a 39,99). Trial **exige tarjeta** | Identificar + cuidar + diagnosticar **enfermedades de PLANTAS** |
| **PlantNet** (Cirad-France) | **10M+** | 4.6★ (264K reseñas) | **Gratis y sin anuncios** | **Ciencia ciudadana** — institución científica, sin fines comerciales. ~20.000 especies |

**Camino por las dos posiciones distintas:**
- Ellos: *"no sé qué planta es" → la identifico (y le diagnostico enfermedades)*
- Yuyo: *"ya sé qué planta es → ¿cómo la preparo para MI salud y con qué precauciones?"*

**Son trabajos distintos.** PictureThis es un **doctor de plantas**; Yuyo es una **guía de remedios para personas**. No se pisan en el trabajo real que hacen para el usuario. El solapamiento es superficial (ambos hablan de plantas).

#### 💰 El dato más importante: PictureThis es top-grossing en Educación

**#2 y #3 top grossing en categoría Educación**, con ~USD 30/año por usuario, y 80M+ descargas.

**Esto prueba algo enorme para Yuyo: la gente PAGA por una app de plantas.** No hay que convencer al mercado de que este tipo de app puede cobrar — **PictureThis ya lo demostró a escala.** Yuyo no tiene que validar el modelo de negocio de "pago por app herbal"; tiene que capturar una porción de un mercado que ya paga.

#### ⚠️ Corrección: la ventaja de idioma es más débil de lo que sugerí

Antes escribí que los competidores están "casi todos en inglés". **Es impreciso.** Tanto **PictureThis como PlantNet están localizados al español** (PictureThis aparece en la tienda como "PictureThis Identificar Planta"). No hay una barrera de idioma real.

**Lo que sí diferencia a Yuyo no es el idioma — es el contenido:**

| Competidor | Yuyo |
|---|---|
| Identifica cualquier planta | Organiza **remedios tradicionales por sistema corporal** |
| Ficha botánica (riego, plagas) | Ficha de remedio (**dosis, cuándo usar, precaución, almacenamiento**) |
| Enfoque en la planta | Enfoque en **la persona y su molestia** |
| Vocabulario botánico neutro | **Rioplatense**, con los yuyos y el habla de acá |

**Traducción estratégica:** el foso de Yuyo es **el modelo de contenido y la curaduría**, no el idioma. "Está en español" no es un diferenciador; "está organizado por síntoma y sistema, con dosis y precaución" sí lo es. **El copy no debe vender el idioma como ventaja**, porque los competidores también están en español.

#### ⚠️ Tradeoff que conviene tener presente

La identificación por foto es **el mejor gancho de adquisición de la categoría** — 80M de descargas para PictureThis son la prueba. Renunciar a competir ahí es foco válido, pero es una renuncia real, no gratis. Si algún día las instalaciones se estancan, ese es el primer feature a evaluar como embudo de entrada.

*(Fuente: datos de Google Play / App Store / AppBrain, consultados 2026-10-07. Los precios de PictureThis fluctúan por tramos; el ~USD 30/año es el orden de magnitud.)*

### 9.3 Los sustitutos reales — la competencia más fuerte

Acá no compite contra apps, compite contra **hábitos gratuitos**:

| Sustituto | Por qué es fuerte |
|---|---|
| **Google y YouTube** | "cómo preparar infusión de boldo" tiene miles de resultados |
| **TikTok e Instagram** | videos de remedios caseros, muchos sin ningún control de calidad |
| **ChatGPT y otras IAs** | cada vez más gente les pregunta recetas y usos de hierbas |
| **Libros y guías de herboristería** | de ~28 € a PDFs de 5 USD. Formato fijo, pero con tradición y confianza |
| **Herboristerías, dietéticas y "la abuela"** | consejo oral y local, con muchísimo peso en Argentina |
| **Grupos de Facebook y WhatsApp** | comunidades de remedios naturales |

> **El sustituto más subestimado es la IA.** Cuando alguien puede preguntarle a ChatGPT "¿para qué sirve el boldo?" y recibir una respuesta en lenguaje natural, **la información dejó de ser un producto.** Yuyo no puede vender acceso a información. Lo que puede vender es **curaduría, estructura y confianza**: información verificable, con dosis, precauciones explícitas y contexto local. Ese es el cambio de marco.

*(Sustituto que no está en la lista y también compite: **"no hacer nada"**. Las apps de bienestar sufren de baja urgencia — el problema nunca es tan grave como para buscar una app hoy. Por eso el copy de adquisición necesita un disparador concreto, no un mensaje aspiracional permanente.)*

### 9.4 Dónde puede ganar Yuyo

**Verificado contra el código:**

| Diferenciador | Estado |
|---|---|
| **Curaduría y estructura** — 10 sistemas, 133 recetas, 248 condiciones | ✅ |
| **Ficha completa por receta** — incluye `dosis`, `cuandoUsar`, `precaucion`, `almacenamiento`, `idealPara` | ✅ |
| **Tono responsable** — disclaimers médicos explícitos en la app | ✅ |
| **Herramientas personales** — favoritos, recetas propias, lista de compras, sincronización | ✅ |
| **Idioma y contexto local** — español rioplatense, yuyos que se consiguen acá | ⚠️ ver 9.6 |

**Correcciones a datos que circulaban en el análisis:**
- ❌ **NO existe un campo "parte usada"** en el modelo de datos. No usar en el copy.
- ⚠️ **El campo `evidencia` existe pero está VACÍO en las 133 recetas.** Es una capacidad *latente*, no un diferenciador actual. Si algún día se completa, sería un diferenciador fuerte (evidencia por receta) — pero **hoy no se puede comunicar.**

### 9.5 El ángulo más filoso: la promesa responsable es también la ventaja de cumplimiento

Hay algo casi perfecto en el análisis de Diego:

```
La app competidora promete:  "tratar problemas de salud SIN efectos secundarios"
Meta prohíbe:                exactamente ese tipo de promesa
Yuyo:                        no la usa — dice dosis y precauciones
```

O sea: **lo que hace a Yuyo más responsable es lo mismo que lo hace más pautable.** Es raro y valioso que ética y eficacia publicitaria apunten al mismo lado. La mayoría de las marcas tiene que elegir entre cumplir y convertir.

**Cómo explotarlo en el copy:** no como superioridad moral hueca ("somos los buenos"), sino como **honestidad concreta**. Yuyo dice la dosis *y* la precaución. Dice cuándo usarlo *y* cuándo no. Eso es lo que ningún video de TikTok hace, y es exactamente por lo que alguien pagaría.

### 9.6 Tensión estratégica: el idioma local es un foso Y un bloqueante

El español rioplatense aparece como **fortaleza** acá y como **bloqueante de expansión** en la sección 7.3. Las dos cosas son ciertas al mismo tiempo.

- **Hacia adentro:** es un foso defensivo contra las apps en inglés. Nadie de afuera lo copia fácil.
- **Hacia afuera:** es la pared que impide escalar a México, Colombia, Chile y Perú sin localizar el producto entero.

No hay que resolverlo ahora, pero conviene tenerlo consciente: **lo que te hace fuerte en Argentina es lo que te frena para salir.** Es una decisión de negocio, no un detalle de producto.

### 9.7 Por qué Yuyo y no otra cosa 🔲 *(afinar)*

Borrador a validar con Diego:

> **Yuyo no compite con las apps de plantas. Compite con el caos de buscar en Google, YouTube y grupos de WhatsApp.** Ordena 133 remedios tradicionales por sistema corporal, con dosis y precauciones reales, en el español que hablás y con los yuyos que se consiguen acá.

**A verificar antes de invertir en pauta:**
- 🔲 Leer las reseñas 1★ de las apps competidoras → de ahí salen los dolores reales, gratis.
- 🔲 Verificar el estado real de PictureThis / PlantNet / Planta (instalaciones, rating, precios).
- 🔲 Comparar precios: ¿Yuyo es más barato o más caro que los competidores pagos?

---

## 10. Objetivos de marketing ✅ *(definido por Diego, 2026-10-07)*

**Estrategia en dos fases.** No es lo mismo escribir para conseguir instalaciones que para convertir a premium — el objetivo cambia todo el copy.

### FASE 1 (ahora) — Volumen y flujo de usuarios

> **Objetivo primario: descargas.** Que entre gente, que haya flujo de usuarios.

**La lógica:** hoy **no hay métricas**. Optimizar para conversión sin datos es adivinar. Primero se llena el embudo y se junta información; después se afina.

### FASE 2 (cuando haya datos) — Conversión a premium

> Con las métricas arriba de la mesa, **hilamos más fino** para convertir esas ventas.

**La lógica:** los datos de la Fase 1 (qué persona descarga, qué mira, dónde abandona) son los que permiten optimizar la conversión con criterio en vez de intuición.

### Por qué esta secuencia es la correcta

1. **Sin datos, la conversión es una apuesta.** Un embudo vacío no dice nada.
2. **Las descargas generan los datos** que hacen posible la Fase 2.
3. **Cada usuario free es una semilla** — y además, feedback real sobre qué busca la gente.

### ⚠️ La trampa a evitar en la Fase 1

**Optimizar solo por cantidad de descargas puede traer usuarios que NUNCA van a pagar.** Si la campaña atrae a gente que no tiene el problema que Yuyo resuelve, tenés volumen pero no conversión futura.

**La regla:** aunque el *objetivo de campaña* sea instalaciones, **desde el día 1 hay que medir las señales que predicen pago:**

- ¿Qué persona (A/B/C/Hormonal) descarga más y **vuelve a abrir**?
- ¿Cuánto tarda en llegar al muro premium?
- ¿Qué contenido mira: digestivo, defensas, nervioso?
- ¿Cuántos días retiene?

**Esas 4 señales son el puente entre la Fase 1 y la Fase 2.** Sin instrumentar esto, cuando llegue el momento de convertir no vas a saber a quién.

### Canales: Meta, con una corrección técnica importante ⚠️

**Decisión de Diego:** la gente que busca estos productos está en **Facebook** — es la red más antigua y las dolencias suelen aquejar a la población de mayor edad. *(Se incluye en ese grupo. 😄)* Plan: **anuncios en Meta con destino a la Play Store** para la descarga.

**El razonamiento es correcto.** Facebook efectivamente skewa a mayor edad que Instagram y TikTok. Y para una app de remedios tradicionales, ese público es exactamente el objetivo.

#### 🔴 Corrección técnica #1 — el objetivo de campaña NO es "Tráfico"

**"Poner un anuncio con un link y listo" es el error más caro y más común.**

| ❌ Lo que parece natural | ✅ Lo correcto |
|---|---|
| Campaña de **Tráfico** con un link a Play Store | Campaña de **Promoción de app** (App Promotion / App Installs) |
| Meta optimiza para **clicks** | Meta optimiza para **instalaciones** |

**Por qué importa:** con una campaña de Tráfico, Meta te trae gente que **hace clic**, no gente que **instala**. Pagás por clicks de curiosos. Con **Promoción de app**, Meta usa su algoritmo para buscar a las personas **con más probabilidad de descargar** — y te reporta el **costo por instalación (CPI)**, que es el número que necesitás para la Fase 2.

**Dentro de "Promoción de app", elegir el objetivo de rendimiento "Maximizar el número de instalaciones".** (Existe también "eventos en la app", para más adelante, cuando haya eventos que valga la pena optimizar.)

#### 🔴 Corrección técnica #2 — la "fase de aprendizaje" (por qué $50 rinde menos de lo que parece)

Meta necesita juntar **~15-50 eventos por ad set cada 7 días** para "aprender" a quién mostrarle el anuncio. Mientras no los junta, está en **"aprendizaje limitado"**: entrega inestable, resultados erráticos.

*(En 2026 Meta bajó este umbral: Shopping de 50 a 25, y las campañas de app Advantage+ quedaron en torno a **15 eventos** por semana. Eso ayuda a presupuestos chicos.)*

**La trampa que esto crea:**

- Con **$10/día y un CPI de ~$1**, juntás ~10 instalaciones por día → **~70 por semana** → **sí** superás el umbral. ✅
- Con **$10/día repartidos en 3 ad sets**, cada uno junta ~23 → **más difícil** salir de aprendizaje. ❌

**La regla de oro que sale de esto:** **concentrá, no repartas.** Un solo ad set, una sola audiencia, 2-3 creativos. Nada de "probemos 5 públicos a la vez" — con presupuesto chico eso garantiza aprendizaje limitado en todos.

**Y la regla de oro n.º 2: NO toques la campaña durante el aprendizaje.** Editar el ad set (cambiar público, presupuesto o creativos) **reinicia el reloj de aprendizaje**. Si mirás los números al día 2 y "arreglás" algo, volvés a cero. **Se deja correr 7 días antes de juzgar nada.**

#### Sobre la atribución (para no medir a ciegas)

- La **UTM de Play** que ya montaste (`recetario_kefir_v1`) es un mecanismo de **Google Play**, no de Meta. Sirve para el tráfico de Mr. Bulgarito, **no** va a atribuir las instalaciones de Meta.
- Para las campañas de app de Meta, lo ideal es el **SDK de Meta (o un MMP tipo AppsFlyer/Adjust)** dentro de la app. Sin eso, Meta igual reporta instalaciones, pero con atribución más débil.
- **Para la Fase 1 no es bloqueante** — se puede arrancar sin SDK. Pero anotado: cuanto antes se instrumente, mejor calidad de datos para la Fase 2.

### Presupuesto: $50 como matrícula, no como inversión

**Decisión de Diego:** $50 USD para la primera campaña, quizás de a $10, mirando métricas. Quiere **aprender** antes de arriesgar capital. El presupuesto sube cuando entienda cómo funciona y cuando la app empiece a convertir.

**El encuadre correcto:** esos $50 **no son para crecer — son para aprender.** Estás comprando información, no usuarios. Y como matrícula, es un precio razonable.

**Realidades de arrancar con $50:**

| Expectativa | Realidad |
|---|---|
| "Voy a ver si funciona" | $50 alcanza para **entender el mecanismo**, no para concluir si el negocio funciona |
| "Voy a ajustar todos los días" | Ajustar reinicia el aprendizaje. **Se mira, no se toca** |
| "Voy a probar 4 públicos" | Cada público fragmenta el presupuesto y ninguno junta datos suficientes |
| Resultados estables | Espéralos **inestables** al principio. Es normal, no es fracaso |

**Cómo estirar al máximo esos $50:**

1. **Objetivo:** Promoción de app → Maximizar instalaciones (NO Tráfico).
2. **Un solo ad set.** Audiencia amplia, dejá que el algoritmo busque.
3. **2-3 creativos distintos** en ese único ad set (ahí SÍ conviene testear — es dentro del mismo ad set, no fragmenta el aprendizaje).
4. **~$10/día durante 5 días.** No editar.
5. **La única métrica que importa en la Fase 1:** el **CPI** (costo por instalación). Ese número es el insumo de la Fase 2.
6. **Paciencia:** 7 días antes de sacar conclusiones.

**Nota:** el mínimo de Meta para campañas optimizadas por conversión es ~$5/día. $10/día está cómodo arriba de eso.

### Definiciones operativas

| Campo | Valor |
|---|---|
| **Objetivo primario (Fase 1)** | Descargas / flujo de usuarios |
| **Objetivo secundario (Fase 2)** | Conversión a premium, guiada por métricas |
| **Métrica de la Fase 1** | **CPI (costo por instalación)** + retención temprana (D1/D7) |
| **Métrica de la Fase 2** | Tasa de conversión free → pago |
| **Canal (Fase 1)** | **Meta Ads** — objetivo *Promoción de app* (Facebook + Instagram). Público afín: 35+ |
| **Canal (evaluar en Fase 2)** | **Google Ads** — es un canal más permisivo para el rubro de lo que dice el folklore (ver sección 8) |
| **Presupuesto (Fase 1)** | **$50 USD**, ~$10/día, un solo ad set. Es *matrícula de aprendizaje*, no inversión de crecimiento |
| **Presupuesto (Fase 2)** | Sube cuando haya CPI conocido y la app empiece a convertir |
| **Qué funciona hoy** | Poco medido. El único canal instrumentado es el sitio de Mr. Bulgarito (UTM `recetario_kefir_v1`) |

### Más adelante: expansión y traducción

**Visión de Diego para después:** pensar actualizaciones para expandir a otros mercados, **sobre todo traducir a otros idiomas.**

**Advertencia metodológica (conecta con la sección 7.3):** **traducir no es localizar.** Cambiar el texto a portugués o inglés no alcanza si la app está construida en voseo rioplatense de punta a punta (interfaz + 133 recetas + 89 hierbas + disclaimers). La expansión a otros mercados requiere **localizar el producto completo**, no solo traducir los anuncios. No es bloqueante hoy — pero es la decisión de negocio que define si Yuyo escala fuera de Argentina.

### Contexto existente

- El sitio **Mr. Bulgarito** (kéfir) ya tiene una sección de cross-promo a Yuyo con link a Play Store y atribución UTM (`utm_campaign=recetario_kefir_v1`). Ver `~/mr-bulgarito`.
- El recetario de kéfir de 37 recetas **es gratis** y su descripción en la app lo atribuye a Mr. Bulgarito.
- **Recomendación metodológica:** instrumentar la atribución **antes** de invertir en pauta. Sin ello, la Fase 2 va a ser a ciegas otra vez.

---

## 11. Historia y origen ✅ *(contada por Diego, 2026-10-07)*

> **Por qué existe Yuyo.** La narrativa de "la abuela sabia" que ya está en la app **no es un recurso de marketing: es su vida real.** Diego tiene un libro de recetas de su abuela. La historia de abajo no se inventó para vender — es literalmente de dónde salió el producto. Eso es lo que la vuelve imposible de copiar.

### La historia, en las palabras de Diego

Nació en **Buenos Aires**, pero se crió en el **norte argentino** — más precisamente en **Santa María, Catamarca**. Un lugar de **mucha cultura medicinal ancestral** y de mucha cultura indígena. Allí, los yuyos no son una afición: **son parte de la vida cotidiana.**

> *"No conozco casa que no tenga una repisa con frasquitos de yuyos: para el mate, para el dolor estomacal. O una planta de aloe vera para las quemaduras, para cuidar la piel."*

Recuerda a los **vendedores ambulantes que bajaban del cerro** a vender yuyos que ellos mismos buscaban en las montañas. **Toda una cadena de conocimiento, de la montaña a la mesa.**

**Hoy vive otra vez en Buenos Aires**, por estudios. Y consume muchas de las plantas que puso en la app: **jengibre, menta, boldo, manzanilla.** El mate, dice, es un compañero inculcado como tradición.

Y después, la frase que lo explica todo:

> *"No sé, me gusta programar y crear cosas. Y tengo un libro de recetas de la abuela. Me dije: esto se puede transformar en una app. Y es lo que pasó."*

### El arco de la historia (por qué conmueve)

```
   EL NORTE                          LA CAPITAL
   Santa María, Catamarca            Buenos Aires
   ────────────────────              ─────────────────
   Los yuyos como vida cotidiana     Los yuyos como recuerdo
   La repisa de frasquitos           El código y las herramientas
   La sabiduría de la abuela    →    El oficio de programar
   Los vendedores del cerro          El deseo de crear algo
                                              │
                                              ▼
                                          YUYO
                              (juntar lo que dejó atrás
                               y convertirlo en algo
                               que otros puedan usar)
```

**En una frase:** Yuyo es la forma que encontró Diego de **llevarse el norte consigo a la capital** — y de que el libro de su abuela siga vivo.

### Los activos estratégicos que hay escondidos acá

| Activo | Por qué vale oro |
|---|---|
| **Experiencia real** | Diego **consume** estas plantas. No es un granjero de contenido armando una app herbal de escritorio. Eso se transmite y se nota |
| **El libro de la abuela** | El origen concreto y tangible del contenido. Es un **objeto heredado**, no una base de datos comprada |
| **La repisa de frasquitos** | Imagen universal en el norte, reconocible al instante por millones. **Candidata a pieza visual central** del marketing |
| **Los vendedores del cerro** | Muestra la cadena del conocimiento tradicional, de la montaña a la casa. Autenticidad pura |
| **El puente norte → capital** | Resuelve la pregunta "¿por qué alguien de Buenos Aires haría esto?" — la respuesta es la distancia y el cariño |

### Ángulos de copy que salen de acá

- **La imagen ancla:** *"No hay casa en el norte sin una repisa con frasquitos de yuyos."* → arranca un anuncio y la gente se ve reflejada.
- **El origen:** *"Tengo el libro de recetas de mi abuela. Lo convertí en una app."* → corto, humano, verificable.
- **La motivación:** *"Me crié donde los yuyos son parte de la vida. Ahora vivo lejos y quise que no se pierdan."*

*(Ninguno de estos rompe las reglas de la sección 8: no prometen resultados ni hablan de enfermedades. Hablan de la historia.)*

### ⚠️ Una observación estratégica para pensar *(no es un pedido)*

La historia es del **NORTE** (Catamarca, cultura ancestral), pero la voz de la app es **rioplatense/porteña** (sección 6). Hay una pequeña tensión ahí.

No es un error — es coherente con que Diego escribe desde donde vive hoy. Pero queda un ángulo sin explorar: la historia del norte es **más rica y más diferencial** que la genérica "abuela sabia". Vale la pena decidir si el marketing se apoya fuerte en el origen norteño (autenticidad máxima) o lo mantiene genérico (menos riesgo de que a un porteño no le resuene). **Diego decide; no es urgente.**

---

## 12. Reglas para los modelos de IA

Cuando uses este archivo, recordales esto:

1. **Hablá en voseo rioplatense.** Nunca "tú" ni "usted".
2. **No inventes datos.** Si falta un número, una función o un precio, preguntá — no lo completes con supuestos.
3. **Respetá los límites de la sección 8.** Ningún claim de cura, tratamiento o reemplazo médico.
4. **Usá los números reales**: 133 recetas, 248 condiciones, 89 hierbas, 10 sistemas.
5. **Suena a Yuyo, no a farmacia.** Cálido, práctico, respetuoso. La sección 6 tiene los ejemplos.
6. **Si el copy menciona una condición de salud, incluí el disclaimer.**
7. **No prometas "sin anuncios" con los packs.** Solo con membresía o lifetime.

---

## 13. Plantillas de prompt

**Anuncio para redes:**
```
[pegar este archivo]
Escribime 5 variantes de anuncio (máximo 40 palabras) para Instagram,
apuntando a [PÚBLICO de la sección 7]. Ángulo: [búsqueda por síntoma].
Respetá la voz y los límites de la sección 8.
```

**Guiones de video corto:**
```
[pegar este archivo]
3 guiones de 20 segundos para TikTok/Reels sobre [tema].
Uno debe usar la narrativa de la sección 6.
```

**Optimización de la ficha de Play:**
```
[pegar este archivo]
Revisá esta ficha y proponé mejoras de ASO usando los números reales
de la sección 2 y la voz de la sección 6. Actual: [pegar ficha].
```

**Definir la audiencia (para la sección 7):**
```
[pegar este archivo]
Teniendo en cuenta el contenido y el modelo freemium, proponeme 3
perfiles de audiencia concretos con su dolor, sus alternativas
actuales y por qué pagarían. Marcá qué suposiciones estás haciendo.
```

---

## 14. Changelog

- **2026-10-07** — Creación. Datos verificados contra `lib/core/constants/app_constants.dart`, `assets/data/*.json` (133/248/89/10/37), `premium_rules.dart` y el copy real de las pantallas.
- **2026-10-07** — Sección 7 completada con la segmentación de Diego (Argentina 25–60, Advantage+, intereses) y expansión (MX/CO/CL/PE). Se agregó el bloqueante del voseo, la advertencia sobre el CPM no verificado y el análisis de resonancia del nombre "Yuyo" por país.
- **2026-10-07** — Sección 9 completada con el análisis competitivo de Diego (directos / indirectos / sustitutos). Verificado contra el código: el campo `evidencia` existe pero está vacío en las 133 recetas, y **no existe** un campo "parte usada". Se agregó la tensión estrategia local/expansión y el ángulo de la promesa responsable.
- **2026-10-07** — Sección 7.5 completada con 2 personas activas + 2 en reserva. Los dolores se extrajeron del campo `idealPara` de las 133 recetas (digestión lenta 10x, gases 9x, defensas bajas 9x). **Primaria: "La de la panza revuelta" (digestivo). Secundaria: "La que cuida a todos" (defensas).** Los perfiles (edad/género) quedaron marcados como hipótesis, no como dato.
- **2026-10-07** — Sección 8 verificada contra fuentes oficiales (Meta Transparency Center, Google Ads Policy Help). **Corrección propia:** la certificación LegitScript de Google Ads aplica a farmacias/telemedicina, NO a marcas de suplementos — Yuyo probablemente no la necesita. Se documentó que el riesgo real en Meta es la política de *Personal Attributes* (no los claims de enfermedad), y la conexión crítica: Meta exige claims respaldados por evidencia, y el campo `evidencia` de Yuyo está vacío → **no puede publicar ningún claim de eficacia hoy**.
- **2026-10-07** — Sección 9.2 verificada con datos reales de tiendas: PictureThis 50M+/80M+ descargas y **#2 top-grossing en Educación** (~USD 30/año), PlantNet 10M+ gratis. **Corrección propia:** ambos están localizados al español → el idioma NO es un foso. El diferenciador real es el modelo de contenido (síntoma → sistema → remedio con dosis/precaución).
- **2026-10-07** — Sección 10 definida por Diego: **estrategia en 2 fases** (Fase 1 = descargas/volumen; Fase 2 = conversión a premium guiada por métricas). Se documentó la trampa de la Fase 1 (optimizar solo por volumen trae usuarios que nunca pagarán) y las 4 señales de embudo a instrumentar desde el día 1.
- **2026-10-07** — Sección 11 completada con la historia de origen real de Diego: criado en Santa María (Catamarca), cultura medicinal ancestral, la repisa de frasquitos, los vendedores del cerro, su abuela y su libro de recetas, hoy en Buenos Aires por estudios. **Hallazgo clave: la narrativa de "la abuela sabia" de la app no es marketing — es la vida real de Diego.** Se extrajeron 5 activos estratégicos y 3 ángulos de copy. Se dejó una observación (no urgente): la historia es norteña pero la voz de la app es rioplatense.
- **2026-10-07** — Sección 10 completada con canales y presupuesto (decisión de Diego). **Canales: Meta Ads** (público 35+, Facebook); **presupuesto: $50 USD como "matrícula de aprendizaje"**, ~$10/día. Se agregaron **2 correcciones técnicas verificadas**: (1) el objetivo debe ser **Promoción de app**, NO Tráfico con link (Tráfico optimiza por clics, no instalaciones); (2) la **fase de aprendizaje** de Meta (~15 eventos / ad set / 7 días en 2026) exige **concentrar el presupuesto, no fragmentarlo** y **no editar** la campaña durante el aprendizaje. Se documentó la métrica clave de la Fase 1: **CPI (costo por instalación)**. Se aclaró que la UTM de Play NO atribuye instalaciones de Meta. Advertencia final: **traducir no es localizar**.
