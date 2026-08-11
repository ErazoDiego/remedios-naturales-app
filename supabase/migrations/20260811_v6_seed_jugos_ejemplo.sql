-- =============================================
-- Remedios Naturales - Migración v6 - SEED
-- Colección de PRUEBA: "Jugos naturales"
-- Aplicada: 2026-08-11 (SQL Editor de Supabase)
-- =============================================
--
-- EJEMPLO — las 5 recetas son placeholders de dominio público para
-- probar la tienda end-to-end. Se reemplazan por el contenido original
-- del usuario. Re-aplicable (on conflict do update).
--
-- Formato de cada receta: modelo Receta de la app + campo 'keywords'
-- (normalizado: sin tildes, ñ→n) para el buscador de la biblioteca.
-- 'tipoPreparacion' usa valores mapeados de AppConstants (bebida).
-- ids: jugos_NN → la app mapea colección 'jugos' + receta 'jugos_NN'.

insert into public.colecciones (id, nombre, descripcion, icono, color, activa, orden, version, recetas)
values (
  'jugos',
  'Jugos naturales',
  'Jugos y licuados frescos para sumar energía, defensas y buena digestión. Colección de PRUEBA: las recetas se reemplazarán por las originales.',
  'glass-full',
  'verde',
  true,
  1,
  1,
  $json$[
    {
      "id": "jugos_01",
      "nombre": "Jugo verde matinal",
      "descripcion": "Apio, pepino, manzana verde y un toque de jengibre: un clásico para arrancar el día liviano y con energía.",
      "idealPara": ["Energía por la mañana", "Digestión ligera", "Retención leve de líquidos"],
      "tipo": "interno",
      "tipoPreparacion": "bebida",
      "cuandoUsar": "En ayunas o media hora antes del desayuno, 3 a 4 veces por semana.",
      "precaucion": "Si tenés gastritis aguda, tomalo después de comer algo suave. El apio crudo no es para presión muy baja.",
      "ingredientes": ["2 ramas de apio", "1/2 pepino", "1 manzana verde", "1 trocito de jengibre (2 cm)", "Jugo de 1/2 limón", "1 vaso de agua"],
      "preparacion": ["Lavá bien el apio, el pepino y la manzana.", "Cortá todo en trozos que entren en la licuadora.", "Licuá con el agua y el jengibre pelado.", "Colá si preferís la textura más fina.", "Sumá el jugo de limón al final y serví bien frío."],
      "dosis": "1 vaso (250 ml), en ayunas hasta 4 veces por semana.",
      "almacenamiento": "Tomar en el momento; se conserva hasta 24 h en heladera en frasco cerrado.",
      "imagen": null,
      "imagenPlaceholder": null,
      "keywords": ["jugo", "verde", "apio", "pepino", "manzana", "energia", "ayunas", "detox", "manana", "despertar"]
    },
    {
      "id": "jugos_02",
      "nombre": "Jugo de naranja, zanahoria y jengibre",
      "descripcion": "El clásico naranja-zanahoria con un toque picante de jengibre: vitamina C para la temporada de resfríos.",
      "idealPara": ["Defensas", "Resfrío leve", "Arranque de día"],
      "tipo": "interno",
      "tipoPreparacion": "bebida",
      "cuandoUsar": "Una vez al día, idealmente en el desayuno o media mañana.",
      "precaucion": "Si tenés reflujo o acidez frecuente, los cítricos en ayunas pueden molestarte: tomalo con comida.",
      "ingredientes": ["2 naranjas", "1 zanahoria grande", "1 trocito de jengibre (2 cm)", "Opcional: una pizca de cúrcuma y pimienta"],
      "preparacion": ["Exprimí las naranjas.", "Pelá la zanahoria y cortala en rodajas.", "Licuá la zanahoria con el jugo de naranja.", "Rallá el jengibre y sumalo con la cúrcuma y la pimienta.", "Mezclá bien y serví."],
      "dosis": "1 vaso (250 ml) por día.",
      "almacenamiento": "Se oxida rápido: tomalo dentro de las 2 horas. Agitalo antes de beber.",
      "imagen": null,
      "imagenPlaceholder": null,
      "keywords": ["naranja", "zanahoria", "jengibre", "defensas", "vitamina", "resfrio", "curcuma", "inmunidad", "gripe", "frio"]
    },
    {
      "id": "jugos_03",
      "nombre": "Jugo de remolacha, manzana y limón",
      "descripcion": "Remolacha con manzana y limón: energía natural para después del ejercicio y para la circulación.",
      "idealPara": ["Después del ejercicio", "Energía sostenida", "Circulación"],
      "tipo": "interno",
      "tipoPreparacion": "bebida",
      "cuandoUsar": "Media hora después de entrenar, o como colación de media tarde.",
      "precaucion": "Si tenés cálculos renales consultá antes por el contenido de oxalatos. La orina o las evacuaciones rosadas son inofensivas y esperables.",
      "ingredientes": ["1 remolacha mediana", "1 manzana roja", "Jugo de 1/2 limón", "1 vaso de agua"],
      "preparacion": ["Lavá bien la remolacha y la manzana (podés dejarles la cáscara).", "Cortá todo en cubos.", "Licuá con el agua.", "Colá y sumá el jugo de limón.", "Serví con hielo."],
      "dosis": "1 vaso (250 ml), hasta 3 veces por semana.",
      "almacenamiento": "Tomalo en el momento; como máximo 24 h en heladera en frasco cerrado.",
      "imagen": null,
      "imagenPlaceholder": null,
      "keywords": ["remolacha", "manzana", "limon", "energia", "circulacion", "ejercicio", "entrenamiento", "deporte", "rojo", "oxalato"]
    },
    {
      "id": "jugos_04",
      "nombre": "Jugo de piña, pepino y menta",
      "descripcion": "Piña fresca con pepino y menta: refrescante y amigable para la digestión y la hinchazón abdominal.",
      "idealPara": ["Digestión pesada", "Hinchazón abdominal", "Días calurosos"],
      "tipo": "interno",
      "tipoPreparacion": "bebida",
      "cuandoUsar": "Después de comidas abundantes o como bebida refrescante a media tarde.",
      "precaucion": "La piña ácida puede irritar la gastritis sensible: en ese caso tomala después de comer, no en ayunas.",
      "ingredientes": ["2 rodajas de piña fresca", "1/2 pepino", "8 hojas de menta", "Jugo de 1/2 limón", "1 vaso de agua fría"],
      "preparacion": ["Cortá la piña y el pepino en trozos.", "Licuá todo con el agua y la menta.", "Colá si no querés la pulpa.", "Sumá el limón y serví bien frío."],
      "dosis": "1 vaso (250 ml), hasta 4 veces por semana.",
      "almacenamiento": "Preparar en el momento; hasta 12 h en heladera (perdé frescura).",
      "imagen": null,
      "imagenPlaceholder": null,
      "keywords": ["pina", "pepino", "menta", "digestion", "hinchazon", "refrescante", "calor", "verano", "fresco", "abdominal"]
    },
    {
      "id": "jugos_05",
      "nombre": "Licuado de banana, avena y canela",
      "descripcion": "Banana con avena y canela: un licuado que rinde y calma el hambre entre comidas.",
      "idealPara": ["Saciedad", "Colación", "Energía sostenida"],
      "tipo": "interno",
      "tipoPreparacion": "bebida",
      "cuandoUsar": "Como colación de media mañana o media tarde, o después del ejercicio.",
      "precaucion": "Si sos celíaco o muy sensible al gluten, usá avena certificada sin TACC (la avena común puede contaminarse).",
      "ingredientes": ["1 banana madura", "2 cucharadas de avena", "1/2 cucharadita de canela", "250 ml de leche o bebida vegetal", "Opcional: 1 dátil para endulzar"],
      "preparacion": ["Pelá la banana y cortala en rodajas.", "Poné todo en la licuadora con la leche o bebida vegetal.", "Licuá hasta que quede cremoso.", "Probá y ajustá el dulzor con el dátil."],
      "dosis": "1 vaso (300 ml) como colación, hasta 5 veces por semana.",
      "almacenamiento": "En el momento; si sobra, hasta 12 h en heladera (se oscurece y espesa).",
      "imagen": null,
      "imagenPlaceholder": null,
      "keywords": ["banana", "avena", "canela", "saciedad", "colacion", "energia", "licuado", "dulce", "merienda", "tacc"]
    }
  ]$json$
)
on conflict (id) do update set
  nombre = excluded.nombre,
  descripcion = excluded.descripcion,
  icono = excluded.icono,
  color = excluded.color,
  activa = excluded.activa,
  orden = excluded.orden,
  recetas = excluded.recetas,
  version = excluded.version,
  actualizado_en = now();
