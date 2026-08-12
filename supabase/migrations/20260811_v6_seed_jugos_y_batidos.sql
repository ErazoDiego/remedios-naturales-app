-- =============================================
-- Remedios Naturales - Migración v6 - SEED REAL
-- Colección: "Jugos y batidos naturales"
-- Aplicar en el SQL Editor de Supabase (re-aplicable).
-- =============================================
--
-- Reemplaza las 5 recetas de ejemplo de la colección 'jugos' por las
-- 15 recetas originales del usuario (archivo
-- coleccion_jugos_y_batidos.xlsx), deduplicadas y con beneficios variados:
-- detox, inmunidad, energía, hidratación, circulación, digestión,
-- saciante y antiinflamatorio.
--
-- Formato: modelo Receta de la app + 'keywords' normalizadas (sin
-- tildes, ñ→n) para el buscador de la biblioteca. 'tipoPreparacion'
-- usa valores mapeados de AppConstants ('bebida').
-- ids: jugos_01..jugos_15 → la app mapea colección 'jugos' + receta 'jugos_NN'.

insert into public.colecciones (id, nombre, descripcion, icono, color, activa, orden, version, recetas)
values (
  'jugos',
  'Jugos y batidos naturales',
  'Jugos, licuados y batidos frescos para detox, energía, defensas y buena digestión. Recetas seleccionadas y adaptadas de la colección del usuario.',
  'glass-full',
  'verde',
  true,
  1,
  3,
  $json$[
  {
    "id": "jugos_01",
    "nombre": "Jugo Limpiador Radiante",
    "descripcion": "Zanahoria, remolacha, manzana, limón y jengibre: un jugo antioxidante que ayuda al hígado a eliminar radicales libres.",
    "idealPara": [
      "Detox y limpieza",
      "Antioxidantes",
      "Piel radiante"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "En ayunas o media mañana, recién hecho y bien frío, hasta 4 veces por semana.",
    "precaucion": "Si tenés cálculos renales consultá antes por el contenido de oxalatos de la remolacha. El limón y el jengibre en ayunas pueden irritar la gastritis sensible.",
    "ingredientes": [
      "3 zanahorias",
      "2 remolachas medianas",
      "1 manzana",
      "Jugo de 1/2 limón",
      "1 trozo de jengibre (2,5 cm)"
    ],
    "preparacion": [
      "Lavá bien las zanahorias, las remolachas y la manzana.",
      "Cortá todo en trozos que entren en el extractor.",
      "Pasá todos los ingredientes por el extractor de jugos.",
      "Sumá el jugo de limón al final y serví frío, de preferencia recién hecho."
    ],
    "dosis": "1 vaso (250 ml), en ayunas hasta 4 veces por semana.",
    "almacenamiento": "Tomalo en el momento; como máximo 24 h en heladera en frasco cerrado.",
    "imagen": "assets/images/recetas/jugos_01_limpiador_radiante.webp",
    "keywords": [
      "zanahoria",
      "remolacha",
      "manzana",
      "limon",
      "jengibre",
      "detox",
      "antioxidante",
      "higado",
      "radicales",
      "piel"
    ]
  },
  {
    "id": "jugos_02",
    "nombre": "Cítricos inmunoestimulante",
    "descripcion": "Naranjas, mandarinas y limón con cúrcuma o jengibre: alta dosis de vitamina C con propiedades antiinflamatorias.",
    "idealPara": [
      "Defensas",
      "Temporada de resfríos",
      "Inmunidad"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "Una vez al día, idealmente en el desayuno, durante la temporada de frío o ante el primer síntoma de resfrío.",
    "precaucion": "Si tenés reflujo o gastritis frecuente, los cítricos en ayunas pueden molestarte: tomalo con comida.",
    "ingredientes": [
      "3 naranjas",
      "2 mandarinas",
      "Jugo de 1/2 limón",
      "2 cm de cúrcuma fresca o jengibre"
    ],
    "preparacion": [
      "Exprimí los cítricos.",
      "Rallá la cúrcuma o el jengibre.",
      "Licuá el jugo junto con la cúrcuma o el jengibre rallado.",
      "Colá si preferís sin pulpa y serví."
    ],
    "dosis": "1 vaso (250 ml) por día.",
    "almacenamiento": "Se oxida rápido: tomalo dentro de las 2 horas. Agitalo antes de beber.",
    "imagen": "assets/images/recetas/jugos_02_citricos_inmunoestimulante.webp",
    "keywords": [
      "naranja",
      "mandarina",
      "limon",
      "curcuma",
      "jengibre",
      "defensas",
      "inmunidad",
      "vitamina",
      "resfrio",
      "gripe"
    ]
  },
  {
    "id": "jugos_03",
    "nombre": "Diosa Verde",
    "descripcion": "Espinacas, col rizada, perejil, manzana verde, pepino, apio y jengibre: cubre varias raciones de verdura en un solo vaso, bajo en azúcar.",
    "idealPara": [
      "Energía",
      "Raciones de verdura",
      "Día liviano"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "A media mañana o antes de entrenar, hasta 5 veces por semana.",
    "precaucion": "Las espinacas y la col rizada crudas aportan oxalatos: si tenés cálculos renales consultá antes. El limón puede irritar la gastritis sensible.",
    "ingredientes": [
      "1 taza de espinacas",
      "1 taza de col rizada",
      "1/2 taza de perejil",
      "1 manzana verde",
      "1 pepino",
      "2 tallos de apio",
      "Jugo de 1/2 limón",
      "1 trozo de jengibre (2,5 cm)"
    ],
    "preparacion": [
      "Lavá bien todas las hojas verdes y las verduras.",
      "Pasá todos los ingredientes por el extractor de jugos, empezando por las hojas verdes.",
      "Sumá el jugo de limón al final y serví."
    ],
    "dosis": "1 vaso (250 ml) por día.",
    "almacenamiento": "Tomalo en el momento; conserva hasta 12 h en heladera en frasco cerrado.",
    "imagen": "assets/images/recetas/jugos_03_diosa_verde.webp",
    "keywords": [
      "espinaca",
      "col",
      "perejil",
      "manzana",
      "pepino",
      "apio",
      "limon",
      "jengibre",
      "verde",
      "energia",
      "verduras"
    ]
  },
  {
    "id": "jugos_04",
    "nombre": "Jugo de granada Power Detox",
    "descripcion": "Granada, manzana, pepino, limón y jengibre: alto en antioxidantes, combina dulzor natural con efecto depurativo.",
    "idealPara": [
      "Detox",
      "Antioxidantes",
      "Dulzor natural"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "En ayunas o después de comidas abundantes, hasta 3 veces por semana.",
    "precaucion": "Si tomás medicación para la presión o estatinas consultá antes: el jugo de granada puede interactuar con esos fármacos. En ayunas, el limón y el jengibre pueden irritar la gastritis.",
    "ingredientes": [
      "1 taza de granada desgranada",
      "1 manzana",
      "1 pepino",
      "Jugo de 1/2 limón",
      "1 trozo de jengibre (2,5 cm)"
    ],
    "preparacion": [
      "Desgraná la granada.",
      "Cortá la manzana y el pepino en trozos.",
      "Extraé el jugo de todos los ingredientes juntos por el extractor.",
      "Serví frío."
    ],
    "dosis": "1 vaso (250 ml), hasta 3 veces por semana.",
    "almacenamiento": "Tomalo en el momento; hasta 24 h en heladera en frasco cerrado.",
    "imagen": "assets/images/recetas/jugos_04_granada_power_detox.webp",
    "keywords": [
      "granada",
      "manzana",
      "pepino",
      "limon",
      "jengibre",
      "detox",
      "antioxidante",
      "depurativo",
      "dulce"
    ]
  },
  {
    "id": "jugos_05",
    "nombre": "Refrescante de pepino y menta",
    "descripcion": "Pepino con manzana verde, limón y menta: el pepino aporta 96% de agua, ideal para hidratar en verano o después de entrenar.",
    "idealPara": [
      "Hidratación",
      "Días calurosos",
      "Después del ejercicio"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "En verano, después de entrenar o en días de mucho calor.",
    "precaucion": "La menta puede relajar el esfínter esofágico: si tenés reflujo, sumá menos hojas o evitála por la noche.",
    "ingredientes": [
      "3 pepinos",
      "1 manzana verde",
      "Jugo de 1/2 limón",
      "1 puñado de hojas de menta fresca"
    ],
    "preparacion": [
      "Lavá los pepinos y la manzana.",
      "Pasá el pepino, la manzana y el limón por el extractor.",
      "Agregá las hojas de menta al final y licuá unos segundos.",
      "Serví bien frío."
    ],
    "dosis": "1 vaso (250 ml), hasta 5 veces por semana.",
    "almacenamiento": "Tomalo en el momento; conserva hasta 12 h en heladera (pierde frescura).",
    "imagen": "assets/images/recetas/jugos_05_pepino_y_menta.webp",
    "keywords": [
      "pepino",
      "manzana",
      "limon",
      "menta",
      "hidratacion",
      "verano",
      "calor",
      "ejercicio",
      "fresco",
      "agua"
    ]
  },
  {
    "id": "jugos_06",
    "nombre": "Jugo Tropical Paradise",
    "descripcion": "Piña, mango, plátano, naranja, lima y agua de coco: dulce y tropical, rico en electrolitos gracias al agua de coco.",
    "idealPara": [
      "Smoothie tropical",
      "Electrolitos",
      "Dulce natural"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "Como bebida de fin de semana o después de entrenar, para reponer energía y electrolitos.",
    "precaucion": "La piña ácida puede irritar la gastritis sensible: en ese caso tomala después de comer, no en ayunas.",
    "ingredientes": [
      "1/2 piña",
      "1 mango",
      "1 plátano",
      "1 naranja pelada",
      "Jugo de 1/2 lima",
      "1 taza de agua de coco"
    ],
    "preparacion": [
      "Extraé el jugo de la piña, el mango, la naranja y la lima.",
      "Vierte ese jugo en la licuadora junto con el plátano y el agua de coco.",
      "Licuá hasta lograr una textura homogénea y serví."
    ],
    "dosis": "1 vaso (300 ml), hasta 3 veces por semana.",
    "almacenamiento": "Tomalo en el momento; el plátano se oscurece y espesa: máximo 12 h en heladera.",
    "imagen": "assets/images/recetas/jugos_06_tropical_paradise.webp",
    "keywords": [
      "pina",
      "mango",
      "platano",
      "naranja",
      "lima",
      "coco",
      "tropical",
      "smoothie",
      "electrolitos",
      "dulce"
    ]
  },
  {
    "id": "jugos_07",
    "nombre": "Jugo de remolacha y zanahoria",
    "descripcion": "Remolacha, zanahoria, manzana verde, jengibre y limón: la remolacha mejora la circulación y las zanahorias aportan betacaroteno.",
    "idealPara": [
      "Circulación",
      "Salud ocular",
      "Antioxidantes"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "Una vez al día, idealmente en la media mañana, hasta 4 veces por semana.",
    "precaucion": "Si tenés cálculos renales consultá antes por el contenido de oxalatos de la remolacha. La orina o las evacuaciones rosadas son inofensivas y esperables.",
    "ingredientes": [
      "2 remolachas",
      "4 zanahorias",
      "1 manzana verde",
      "1 trozo pequeño de jengibre fresco",
      "Jugo de 1 limón",
      "Agua fría o hielo"
    ],
    "preparacion": [
      "Lavá bien las remolachas, las zanahorias y la manzana.",
      "Cortá todo en trozos.",
      "Pasá todo por el extractor de jugos.",
      "Sumá el jugo de limón y serví con hielo."
    ],
    "dosis": "1 vaso (250 ml), hasta 4 veces por semana.",
    "almacenamiento": "Tomalo en el momento; conserva hasta 24 h en heladera en frasco cerrado.",
    "imagen": "assets/images/recetas/jugos_07_remolacha_y_zanahoria.webp",
    "keywords": [
      "remolacha",
      "zanahoria",
      "manzana",
      "jengibre",
      "limon",
      "circulacion",
      "ojos",
      "antioxidante",
      "betacaroteno"
    ]
  },
  {
    "id": "jugos_08",
    "nombre": "Jugo detox de espinaca",
    "descripcion": "Espinacas, pepino, manzana verde, limón y agua: rico en luteína y zeaxantina, protectoras de los ojos, y de bajo índice glucémico.",
    "idealPara": [
      "Salud ocular",
      "Glucosa equilibrada",
      "Detox"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "En ayunas, 3 a 4 veces por semana.",
    "precaucion": "La espinaca cruda aporta oxalatos: si tenés cálculos renales consultá antes. El limón en ayunas puede irritar la gastritis.",
    "ingredientes": [
      "2 tazas de espinacas",
      "1/2 pepino",
      "1/2 manzana verde",
      "1 limón",
      "150 ml de agua"
    ],
    "preparacion": [
      "Lavá bien las espinacas, el pepino y la manzana.",
      "Cortá el pepino y la manzana en trozos.",
      "Licuá todo con el agua y el jugo del limón.",
      "Colá si preferís más fino y serví."
    ],
    "dosis": "1 vaso (250 ml), hasta 4 veces por semana.",
    "almacenamiento": "Tomalo en el momento; conserva hasta 12 h en heladera.",
    "imagen": "assets/images/recetas/jugos_08_detox_de_espinaca.webp",
    "keywords": [
      "espinaca",
      "pepino",
      "manzana",
      "limon",
      "luteina",
      "ojos",
      "glucosa",
      "detox",
      "verde"
    ]
  },
  {
    "id": "jugos_09",
    "nombre": "Batido verde detox de espinacas y jengibre",
    "descripcion": "Espinacas, apio, limón y jengibre: aporta fibra y antioxidantes, actúa como diurético natural y acelera el metabolismo.",
    "idealPara": [
      "Detox",
      "Retención de líquidos",
      "Metabolismo"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "En ayunas durante 7 días para activar el metabolismo.",
    "precaucion": "El apio crudo no es para presión muy baja. Las espinacas crudas aportan oxalatos: consultá si tenés cálculos renales.",
    "ingredientes": [
      "1 taza de espinacas",
      "1 rama de apio",
      "Jugo de 1 limón",
      "1 trozo pequeño de jengibre",
      "1 vaso de agua"
    ],
    "preparacion": [
      "Lavá bien las espinacas y el apio.",
      "Cortá el apio en trozos y pelá el jengibre.",
      "Licuá todos los ingredientes hasta obtener una mezcla homogénea.",
      "Serví de inmediato."
    ],
    "dosis": "1 vaso (250 ml) en ayunas, por 7 días.",
    "almacenamiento": "Tomalo en el momento; máximo 12 h en heladera en frasco cerrado.",
    "imagen": "assets/images/recetas/jugos_09_batido_verde_detox.webp",
    "keywords": [
      "espinaca",
      "apio",
      "limon",
      "jengibre",
      "detox",
      "diuretico",
      "metabolismo",
      "retencion",
      "verde"
    ]
  },
  {
    "id": "jugos_10",
    "nombre": "Batido de papaya y linaza",
    "descripcion": "Papaya con semillas de linaza: la papaína mejora la digestión y la linaza (fibra y omega-3) favorece el tránsito intestinal.",
    "idealPara": [
      "Digestión",
      "Estreñimiento",
      "Cena ligera"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "Por la noche, hasta 3 veces por semana, como cena ligera.",
    "precaucion": "La linaza suma mucha fibra: si tu digestión es sensible, empezá con media cucharada y tomá bastante agua durante el día.",
    "ingredientes": [
      "1 taza de papaya en trozos",
      "1 vaso de agua",
      "1 cucharada de semillas de linaza"
    ],
    "preparacion": [
      "Cortá la papaya en trozos.",
      "Licuá todos los ingredientes hasta que no queden grumos.",
      "Serví de inmediato."
    ],
    "dosis": "1 vaso (250 ml) por la noche, hasta 3 veces por semana.",
    "almacenamiento": "Tomalo en el momento; máximo 12 h en heladera (pierde frescura).",
    "imagen": "assets/images/recetas/jugos_10_papaya_y_linaza.webp",
    "keywords": [
      "papaya",
      "linaza",
      "digestion",
      "transito",
      "fibra",
      "omega",
      "cena",
      "ligero",
      "estrenimiento"
    ]
  },
  {
    "id": "jugos_11",
    "nombre": "Batido de piña, apio y perejil",
    "descripcion": "Piña, apio, perejil y agua: la bromelina de la piña mejora la digestión, el apio es antiinflamatorio y el perejil depura los riñones.",
    "idealPara": [
      "Digestión",
      "Quemagrasas",
      "Riñones"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "En ayunas, antes de desayunar, a diario o la mayoría de los días.",
    "precaucion": "La piña ácida puede irritar la gastritis sensible: tomala después de comer en ese caso. El apio crudo no es para presión muy baja.",
    "ingredientes": [
      "2 rodajas de piña en trozos",
      "1 rama de apio",
      "1 puñado de perejil",
      "1 vaso de agua"
    ],
    "preparacion": [
      "Cortá la piña en trozos y el apio en ramas.",
      "Lavá el perejil.",
      "Licuá todos los ingredientes hasta obtener una bebida homogénea.",
      "Serví de inmediato."
    ],
    "dosis": "1 vaso (250 ml) en ayunas, a diario.",
    "almacenamiento": "Tomalo en el momento; máximo 12 h en heladera.",
    "imagen": "assets/images/recetas/jugos_11_pina_apio_y_perejil.webp",
    "keywords": [
      "pina",
      "apio",
      "perejil",
      "digestion",
      "quemagrasas",
      "rinones",
      "depurativo",
      "ayunas"
    ]
  },
  {
    "id": "jugos_12",
    "nombre": "Batido de plátano y avena",
    "descripcion": "Plátano maduro, avena y bebida vegetal: alto en fibra soluble, regula líquidos, mejora la digestión y controla el apetito.",
    "idealPara": [
      "Saciedad",
      "Cena ligera",
      "Energía sostenida"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "Por la noche en lugar de una cena pesada, o como colación de media mañana.",
    "precaucion": "Si sos celíaco o muy sensible al gluten, usá avena certificada sin TACC (la avena común puede contaminarse).",
    "ingredientes": [
      "1 plátano maduro en trozos",
      "3 cucharadas de avena",
      "1 vaso de bebida vegetal (soja, avena, almendra o coco)",
      "Opcional: canela en polvo al gusto"
    ],
    "preparacion": [
      "Pelá y troceá el plátano.",
      "Licuá todos los ingredientes hasta obtener una textura cremosa.",
      "Agregá canela en polvo al gusto y serví."
    ],
    "dosis": "1 vaso (300 ml) por noche, hasta 5 veces por semana.",
    "almacenamiento": "Tomalo en el momento; el plátano se oscurece y espesa: máximo 12 h en heladera.",
    "imagen": "assets/images/recetas/jugos_12_platano_y_avena.webp",
    "keywords": [
      "platano",
      "avena",
      "saciedad",
      "fibra",
      "cena",
      "colacion",
      "energia",
      "canela",
      "tacc",
      "cremoso"
    ]
  },
  {
    "id": "jugos_13",
    "nombre": "Batido de fresas y chia",
    "descripcion": "Fresas, plátano y chía remojada: las antocianinas de las fresas reducen la inflamación y la chía suma omega-3 y saciedad.",
    "idealPara": [
      "Antiinflamatorio",
      "Saciedad",
      "Antioxidantes"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "Para sustituir alguna cena o como colación de media tarde.",
    "precaucion": "La chía hidratada suma fibra: tomala con suficiente agua y empezá con porciones chicas si tu digestión es sensible.",
    "ingredientes": [
      "1 cucharada de chía (remojada en agua 15 min)",
      "1 taza de fresas",
      "1 plátano pequeño",
      "1 taza de bebida vegetal o agua"
    ],
    "preparacion": [
      "Remojá la chía en un poco de agua durante 15 minutos.",
      "Lavá las fresas y pelá el plátano.",
      "Licuá todos los ingredientes hasta lograr una textura cremosa.",
      "Serví de inmediato."
    ],
    "dosis": "1 vaso (300 ml), hasta 4 veces por semana.",
    "almacenamiento": "Tomalo en el momento; máximo 12 h en heladera.",
    "imagen": "assets/images/recetas/jugos_13_fresas_y_chia.webp",
    "keywords": [
      "fresa",
      "chia",
      "platano",
      "antiinflamatorio",
      "omega",
      "antioxidante",
      "saciedad",
      "cremoso",
      "rojo"
    ]
  },
  {
    "id": "jugos_14",
    "nombre": "Batido de arándanos y cúrcuma",
    "descripcion": "Arándanos, plátano, cúrcuma y pimienta: los arándanos son potentes antioxidantes y la cúrcuma con pimienta potencia su acción antiinflamatoria.",
    "idealPara": [
      "Antiinflamatorio",
      "Antioxidantes",
      "Defensas"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "A media mañana o media tarde, hasta 4 veces por semana.",
    "precaucion": "La cúrcuma en dosis altas puede irritar el estómago sensible y la pimienta negra, la gastritis. Usá las cantidades indicadas.",
    "ingredientes": [
      "1 taza de arándanos",
      "1/2 plátano maduro",
      "1/2 cucharadita de cúrcuma en polvo",
      "1 pizca de pimienta negra",
      "1 taza de bebida vegetal al gusto"
    ],
    "preparacion": [
      "Pelá el plátano.",
      "Licuá todos los ingredientes hasta homogeneizar.",
      "Dejá reposar 2 minutos y serví."
    ],
    "dosis": "1 vaso (300 ml), hasta 4 veces por semana.",
    "almacenamiento": "Tomalo en el momento; máximo 12 h en heladera.",
    "imagen": "assets/images/recetas/jugos_14_arandanos_y_curcuma.webp",
    "keywords": [
      "arandano",
      "platano",
      "curcuma",
      "pimienta",
      "antiinflamatorio",
      "antioxidante",
      "defensas",
      "violeta"
    ]
  },
  {
    "id": "jugos_15",
    "nombre": "Jugo tres en uno",
    "descripcion": "Remolacha, naranjas y zanahoria: rico en potasio, vitamina C y A; la remolacha es remedio popular para la rinitis y la tos seca.",
    "idealPara": [
      "Defensas",
      "Tos seca",
      "Antioxidantes"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "cuandoUsar": "Una vez al día, idealmente en el desayuno, durante la temporada de resfríos.",
    "precaucion": "Si tenés cálculos renales consultá antes por el contenido de oxalatos de la remolacha. Los cítricos en ayunas pueden irritar la gastritis.",
    "ingredientes": [
      "1 remolacha",
      "5 naranjas",
      "1 zanahoria"
    ],
    "preparacion": [
      "Lavá la remolacha y la zanahoria y cortalas en trozos.",
      "Exprimí las naranjas.",
      "Pasá la remolacha y la zanahoria por el extractor de jugos.",
      "Mezclá con el jugo de naranja y serví."
    ],
    "dosis": "1 vaso (250 ml) por día.",
    "almacenamiento": "Tomalo en el momento; se oxida rápido, máximo 2 horas.",
    "imagen": "assets/images/recetas/jugos_15_tres_en_uno.webp",
    "keywords": [
      "remolacha",
      "naranja",
      "zanahoria",
      "defensas",
      "tos",
      "rinitis",
      "antioxidante",
      "potasio",
      "vitamina",
      "inmunidad"
    ]
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
