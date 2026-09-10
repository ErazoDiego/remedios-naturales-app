-- =============================================
-- Remedios Naturales - Migración v9 - SEED KÉFIR DE LECHE (GRATIS)
-- Colección: "Recetas con kéfir de leche" — colaboración Mr. Bulgarito
-- Aplicar en el SQL Editor de Supabase (re-aplicable).
-- =============================================
--
-- 1) Nuevo flag `gratis`: colecciones sin pack IAP, abiertas para
--    todos (decisión de producto 2026-08-30). Default FALSE: las
--    colecciones existentes no cambian.
--
-- 2) Seed de la colección 'kefir' (kéfir de leche) con las 37 recetas
--    del recetario (archivo Recetas_de_Kefir.md). Sin imágenes (null):
--    la app usa el fallback de ícono + color. Orden 2 (después de 'jugos').
--
-- Formato: modelo Receta de la app + 'keywords' normalizadas (sin
-- tildes, ñ→n) para el buscador de la biblioteca. 'tipoPreparacion'
-- usa valores mapeados de AppConstants (nuevos tipos de cocina:
-- batido, postre, helado, panadería, queso, salsa, ensalada,
-- guarnición, además de 'bebida').
-- ids: kefir_01..kefir_37 → la app mapea colección 'kefir' + receta 'kefir_NN'.

-- 1) Flag gratis (idempotente)
alter table public.colecciones
  add column if not exists gratis boolean not null default false;

-- 2) Colección de kéfir
insert into public.colecciones (id, nombre, descripcion, icono, color, activa, orden, version, imagen, gratis, recetas)
values (
  'kefir',
  'Recetas con kéfir de leche',
  '37 recetas dulces y saladas con kéfir de leche: postres, bebidas, panes, quesos, helados y salsas. Recetario de Mr. Bulgarito, gratis para todos.',
  'milk',
  'verde',
  true,
  2,
  1,
  null,
  true,
  $json$[
  {
    "id": "kefir_01",
    "nombre": "Pavé de Kéfir Griego",
    "descripcion": "Capas de crema de kéfir y galletas, sin horno y listo en 4-6 horas de refrigeración.",
    "idealPara": [
      "Postre",
      "Sin horno",
      "Ocasiones especiales"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Añadí la gelatina tibia, no caliente, para conservar mejor los probióticos del kéfir.",
    "ingredientes": [
      "500 g de kéfir griego (filtrado 18 horas)",
      "7 g de gelatina sin sabor (1 sobre)",
      "60 ml de agua fría",
      "30 g de leche en polvo",
      "40-60 g de leche condensada (opcional)",
      "Endulzante al gusto",
      "5 ml de extracto de vainilla",
      "150 g de galletas María o de vainilla",
      "Cacao, canela o fruta fresca para decorar"
    ],
    "preparacion": [
      "Hidratá la gelatina en el agua fría durante 5 minutos.",
      "Derretila en el microondas (10-15 seg) o a baño María.",
      "Mezclá el kéfir griego con la leche en polvo, la vainilla y el endulzante. Si lo querés más dulce, sumá la leche condensada.",
      "Incorporá la gelatina de a poco mientras mezclás hasta lograr una crema homogénea.",
      "En un molde o vasitos, alterná capas de crema y galletas hasta terminar los ingredientes.",
      "Refrigerá de 4 a 6 horas o hasta que esté completamente firme.",
      "Decorá con cacao, canela o fruta fresca antes de servir."
    ],
    "dosis": "Rinde 8 porciones.",
    "almacenamiento": "Conservar refrigerado y consumir dentro de los 3-4 días.",
    "keywords": [
      "kefir",
      "pave",
      "postre",
      "galletas",
      "gelatina",
      "crema",
      "sin horno",
      "probiótico"
    ]
  },
  {
    "id": "kefir_02",
    "nombre": "Tepache Probiótico con Suero de Kéfir",
    "descripcion": "Tepache tradicional de piña y panela, fermentado y enriquecido con suero de kéfir al final.",
    "idealPara": [
      "Bebida refrescante",
      "Fermentados",
      "Días calurosos"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "precaucion": "Cubrí con una tela limpia y no cierres el recipiente herméticamente durante la fermentación: puede acumular presión. Si aparece moho u olor raro, desechalo.",
    "ingredientes": [
      "250 ml de suero de kéfir",
      "Cáscara de 1 piña bien lavada",
      "250 g de piña en cubos",
      "150 g de panela rallada o azúcar morena",
      "1 rama de canela",
      "2 clavos de olor (opcional)",
      "1750 ml de agua",
      "Hielo al gusto"
    ],
    "preparacion": [
      "Colocá en un recipiente la cáscara de piña, los cubos, la panela, la canela y los clavos.",
      "Agregá el agua y mezclá hasta disolver la panela.",
      "Cubrí con una tela limpia y dejá fermentar a temperatura ambiente 24 a 48 horas.",
      "Colá la bebida y refrigerá hasta que esté bien fría.",
      "Recién cuando esté fría, sumá el suero de kéfir y mezclá suavemente.",
      "Serví con abundante hielo."
    ],
    "dosis": "Rinde aproximadamente 2 litros.",
    "almacenamiento": "Refrigerado y bien tapado, dura 3-4 días.",
    "keywords": [
      "kefir",
      "tepache",
      "pina",
      "panela",
      "fermentado",
      "suero",
      "probiótico",
      "refresco"
    ]
  },
  {
    "id": "kefir_03",
    "nombre": "Agua Azul Tropical con Suero de Kéfir",
    "descripcion": "Infusión de guisante azul (butterfly pea) con piña y suero de kéfir: una bebida azul vibrante y probiótica.",
    "idealPara": [
      "Bebida refrescante",
      "Llamativa y natural",
      "Sin alcohol"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "precaucion": "El limón cambia el color azul a violeta: si querés mantener el azul, agregalo directo al vaso al servir. Sumá el suero de kéfir solo cuando la bebida esté fría.",
    "ingredientes": [
      "250 ml de suero de kéfir",
      "10-12 flores secas de guisante azul (butterfly pea)",
      "250 ml de piña fresca en cubos",
      "60 ml de uvas verdes (opcional)",
      "120-180 ml de azúcar (½ a ¾ taza)",
      "30 ml de jugo de limón (1 limón)",
      "1750 ml de agua",
      "Hielo al gusto"
    ],
    "preparacion": [
      "Herví 500 ml de agua y agregá las flores de guisante azul. Infusioná 8-10 minutos, colá y enfriá.",
      "Licuá la piña con 500 ml de agua; colá si la querés más ligera.",
      "En un recipiente grande mezclá la infusión azul con el licuado de piña.",
      "Sumá 750 ml de agua fría e incorporá el azúcar hasta disolver.",
      "Cuando esté bien fría, agregá el suero de kéfir y el jugo de limón, mezclando suave.",
      "Refrigerá al menos 1 hora antes de servir y serví con hielo."
    ],
    "dosis": "Rinde 2 litros.",
    "almacenamiento": "Refrigerada y tapada, 3-4 días.",
    "keywords": [
      "kefir",
      "agua azul",
      "guisante azul",
      "butterfly pea",
      "pina",
      "limon",
      "suero",
      "probiótico",
      "refresco"
    ]
  },
  {
    "id": "kefir_04",
    "nombre": "Cheesecake de Kéfir sin hornear",
    "descripcion": "Cheesecake cremoso con base de galleta y relleno de kéfir griego: fresco, ligero y lleno de probióticos.",
    "idealPara": [
      "Postre",
      "Sin horno",
      "Cumpleaños y reuniones"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Añadí la gelatina tibia, nunca caliente, para no matar los probióticos del kéfir.",
    "ingredientes": [
      "200 g de galletas tipo María trituradas",
      "80 g de mantequilla derretida",
      "300 g de kéfir griego",
      "200 g de queso crema",
      "200 ml de crema para batir",
      "120 g de azúcar o endulzante al gusto",
      "5 ml de extracto de vainilla",
      "14 g de gelatina sin sabor (2 sobres)",
      "100 ml de agua fría",
      "200 g de fresas o frutos rojos (cobertura opcional)"
    ],
    "preparacion": [
      "Mezclá las galletas con la mantequilla hasta lograr textura de arena húmeda.",
      "Cubrí el fondo de un molde desmontable, presioná bien y refrigerá 20 minutos.",
      "Hidratá la gelatina con el agua fría 5 minutos, calentá unos segundos hasta disolver y dejá entibiar.",
      "Batí el queso crema, el kéfir griego, la crema, el azúcar y la vainilla hasta lograr una mezcla cremosa.",
      "Agregá la gelatina tibia de a poco mientras mezclás.",
      "Verté el relleno sobre la base y alisá la superficie.",
      "Refrigerá 6-8 horas o toda la noche hasta que esté firme.",
      "Decorá con frutas frescas o mermelada antes de servir."
    ],
    "dosis": "Rinde 8-10 porciones.",
    "almacenamiento": "Refrigerado hasta 4 días.",
    "keywords": [
      "kefir",
      "cheesecake",
      "postre",
      "galletas",
      "queso crema",
      "gelatina",
      "sin horno",
      "probiótico"
    ]
  },
  {
    "id": "kefir_05",
    "nombre": "Flan de Kéfir sin horno",
    "descripcion": "Flan cremoso de kéfir con caramelo casero, firme con gelatina y listo sin horno.",
    "idealPara": [
      "Postre",
      "Sin horno",
      "Clásicos"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Añadí la gelatina tibia, no caliente, para conservar los probióticos. Mantené el flan siempre refrigerado.",
    "ingredientes": [
      "300 g de kéfir griego",
      "250 ml de leche",
      "1 lata (395 g) de leche condensada",
      "5 ml de extracto de vainilla",
      "14 g de gelatina sin sabor (2 sobres)",
      "100 ml de agua fría",
      "100 g de azúcar (caramelo)",
      "30 ml de agua (caramelo)"
    ],
    "preparacion": [
      "Hidratá la gelatina con el agua fría 5 minutos, calentá unos segundos hasta disolver y dejá entibiar.",
      "Mezclá el kéfir griego, la leche, la leche condensada y la vainilla hasta lograr una mezcla homogénea.",
      "Incorporá la gelatina tibia de a poco mezclando constantemente.",
      "Para el caramelo: cociná el azúcar con el agua a fuego medio hasta lograr un color dorado.",
      "Verté el caramelo en el molde y distribuilo por toda la base.",
      "Sumá la mezcla del flan sobre el caramelo.",
      "Refrigerá 6-8 horas o hasta que esté firme.",
      "Desmoldá con cuidado y serví bien frío."
    ],
    "dosis": "Rinde 6-8 porciones.",
    "almacenamiento": "Siempre refrigerado, consumir dentro de los 4 días.",
    "keywords": [
      "kefir",
      "flan",
      "postre",
      "caramelo",
      "gelatina",
      "leche condensada",
      "sin horno",
      "probiótico"
    ]
  },
  {
    "id": "kefir_06",
    "nombre": "Refresco de Sandía y Jamaica con Suero de Kéfir",
    "descripcion": "Sandía licuada con infusión fría de flor de Jamaica y suero de kéfir: refrescante y probiótico.",
    "idealPara": [
      "Bebida refrescante",
      "Verano",
      "Hidratación"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "precaucion": "Sumá el suero de kéfir solo cuando la bebida esté fría para conservar los microorganismos vivos.",
    "ingredientes": [
      "500 g de sandía sin semillas",
      "300 ml de infusión de flor de Jamaica fría",
      "200 ml de suero de kéfir",
      "10 ml de jugo de limón (opcional)",
      "Estevia o eritritol al gusto",
      "Hielo al gusto"
    ],
    "preparacion": [
      "Herví 15 g de flor de Jamaica en 500 ml de agua 8-10 minutos, colá y enfriá por completo.",
      "Licuá la sandía hasta obtener un puré suave.",
      "Mezclá el puré con 300 ml de la infusión de Jamaica.",
      "Incorporá el suero de kéfir cuando la mezcla esté fría.",
      "Sumá el jugo de limón y el endulzante si querés.",
      "Mezclá suave, agregá hielo y serví inmediatamente bien frío."
    ],
    "dosis": "Rinde 4-5 vasos.",
    "almacenamiento": "Consumir en el momento o refrigerado el mismo día.",
    "keywords": [
      "kefir",
      "sandia",
      "jamaica",
      "suero",
      "refresco",
      "probiótico",
      "verano"
    ]
  },
  {
    "id": "kefir_07",
    "nombre": "Bombones rellenos con crema de Kéfir",
    "descripcion": "Bombones de chocolate negro (70%) rellenos con queso de kéfir y crema de almendras.",
    "idealPara": [
      "Antojo saludable",
      "Postre",
      "Regalo casero"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Contiene chocolate con alto contenido de cacao: consumí con moderación si sos sensible a la cafeína. Conservar siempre refrigerados.",
    "ingredientes": [
      "150 g de queso de kéfir (escurrido 48 h)",
      "30 g de crema de almendras 100% natural",
      "Estevia al gusto",
      "5 ml de vainilla",
      "1 pizca de sal",
      "200 g de chocolate negro (70% cacao o más)"
    ],
    "preparacion": [
      "Relleno: mezclá el queso de kéfir con la crema de almendras, la vainilla, la estevia y la sal hasta lograr una crema suave. Refrigerá 20 minutos.",
      "Cobertura: derretí el chocolate a baño María o en microondas.",
      "Cubrí el interior de cada cavidad del molde con una capa fina de chocolate y refrigerá 10 minutos. Repetí para una segunda capa.",
      "Rellená cada cavidad dejando unos milímetros libres y cubrí con el resto del chocolate derretido. Alisá con espátula.",
      "Llevá los bombones al refrigerador 30-60 minutos hasta que el chocolate endurezca por completo."
    ],
    "dosis": "Rinde 12-15 bombones.",
    "almacenamiento": "En recipiente hermético refrigerado, hasta 7 días.",
    "keywords": [
      "kefir",
      "bombones",
      "chocolate",
      "postre",
      "almendras",
      "antojos",
      "probiótico"
    ]
  },
  {
    "id": "kefir_08",
    "nombre": "Bark de Kéfir Griego",
    "descripcion": "Láminas congeladas de kéfir griego con frutas, almendras y chocolate: crujiente, fresco y probiótico.",
    "idealPara": [
      "Snack frío",
      "Verano",
      "Antojo saludable"
    ],
    "tipo": "interno",
    "tipoPreparacion": "helado",
    "precaucion": "Usá kéfir griego bien filtrado (18 horas) para una textura firme tipo helado.",
    "ingredientes": [
      "400 g de kéfir griego",
      "20 g de miel (opcional)",
      "5 ml de esencia de vainilla",
      "80 g de fresas en rodajas",
      "50 g de arándanos",
      "30 g de chocolate negro picado (70% cacao)",
      "30 g de almendras picadas",
      "15 g de pistachos picados (opcional)"
    ],
    "preparacion": [
      "Mezclá el kéfir griego con la miel (si usás) y la vainilla.",
      "Extendé la mezcla sobre una bandeja con papel para hornear formando una capa de 1 cm.",
      "Distribuí las fresas, arándanos, almendras, chocolate y pistachos por encima.",
      "Presioná apenas para que los ingredientes queden adheridos.",
      "Congelá de 4 a 6 horas o hasta que esté completamente firme.",
      "Retirá del congelador, rompé en trozos irregulares y disfrutá."
    ],
    "dosis": "Rinde 6-8 trozos.",
    "almacenamiento": "En recipiente hermético en el congelador, hasta 2 meses.",
    "keywords": [
      "kefir",
      "bark",
      "congelado",
      "fresas",
      "chocolate",
      "almendras",
      "snack",
      "probiótico"
    ]
  },
  {
    "id": "kefir_09",
    "nombre": "Chimichurri Cremoso de Kéfir",
    "descripcion": "Chimichurri cremoso con kéfir, perejil, ajo y orégano: el acompañamiento fresco para carnes y ensaladas.",
    "idealPara": [
      "Salsa para carnes",
      "Aderezo",
      "Acompañamiento"
    ],
    "tipo": "interno",
    "tipoPreparacion": "salsa",
    "precaucion": "Conservar siempre refrigerado y consumir dentro de los 5-7 días.",
    "ingredientes": [
      "½ taza de kéfir de leche",
      "½ taza de perejil fresco picado",
      "2 cucharadas de cilantro (opcional)",
      "2 dientes de ajo rallados",
      "2 cucharadas de aceite de oliva",
      "Jugo de ½ limón",
      "½ cucharadita de hojuelas de chile (opcional)",
      "1 cucharadita de orégano seco",
      "Sal y pimienta negra al gusto"
    ],
    "preparacion": [
      "Mezclá el kéfir con el aceite de oliva y el jugo de limón.",
      "Sumá el perejil, el cilantro, el ajo, el orégano y las hojuelas de chile.",
      "Sazoná con sal y pimienta al gusto.",
      "Mezclá bien hasta lograr una salsa cremosa y homogénea.",
      "Refrigerá 20 minutos para que los sabores se integren."
    ],
    "dosis": "Rinde aprox. 1 taza de salsa.",
    "almacenamiento": "En frasco hermético refrigerado, 5-7 días.",
    "keywords": [
      "kefir",
      "chimichurri",
      "salsa",
      "perejil",
      "ajo",
      "carne",
      "aderezo",
      "probiótico"
    ]
  },
  {
    "id": "kefir_10",
    "nombre": "Muffins Saludables de Guineo, Avena y Kéfir",
    "descripcion": "Muffins esponjosos de guineo (banana), avena y kéfir, sin cantidades exactas: simples y nutritivos.",
    "idealPara": [
      "Desayuno",
      "Merienda",
      "Lonchera"
    ],
    "tipo": "interno",
    "tipoPreparacion": "panadería",
    "precaucion": "Al hornear, los probióticos no sobreviven a las altas temperaturas; igual conservan calcio, proteínas y minerales, y el kéfir aporta textura esponjosa.",
    "ingredientes": [
      "2 guineos o bananas maduros",
      "2 huevos",
      "1 taza de kéfir",
      "1½ tazas de avena en hojuelas",
      "1 cucharadita de polvo de hornear",
      "1 cucharadita de canela",
      "Nueces (opcional)"
    ],
    "preparacion": [
      "Precalentá el horno a 200 °C.",
      "Triturá los guineos en un bowl.",
      "Agregá los huevos y el kéfir, y mezclá bien.",
      "Incorporá la avena, el polvo para hornear y la canela.",
      "Añadí las nueces si querés.",
      "Repartí la mezcla en 6 moldes para muffins.",
      "Horneá 15-20 minutos o hasta que estén dorados y al insertar un palillo salga limpio.",
      "Dejá enfriar unos minutos y disfrutá."
    ],
    "dosis": "Rinde 6 muffins medianos.",
    "almacenamiento": "En recipiente hermético a temperatura ambiente 2-3 días, o refrigerados hasta 5.",
    "keywords": [
      "kefir",
      "muffins",
      "guineo",
      "banana",
      "avena",
      "desayuno",
      "horneado",
      "probiótico"
    ]
  },
  {
    "id": "kefir_11",
    "nombre": "Panna Cotta de Kéfir Griego",
    "descripcion": "Panna cotta cremosa de kéfir griego con salsa de fresas: elegante, sin horno y llena de probióticos.",
    "idealPara": [
      "Postre elegante",
      "Sin horno",
      "Reuniones"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Añadí la gelatina tibia, no caliente, para conservar los probióticos del kéfir.",
    "ingredientes": [
      "500 g de kéfir griego (filtrado 18 horas)",
      "30 g de leche en polvo",
      "7 g de gelatina sin sabor",
      "60 ml de agua fría",
      "5 ml de extracto de vainilla",
      "Endulzante al gusto",
      "40-60 g de leche condensada (opcional)",
      "150 g de fresas (cobertura)",
      "40 ml de agua (cobertura)",
      "15-20 g de miel o endulzante (cobertura)",
      "5 ml de jugo de limón (cobertura)"
    ],
    "preparacion": [
      "Hidratá la gelatina en el agua fría 5 minutos y derretila en el microondas (10-15 seg) o a baño María.",
      "Mezclá el kéfir griego, la leche en polvo, la vainilla y el endulzante. Sumá la leche condensada si querés más dulce.",
      "Incorporá la gelatina de a poco mezclando constantemente.",
      "Verté la mezcla en moldes o vasitos individuales.",
      "Refrigerá de 4 a 6 horas hasta que esté firme.",
      "Cobertura: cociná las fresas con el agua, la miel y el jugo de limón 5 minutos. Triturá apenas y enfriá.",
      "Colocá la salsa sobre cada panna cotta y decorá con fresas frescas y menta."
    ],
    "dosis": "Rinde 4-6 porciones.",
    "almacenamiento": "Refrigerada en recipiente con tapa, hasta 4 días.",
    "keywords": [
      "kefir",
      "panna cotta",
      "postre",
      "fresas",
      "gelatina",
      "crema",
      "probiótico"
    ]
  },
  {
    "id": "kefir_12",
    "nombre": "Puré de Papa Cremoso con Kéfir",
    "descripcion": "Puré de papas suave y cremoso con kéfir en lugar de crema: más ligero y con probióticos.",
    "idealPara": [
      "Guarnición",
      "Acompañamiento",
      "Comida reconfortante"
    ],
    "tipo": "interno",
    "tipoPreparacion": "guarnición",
    "precaucion": "Incorporá el kéfir cuando el puré esté tibio, nunca hirviendo, para no cortarlo ni matar los probióticos.",
    "ingredientes": [
      "1 kg de papas (aprox. 4 medianas)",
      "500 ml de agua",
      "250-300 g de kéfir de leche o 200-250 g de kéfir griego",
      "30 g de mantequilla",
      "10 ml de aceite de oliva (opcional)",
      "Sal y pimienta negra al gusto",
      "Ajo y perejil fresco picado (opcional)"
    ],
    "preparacion": [
      "Cociná las papas en agua hasta que estén tiernas.",
      "Escurrilas y hacé el puré.",
      "Agregá la mantequilla y mezclá.",
      "Esperá que el puré esté tibio.",
      "Incorporá el kéfir de a poco hasta lograr una textura cremosa.",
      "Añadí sal, pimienta y las hierbas al gusto."
    ],
    "dosis": "Rinde 4 porciones.",
    "almacenamiento": "Refrigerado hasta 3 días.",
    "keywords": [
      "kefir",
      "pure",
      "papa",
      "guarnición",
      "cremoso",
      "acompañamiento",
      "probiótico"
    ]
  },
  {
    "id": "kefir_13",
    "nombre": "Arroz con Kéfir",
    "descripcion": "Arroz con leche cremoso que se termina con kéfir griego en frío: un postre clásico con probióticos.",
    "idealPara": [
      "Postre",
      "Clásicos",
      "Comida reconfortante"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Añadí el kéfir cuando el arroz esté tibio, no caliente, para conservar los probióticos.",
    "ingredientes": [
      "200 g de arroz",
      "500 ml de agua",
      "1 litro de leche",
      "1 rama de canela",
      "Cáscara de 1 limón (opcional)",
      "30 g de leche en polvo",
      "Endulzante al gusto",
      "300 g de kéfir griego (filtrado 18 horas)",
      "5 ml de extracto de vainilla",
      "40-60 g de leche condensada (opcional)"
    ],
    "preparacion": [
      "Cociná el arroz con el agua, la canela y la cáscara de limón hasta que el agua se absorba y el arroz esté tierno.",
      "Agregá la leche y cociná a fuego bajo 20-30 minutos, revolviendo de vez en cuando, hasta que quede cremoso.",
      "Incorporá la leche en polvo y el endulzante. Sumá la leche condensada si querés más dulce.",
      "Retirá del fuego y dejá enfriar hasta que esté tibio.",
      "Agregá el kéfir griego y la vainilla, mezclando suavemente.",
      "Refrigerá 1-2 horas.",
      "Serví frío o ligeramente fresco con canela espolvoreada."
    ],
    "dosis": "Rinde 6-8 porciones.",
    "almacenamiento": "Refrigerado hasta 4 días.",
    "keywords": [
      "kefir",
      "arroz",
      "arroz con leche",
      "postre",
      "canela",
      "cremoso",
      "probiótico"
    ]
  },
  {
    "id": "kefir_14",
    "nombre": "Ferrero Rocher de Kéfir",
    "descripcion": "Bombones tipo Ferrero Rocher con queso de kéfir, avellanas y chocolate negro: 100% con kéfir.",
    "idealPara": [
      "Postre",
      "Antojo saludable",
      "Regalo casero"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Si la mezcla del relleno está muy blanda, congelala 10-15 minutos más antes de formar las bolitas.",
    "ingredientes": [
      "1 litro de kéfir natural",
      "20 g de miel o estevia al gusto (opcional)",
      "5 ml de esencia de vainilla",
      "12 avellanas enteras tostadas",
      "180 g de chocolate negro (70% cacao o más)",
      "50 g de avellanas tostadas picadas"
    ],
    "preparacion": [
      "Prepará el queso de kéfir: pasá 1 litro de kéfir natural por una tela para quesos sobre un colador. Dejá escurrir 48 horas en el refrigerador hasta obtener aprox. 200 g de queso de kéfir.",
      "Relleno: mezclá el queso de kéfir con la miel o estevia y la vainilla hasta lograr una crema homogénea.",
      "Enfriá la mezcla 1 hora refrigerada y luego congelá 20-30 minutos para que tome cuerpo.",
      "Con las manos apenas húmedas, tomá una porción, colocá una avellana en el centro y formá una bolita.",
      "Congelá las bolitas 1-2 horas sobre una bandeja con papel para hornear.",
      "Derretí el chocolate a baño María o en microondas. Bañá cada bolita y cubrí con avellanas picadas antes de que endurezca.",
      "Enfriá 10-15 minutos refrigerando o 5-10 congelando hasta que la cobertura quede firme."
    ],
    "dosis": "Rinde 12 bombones.",
    "almacenamiento": "En recipiente hermético en el congelador, hasta 2 meses.",
    "keywords": [
      "kefir",
      "ferrero",
      "bombones",
      "avellanas",
      "chocolate",
      "postre",
      "probiótico"
    ]
  },
  {
    "id": "kefir_15",
    "nombre": "Danonino de Kéfir",
    "descripcion": "Vasitos cremosos de kéfir con puré de fresas y gelatina: la versión casera del clásico infantil.",
    "idealPara": [
      "Postre infantil",
      "Merienda",
      "Lonchera"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Si preferís una textura tipo yogur, omití la gelatina; con gelatina queda más firme, tipo el comercial.",
    "ingredientes": [
      "300 g de kéfir griego",
      "150 g de fresas o la fruta que prefieras",
      "5 ml de extracto de vainilla",
      "Estevia o miel al gusto",
      "3 g de gelatina sin sabor (1 cucharadita)",
      "30 ml de agua fría"
    ],
    "preparacion": [
      "Hidratá la gelatina con el agua fría 5 minutos, calentá unos segundos hasta disolverla y dejá entibiar.",
      "Licuá las fresas con la vainilla y el endulzante hasta lograr un puré suave.",
      "Colocá el kéfir griego en un recipiente e incorporá el puré de fresas. Mezclá suavemente.",
      "Agregá la gelatina tibia y mezclá hasta integrar por completo.",
      "Repartí la preparación en 4 vasitos.",
      "Refrigerá de 2 a 4 horas hasta que tenga textura firme y cremosa."
    ],
    "dosis": "Rinde 4 vasitos.",
    "almacenamiento": "Refrigerado, consumir en 3-4 días.",
    "keywords": [
      "kefir",
      "danonino",
      "fresas",
      "postre",
      "infantil",
      "vasitos",
      "probiótico"
    ]
  },
  {
    "id": "kefir_16",
    "nombre": "Panqueques con Kéfir",
    "descripcion": "Panqueques esponjosos con kéfir: el toque ácido activa el polvo de hornear y los deja increíbles.",
    "idealPara": [
      "Desayuno",
      "Merienda",
      "Fin de semana"
    ],
    "tipo": "interno",
    "tipoPreparacion": "panadería",
    "precaucion": "No mezcles demasiado la masa: los panqueques quedan más esponjosos si apenas se integra.",
    "ingredientes": [
      "240 g de kéfir de leche",
      "1 huevo (50 g)",
      "20 g de mantequilla derretida o aceite de coco",
      "5 g de extracto de vainilla (opcional)",
      "120 g de harina de trigo o avena",
      "8 g de polvo de hornear",
      "3 g de bicarbonato de sodio",
      "2 g de sal",
      "10-15 g de miel o endulzante (opcional)"
    ],
    "preparacion": [
      "Mezclá el kéfir, el huevo, la mantequilla y la vainilla.",
      "En otro recipiente combiná la harina, el polvo de hornear, el bicarbonato y la sal.",
      "Incorporá los secos a los líquidos y mezclá solo hasta integrar.",
      "Dejá reposar la masa 5-10 minutos.",
      "Cociná en sartén antiadherente a fuego medio hasta que aparezcan burbujas en la superficie.",
      "Dale vuelta y cociná 1 minuto más hasta que esté dorado."
    ],
    "dosis": "Rinde 6-8 panqueques.",
    "almacenamiento": "Consumir en el momento; conservados refrigerados hasta 2 días.",
    "keywords": [
      "kefir",
      "panqueques",
      "desayuno",
      "esponjosos",
      "harina",
      "huevo",
      "probiótico"
    ]
  },
  {
    "id": "kefir_17",
    "nombre": "Helado tipo Mango Biche con Kéfir",
    "descripcion": "Paletas o helado de mango verde (biche) con kéfir, limón y un toque de chile o Tajín.",
    "idealPara": [
      "Postre fresco",
      "Verano",
      "Sabor tropical"
    ],
    "tipo": "interno",
    "tipoPreparacion": "helado",
    "precaucion": "El mango biche (verde) es más ácido que el maduro: ajustá el dulzor a tu gusto.",
    "ingredientes": [
      "300 g de kéfir griego",
      "2 mangos verdes medianos (aprox. 350 g de pulpa)",
      "50 ml de crema de leche (opcional)",
      "2 cucharadas de miel, stevia o azúcar",
      "Jugo de 1 limón",
      "1 cucharadita de ralladura de limón (opcional)",
      "1 pizca de sal",
      "Chile en polvo o Tajín (opcional)"
    ],
    "preparacion": [
      "Pelá los mangos y cortalos en cubos.",
      "Licuá el mango con el jugo de limón, el endulzante y la pizca de sal hasta obtener un puré suave.",
      "Agregá el kéfir griego y la crema de leche. Mezclá suavemente hasta integrar.",
      "Probá y ajustá el dulzor o la acidez.",
      "Verté la mezcla en moldes para paletas o en un recipiente apto para congelar.",
      "Congelá 6-8 horas hasta que esté firme.",
      "Antes de servir, espolvoreá con chile en polvo o Tajín si querés."
    ],
    "dosis": "Rinde 4-6 porciones o paletas.",
    "almacenamiento": "En el congelador hasta 1 mes.",
    "keywords": [
      "kefir",
      "helado",
      "mango",
      "mango biche",
      "paletas",
      "tajin",
      "verano",
      "probiótico"
    ]
  },
  {
    "id": "kefir_18",
    "nombre": "Refresco de Suero de Kéfir con Tamarindo y Jamaica",
    "descripcion": "Agua fresca de tamarindo y flor de Jamaica con suero de kéfir: dulce, ácida y probiótica.",
    "idealPara": [
      "Bebida refrescante",
      "Agua fresca",
      "Verano"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "precaucion": "Sumá el suero de kéfir solo cuando la infusión esté completamente fría, para conservar los probióticos.",
    "ingredientes": [
      "500 ml de suero de kéfir",
      "500 ml de agua",
      "2 cucharadas de flor de Jamaica seca",
      "80 g de pulpa de tamarindo sin semillas",
      "Stevia, miel o endulzante al gusto",
      "Hielo al gusto",
      "Rodajas de limón y menta (opcional)"
    ],
    "preparacion": [
      "Herví el agua y agregá la flor de Jamaica. Cociná 5 minutos.",
      "Retirá del fuego, dejá reposar 10 minutos y colá.",
      "Mientras se enfría, disolvé la pulpa de tamarindo en un poco de agua y colá para retirar las fibras.",
      "Mezclá la infusión de Jamaica fría con el tamarindo.",
      "Añadí el suero de kéfir y mezclá suavemente.",
      "Endulzá al gusto y serví con abundante hielo. Decorá con limón y menta si querés."
    ],
    "dosis": "Rinde 4 vasos.",
    "almacenamiento": "Refrigerado, consumir en 2-3 días.",
    "keywords": [
      "kefir",
      "suero",
      "tamarindo",
      "jamaica",
      "refresco",
      "agua fresca",
      "probiótico"
    ]
  },
  {
    "id": "kefir_19",
    "nombre": "Batido de Banana, Remolacha y Kéfir",
    "descripcion": "Batido rosado de banana y remolacha cocida con kéfir: nutritivo, dulce natural y refrescante.",
    "idealPara": [
      "Desayuno",
      "Merienda saludable",
      "Energía"
    ],
    "tipo": "interno",
    "tipoPreparacion": "batido",
    "precaucion": "La remolacha cocida tiene un sabor más suave y dulce que la cruda: probala fría.",
    "ingredientes": [
      "1 banana madura",
      "½ remolacha cocida y fría (aprox. 100 g)",
      "250 ml de kéfir de leche (1 taza)",
      "1 cucharadita de miel (opcional)",
      "Hielo al gusto (opcional)"
    ],
    "preparacion": [
      "Colocá la banana y la remolacha en la licuadora.",
      "Agregá el kéfir de leche.",
      "Licuá hasta obtener una mezcla suave y homogénea.",
      "Endulzá con miel si querés.",
      "Licuá unos segundos más y serví inmediatamente con hielo si lo deseás."
    ],
    "dosis": "Rinde 1 vaso grande (350-400 ml).",
    "almacenamiento": "Consumir en el momento.",
    "keywords": [
      "kefir",
      "batido",
      "banana",
      "remolacha",
      "desayuno",
      "energía",
      "probiótico",
      "licuado"
    ]
  },
  {
    "id": "kefir_20",
    "nombre": "Ensalada de Pasta Fría con Salsa de Kéfir",
    "descripcion": "Ensalada de pasta con vegetales y dos salsas a elegir: de kéfir o de queso crema de kéfir.",
    "idealPara": [
      "Almuerzo liviano",
      "Comida fría",
      "Reuniones"
    ],
    "tipo": "interno",
    "tipoPreparacion": "ensalada",
    "precaucion": "Para que no se aguade: escurrí bien los vegetales, usá kéfir espeso o queso crema, y mezclá la salsa justo antes de servir.",
    "ingredientes": [
      "300 g de pasta corta (fusilli, moño o penne)",
      "1 pepino en medias lunas",
      "200 g de tomates cherry partidos",
      "1 zanahoria rallada",
      "120 g de maíz dulce",
      "100 g de jamón cocido en cubos",
      "Hojas verdes al gusto",
      "Sal y pimienta al gusto"
    ],
    "preparacion": [
      "Cociná la pasta al dente. Enjuagá con agua fría y escurrí muy bien.",
      "Prepará los vegetales: cortá, rallá y escurrí todo muy bien.",
      "Mezclá la salsa elegida (kéfir con aceite, limón y mostaza; o queso crema de kéfir aligerado) y ajustá al gusto.",
      "Integrá la pasta con los ingredientes y agregá la salsa de a poco.",
      "Refrigerá 20-30 minutos para que los sabores se mezclen.",
      "Serví fría."
    ],
    "dosis": "Rinde 4 porciones.",
    "almacenamiento": "Refrigerada en recipiente cerrado hasta 2 días.",
    "keywords": [
      "kefir",
      "ensalada",
      "pasta",
      "vegetales",
      "fria",
      "salsa",
      "almuerzo",
      "probiótico"
    ]
  },
  {
    "id": "kefir_21",
    "nombre": "Queso Crema de Kéfir",
    "descripcion": "Queso crema untable con solo 2 ingredientes: kéfir filtrado y tiempo. Base para salsas, dips y recetas.",
    "idealPara": [
      "Untable",
      "Base de recetas",
      "Dips y aderezos"
    ],
    "tipo": "interno",
    "tipoPreparacion": "queso",
    "precaucion": "Usá utensilios de vidrio o acero inoxidable, kéfir natural sin azúcar ni saborizantes, y no exprimas la gasa: dejá que escurra sola.",
    "ingredientes": [
      "1 litro de kéfir natural (de leche)",
      "1 gasa, tela para quesos o filtro de café"
    ],
    "preparacion": [
      "Fermentá el litro de kéfir de leche durante 18-24 horas.",
      "Colocá la gasa limpia sobre un colador y poné el colador sobre un recipiente.",
      "Verté el kéfir en la gasa.",
      "Refrigerá y dejá filtrar según la textura que prefieras (8-12 h tipo yogur griego; 12-18 h crema untable; 18-24 h más firme).",
      "El líquido que cae es el suero de kéfir: guardalo para bebidas, aderezos o recetas.",
      "Retirá el queso crema de la gasa y pasalo a un recipiente limpio.",
      "Conservá refrigerado."
    ],
    "dosis": "Rinde 300-400 g de queso crema + 600-700 ml de suero.",
    "almacenamiento": "Refrigerado, consumir en 5-7 días. El suero guardado en vidrio dura hasta 7 días.",
    "keywords": [
      "kefir",
      "queso crema",
      "queso",
      "untable",
      "suero",
      "filtrado",
      "probiótico",
      "fermentado"
    ]
  },
  {
    "id": "kefir_22",
    "nombre": "Helado de Mango con Kéfir",
    "descripcion": "Helado cremoso de mango maduro y kéfir griego, sin heladera: congelás y revolvés un par de veces.",
    "idealPara": [
      "Postre fresco",
      "Verano",
      "Sin heladera"
    ],
    "tipo": "interno",
    "tipoPreparacion": "helado",
    "precaucion": "Usá mango bien maduro y kéfir griego para una textura más suave, tipo helado artesanal.",
    "ingredientes": [
      "500 g de mango maduro en cubos (aprox. 2 mangos)",
      "300 g de kéfir griego",
      "100 ml de crema de leche (opcional)",
      "2-3 cucharadas de miel, azúcar o stevia",
      "5 ml de extracto de vainilla",
      "15 ml de jugo de limón (opcional)"
    ],
    "preparacion": [
      "Pelá y cortá el mango en cubos. Para un helado más intenso, congelá el mango 2 horas.",
      "Colocá en la licuadora el mango, el kéfir griego, la crema, la vainilla, el endulzante y el jugo de limón.",
      "Licuá hasta obtener una mezcla completamente cremosa y homogénea.",
      "Verté en un recipiente apto para congelador.",
      "Congelá 4-6 horas; si no tenés heladera, mezclá cada 60-90 minutos durante las primeras 3 horas para reducir los cristales de hielo.",
      "Antes de servir, dejá reposar el helado 5-10 minutos a temperatura ambiente."
    ],
    "dosis": "Rinde 4-6 porciones.",
    "almacenamiento": "En el congelador, hasta 1 mes.",
    "keywords": [
      "kefir",
      "helado",
      "mango",
      "postre",
      "verano",
      "cremoso",
      "probiótico"
    ]
  },
  {
    "id": "kefir_23",
    "nombre": "Mayonesa de Kéfir",
    "descripcion": "Mayonesa cremosa de kéfir con huevo cocido y aceite de aguacate: más saludable y sin huevo crudo.",
    "idealPara": [
      "Salsa",
      "Aderezo",
      "Acompañamiento"
    ],
    "tipo": "interno",
    "tipoPreparacion": "salsa",
    "precaucion": "Esta versión usa huevo cocido, lo que reduce el riesgo asociado al huevo crudo. Conservala siempre refrigerada.",
    "ingredientes": [
      "150 g de kéfir griego (filtrado 8 horas)",
      "2 huevos duros",
      "200 ml de aceite de aguacate u oliva suave",
      "5 ml de mostaza (opcional)",
      "15 ml de jugo de limón (opcional)",
      "½ cucharadita de sal",
      "1 diente de ajo",
      "1 cucharada de perejil, cebollín o cilantro picado"
    ],
    "preparacion": [
      "Cociná los huevos 10-12 minutos, enfriálos, pelalos y cortalos en trozos.",
      "Colocá en la licuadora el kéfir griego, los huevos, la mostaza, el jugo de limón y la sal.",
      "Licuá 30 segundos hasta obtener una mezcla homogénea.",
      "Agregá el aceite de a poco mientras licuás, hasta lograr una textura cremosa.",
      "Incorporá el ajo, las hierbas y la pimienta si querés. Licuá unos segundos más.",
      "Probá y ajustá la sal o el limón.",
      "Guardá en frasco de vidrio y refrigerá 30 minutos antes de servir."
    ],
    "dosis": "Rinde 350-400 ml.",
    "almacenamiento": "Refrigerada, consumir en 3-5 días.",
    "keywords": [
      "kefir",
      "mayonesa",
      "salsa",
      "huevo",
      "aderezo",
      "aceite",
      "probiótico"
    ]
  },
  {
    "id": "kefir_24",
    "nombre": "Trufas Energéticas de Kéfir",
    "descripcion": "Bolitas de kéfir, avena, mantequilla de maní y cacao: energía sostenida, fibra y probióticos.",
    "idealPara": [
      "Snack saludable",
      "Antes o después de entrenar",
      "Antojos sin culpa"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Para unas trufas más nutritivas, sumá 1 cucharada de chía o linaza molida.",
    "ingredientes": [
      "200 g de kéfir griego",
      "150 g de avena en hojuelas",
      "100 g de mantequilla de maní natural",
      "50 g de miel",
      "30 g de cacao en polvo sin azúcar",
      "5 ml de extracto de vainilla",
      "30 g de coco rallado (para cubrir)",
      "30 g de almendras o nueces picadas (opcional)",
      "1 pizca de canela (opcional)"
    ],
    "preparacion": [
      "Mezclá el kéfir griego, la mantequilla de maní, la miel y la vainilla.",
      "Agregá la avena, el cacao y la canela. Mezclá hasta obtener una masa firme.",
      "Incorporá las almendras o nueces si querés un toque crujiente.",
      "Refrigerá la mezcla 30 minutos para que sea más fácil de manipular.",
      "Formá bolitas del tamaño de una nuez con las manos.",
      "Pasalas por coco rallado o cacao hasta cubrirlas.",
      "Refrigerá nuevamente 30 minutos antes de servir."
    ],
    "dosis": "Rinde 12-15 trufas.",
    "almacenamiento": "En recipiente hermético refrigerado, 5-7 días.",
    "keywords": [
      "kefir",
      "trufas",
      "energía",
      "avena",
      "mani",
      "cacao",
      "snack",
      "probiótico"
    ]
  },
  {
    "id": "kefir_25",
    "nombre": "Bubble Tea de Kéfir",
    "descripcion": "Bubble tea probiótico: kéfir con leche y perlas de tapioca, el clásico taiwanés en versión saludable.",
    "idealPara": [
      "Bebida refrescante",
      "Original",
      "Días calurosos"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "precaucion": "Cociná las perlas de tapioca según las instrucciones del fabricante y consumí la bebida el mismo día, refrigerada.",
    "ingredientes": [
      "500 ml de kéfir natural",
      "250 ml de leche o bebida vegetal",
      "2 cucharadas de miel, azúcar o stevia",
      "5 ml de extracto de vainilla",
      "100 g de perlas de tapioca negras",
      "1 litro de agua (para las perlas)",
      "2 cucharadas de azúcar morena o miel",
      "Hielo y cubos de fruta al gusto"
    ],
    "preparacion": [
      "Cociná las perlas de tapioca en el agua hirviendo siguiendo las instrucciones del fabricante (generalmente 20-30 minutos).",
      "Escurrilas y mezclalas con el azúcar morena o la miel. Dejá reposar 10 minutos.",
      "En una jarra mezclá el kéfir, la leche, la vainilla y el endulzante.",
      "Llená cada vaso con hielo.",
      "Agregá 2-3 cucharadas de perlas en cada vaso.",
      "Verté la mezcla de kéfir sobre las perlas y serví con un popote ancho."
    ],
    "dosis": "Rinde 2-3 vasos.",
    "almacenamiento": "Refrigerado, consumir el mismo día.",
    "keywords": [
      "kefir",
      "bubble tea",
      "tapioca",
      "perlas",
      "bebida",
      "leche",
      "probiótico"
    ]
  },
  {
    "id": "kefir_26",
    "nombre": "Kéfir, Cacao y Chía",
    "descripcion": "Kéfir con cacao puro y chía: cremoso, energético y saciante. Listo en 2 minutos más reposo.",
    "idealPara": [
      "Desayuno rápido",
      "Snack",
      "Después de entrenar"
    ],
    "tipo": "interno",
    "tipoPreparacion": "batido",
    "precaucion": "Dejá reposar al menos 30 minutos (o toda la noche) para que la chía se hidrate.",
    "ingredientes": [
      "250 ml de kéfir de leche natural",
      "1 cucharada de cacao en polvo puro",
      "1 cucharada de chía",
      "1 cucharadita de miel o 1 dátil (opcional)",
      "½ cucharadita de esencia de vainilla (opcional)"
    ],
    "preparacion": [
      "En un vaso o frasco agregá el kéfir.",
      "Añadí el cacao en polvo y endulzá al gusto.",
      "Incorporá la chía y la vainilla.",
      "Mezclá muy bien hasta que todo esté integrado.",
      "Dejá reposar en el refrigerador al menos 30 minutos o toda la noche."
    ],
    "dosis": "Rinde 1 porción.",
    "almacenamiento": "Refrigerado, consumir dentro de las 24 horas.",
    "keywords": [
      "kefir",
      "cacao",
      "chia",
      "desayuno",
      "energía",
      "saciante",
      "probiótico"
    ]
  },
  {
    "id": "kefir_27",
    "nombre": "Pan de Ajo con Kéfir",
    "descripcion": "Pan casero esponjoso amasado con kéfir, untado con mantequilla de ajo y perejil antes de hornear.",
    "idealPara": [
      "Acompañamiento",
      "Cenas",
      "Parrilla y pastas"
    ],
    "tipo": "interno",
    "tipoPreparacion": "panadería",
    "precaucion": "Al hornearse, los probióticos no sobreviven, pero el kéfir aporta esponjosidad, humedad y un ligero toque ácido.",
    "ingredientes": [
      "300 g de harina de trigo",
      "200 ml de kéfir natural",
      "7 g de levadura seca (1 cucharadita)",
      "5 g de azúcar (1 cucharadita)",
      "3 g de sal (½ cucharadita)",
      "30 ml de aceite de oliva (2 cucharadas)",
      "50 g de mantequilla derretida",
      "3 dientes de ajo finamente picados",
      "1 cucharada de perejil fresco picado",
      "30 g de queso parmesano rallado (opcional)"
    ],
    "preparacion": [
      "Mezclá el kéfir con la levadura y el azúcar. Dejá reposar 10 minutos.",
      "Agregá la harina, la sal y el aceite. Incorporá la mezcla de kéfir y amasá 8-10 minutos hasta lograr una masa suave.",
      "Cubrí la masa y dejá reposar 1 hora o hasta que duplique su tamaño.",
      "Extendé la masa formando un óvalo o círculo de unos 2 cm de grosor.",
      "Mezclá la mantequilla derretida con el ajo, el perejil y el parmesano. Untá la superficie del pan.",
      "Horneá a 180 °C durante 20-25 minutos o hasta que esté dorado.",
      "Retirá del horno, dejá reposar 5 minutos y serví caliente."
    ],
    "dosis": "Rinde 1 pan (4-6 personas).",
    "almacenamiento": "En envase cerrado, 2-3 días a temperatura ambiente.",
    "keywords": [
      "kefir",
      "pan",
      "ajo",
      "panadería",
      "harina",
      "esponjoso",
      "masa",
      "probiótico"
    ]
  },
  {
    "id": "kefir_28",
    "nombre": "Danonino Casero de Kéfir con Durazno",
    "descripcion": "Vasitos cremosos de kéfir con durazno y gelatina, endulzados con stevia: sin azúcar añadida.",
    "idealPara": [
      "Postre infantil",
      "Merienda",
      "Sin azúcar añadida"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Usá duraznos bien maduros para un sabor más dulce y natural.",
    "ingredientes": [
      "300 g de kéfir griego",
      "2 duraznos maduros",
      "5 g de gelatina sin sabor",
      "2-3 cucharadas de agua (para hidratar)",
      "Estevia al gusto (opcional)",
      "½ cucharadita de vainilla"
    ],
    "preparacion": [
      "Hidratá la gelatina en el agua y dejá reposar 5 minutos.",
      "Disolvela a baño María o en microondas 10-15 segundos. Dejá entibiar.",
      "Licuá los duraznos con el kéfir griego, la vainilla y la stevia hasta obtener una mezcla suave.",
      "Incorporá la gelatina disuelta y mezclá o licuá muy bien.",
      "Verté en vasitos o recipientes individuales.",
      "Refrigerá de 2 a 4 horas hasta que cuaje y tenga textura firme y cremosa."
    ],
    "dosis": "Rinde 4-5 porciones.",
    "almacenamiento": "Refrigerado, consumir en 3-4 días.",
    "keywords": [
      "kefir",
      "danonino",
      "durazno",
      "postre",
      "stevia",
      "infantil",
      "probiótico"
    ]
  },
  {
    "id": "kefir_29",
    "nombre": "Yogur Griego con Kéfir Casero",
    "descripcion": "Yogur griego de kéfir: solo filtrás el kéfir 8-12 horas y obtenés 300-450 g de yogur espeso y cremoso.",
    "idealPara": [
      "Desayuno",
      "Base de recetas",
      "Postres"
    ],
    "tipo": "interno",
    "tipoPreparacion": "queso",
    "precaucion": "El kéfir debe filtrarse en refrigeración para evitar contaminaciones.",
    "ingredientes": [
      "1 litro de kéfir natural",
      "1 gasa, tela para quesos o filtro de café",
      "1 colador",
      "1 recipiente"
    ],
    "preparacion": [
      "Fermentá 1 litro de kéfir durante 18-24 horas.",
      "Colocá una gasa o tela limpia sobre un colador y poné el colador sobre un recipiente.",
      "Verté el kéfir en la gasa.",
      "Refrigerá y dejá filtrar durante 8-12 horas.",
      "El líquido que cae es el suero: guardalo para bebidas, aderezos o recetas.",
      "Retirá el yogur griego de la gasa y pasalo a un recipiente limpio.",
      "Conservá refrigerado y consumí dentro de 5-7 días."
    ],
    "dosis": "Rinde 300-450 g de yogur griego y el suero restante.",
    "almacenamiento": "Refrigerado, consumir en 5-7 días.",
    "keywords": [
      "kefir",
      "yogur griego",
      "yogur",
      "filtrado",
      "suero",
      "desayuno",
      "probiótico"
    ]
  },
  {
    "id": "kefir_30",
    "nombre": "Parfait de Kéfir con Frutos Rojos y Chía",
    "descripcion": "Capas de kéfir griego, fresas, arándanos, chía y nueces: sin horno, sin azúcar refinada y fresco.",
    "idealPara": [
      "Desayuno",
      "Merienda",
      "Postre liviano"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Usá kéfir filtrado 6-8 horas para una textura tipo yogur griego más cremosa.",
    "ingredientes": [
      "300 g de kéfir griego bien filtrado",
      "100 g de fresas",
      "60 g de arándanos",
      "1 cucharada de semillas de chía",
      "2 cucharadas de nueces o almendras picadas",
      "1 cucharadita de vainilla",
      "Estevia al gusto (opcional)",
      "1 cucharada de coco rallado sin azúcar (opcional)"
    ],
    "preparacion": [
      "Lavá bien las fresas y los arándanos. Cortá las fresas en trocitos.",
      "Mezclá el kéfir griego con la vainilla y, si querés, un poco de stevia.",
      "En un vaso o frasco colocá una primera capa de kéfir.",
      "Añadí una capa de frutos rojos y espolvoreá un poco de chía.",
      "Agregá otra capa de kéfir y repetí las capas.",
      "Terminá con fresas, arándanos, nueces y coco rallado.",
      "Refrigerá 30-60 minutos antes de servir para que la chía comience a hidratarse."
    ],
    "dosis": "Rinde 2 porciones.",
    "almacenamiento": "Refrigerado, consumir dentro de las 24 horas.",
    "keywords": [
      "kefir",
      "parfait",
      "frutos rojos",
      "chia",
      "desayuno",
      "capas",
      "probiótico"
    ]
  },
  {
    "id": "kefir_31",
    "nombre": "Pavé Saludable de Kéfir Griego",
    "descripcion": "Pavé con banana, avena y cacao: crema de kéfir griego con capas de avena, sin horno y sin azúcar refinada.",
    "idealPara": [
      "Postre",
      "Sin horno",
      "Nutritivo"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Usá kéfir griego bien filtrado para una crema más espesa que mantenga mejor las capas.",
    "ingredientes": [
      "400 g de kéfir griego bien filtrado",
      "2 bananos maduros",
      "2 cucharadas de cacao puro sin azúcar",
      "1 cucharadita de vainilla",
      "½ cucharadita de canela",
      "120 g de avena en hojuelas",
      "40 g de nueces o almendras picadas",
      "2 cucharadas de cacao puro (capas)",
      "1 banano en rodajas",
      "2-3 cucharadas de leche o kéfir (para humedecer la avena)",
      "Frutos rojos y cacao para decorar"
    ],
    "preparacion": [
      "Crema: triturá los 2 bananos y mezclá con el kéfir griego, el cacao, la vainilla y la canela hasta obtener una crema suave.",
      "Capa de avena: mezclá las hojuelas de avena, las nueces y el cacao.",
      "Colocá una capa fina de avena en el fondo de un recipiente.",
      "Agregá una capa de crema de kéfir y algunas rodajas de banano.",
      "Repetí alternando avena, crema y banano hasta terminar.",
      "Tapá y refrigerá 6-8 horas, preferiblemente toda la noche.",
      "Antes de servir decorá con frutos rojos, nueces y un poco de cacao."
    ],
    "dosis": "Rinde 6-8 porciones.",
    "almacenamiento": "Refrigerado, consumir en 3 días.",
    "keywords": [
      "kefir",
      "pave",
      "banana",
      "avena",
      "cacao",
      "postre",
      "sin horno",
      "probiótico"
    ]
  },
  {
    "id": "kefir_32",
    "nombre": "Smoothie Verde de Kéfir",
    "descripcion": "Kéfir con espinaca, kiwi, manzana verde y plátano: un licuado verde refrescante y lleno de probióticos.",
    "idealPara": [
      "Desayuno",
      "Energía",
      "Verdura en vaso"
    ],
    "tipo": "interno",
    "tipoPreparacion": "batido",
    "precaucion": "Para un smoothie más cremoso y con más fibra, usá un plátano previamente congelado.",
    "ingredientes": [
      "300 ml de kéfir natural",
      "1 taza de espinaca fresca (30 g)",
      "1 kiwi pelado",
      "½ manzana verde",
      "½ plátano maduro",
      "Jugo de ½ limón",
      "1 cucharadita de miel o stevia (opcional)",
      "4-6 cubos de hielo"
    ],
    "preparacion": [
      "Lavá muy bien la espinaca, el kiwi y la manzana.",
      "Cortá el kiwi, la manzana y el plátano en trozos.",
      "Colocá en la licuadora el kéfir, la espinaca, las frutas, el jugo de limón y el endulzante.",
      "Licuá 1-2 minutos hasta obtener una mezcla completamente cremosa.",
      "Agregá el hielo y licuá nuevamente 20-30 segundos.",
      "Probá el sabor, ajustá el dulzor y serví inmediatamente bien frío."
    ],
    "dosis": "Rinde 2 vasos (500-600 ml).",
    "almacenamiento": "Consumir en el momento.",
    "keywords": [
      "kefir",
      "smoothie",
      "verde",
      "espinaca",
      "kiwi",
      "manzana",
      "batido",
      "probiótico"
    ]
  },
  {
    "id": "kefir_33",
    "nombre": "Overnight Oats con Kéfir",
    "descripcion": "Avena remojada en kéfir con chía, banana y manzana: desayuno cremoso que se prepara la noche anterior.",
    "idealPara": [
      "Desayuno",
      "Sin cocción",
      "Para llevar"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Para una textura más cremosa usá kéfir griego; no hace falta calentar la avena, se hidrata en frío.",
    "ingredientes": [
      "150 ml de kéfir natural",
      "½ taza de avena en hojuelas (40-50 g)",
      "1 cucharada de semillas de chía",
      "½ banano maduro en rodajas",
      "½ manzana pequeña en cubitos",
      "½ cucharadita de canela",
      "1 cucharadita de vainilla",
      "Estevia al gusto (opcional)",
      "1 cucharada de nueces o almendras picadas"
    ],
    "preparacion": [
      "En un frasco con tapa colocá la avena y las semillas de chía.",
      "Añadí el kéfir, la vainilla y la canela. Mezclá muy bien.",
      "Incorporá el banano y la manzana.",
      "Agregá stevia si querés un toque más dulce.",
      "Tapá y refrigerá 6-8 horas, preferiblemente toda la noche.",
      "Por la mañana mezclá nuevamente; si está muy espeso, añadí un poco más de kéfir.",
      "Decorá con nueces, fruta y canela."
    ],
    "dosis": "Rinde 1 porción.",
    "almacenamiento": "Refrigerado, consumir dentro de las 48 horas.",
    "keywords": [
      "kefir",
      "overnight oats",
      "avena",
      "chia",
      "desayuno",
      "frio",
      "probiótico"
    ]
  },
  {
    "id": "kefir_34",
    "nombre": "Marquesa Saludable de Kéfir, Avena y Chocolate",
    "descripcion": "Marquesa en capas de crema de kéfir con cacao y avena: sin horno, sin azúcar refinada y chocolatosa.",
    "idealPara": [
      "Postre",
      "Sin horno",
      "Chocolate"
    ],
    "tipo": "interno",
    "tipoPreparacion": "postre",
    "precaucion": "Para una textura más firme usá kéfir griego bien filtrado. Añadí la stevia de a poco y probá.",
    "ingredientes": [
      "400 g de kéfir griego",
      "2 bananos maduros",
      "2 cucharadas de cacao puro sin azúcar",
      "1 cucharadita de vainilla",
      "1 cucharadita de canela",
      "Stevia líquida al gusto (5-10 gotas)",
      "150 g de avena en hojuelas",
      "40 g de nueces o almendras picadas",
      "1 cucharada de cacao puro sin azúcar (capas)",
      "2 cucharadas de semillas de chía (opcional)"
    ],
    "preparacion": [
      "Triturá los bananos hasta obtener un puré.",
      "Añadí el kéfir, el cacao, la vainilla y la canela. Mezclá hasta obtener una crema homogénea.",
      "Agregá la stevia de a poco, probando el dulzor.",
      "En otro recipiente mezclá la avena, las nueces, el cacao y la chía.",
      "En un molde colocá una capa de la mezcla de avena.",
      "Añadí encima una capa de crema de kéfir.",
      "Repetí las capas hasta terminar los ingredientes.",
      "Cubrí y refrigerá 6-8 horas, preferiblemente toda la noche.",
      "Antes de servir decorá con cacao, frutos secos o fruta fresca."
    ],
    "dosis": "Rinde 8-10 porciones.",
    "almacenamiento": "Refrigerado, consumir en 3-4 días.",
    "keywords": [
      "kefir",
      "marquesa",
      "chocolate",
      "avena",
      "banana",
      "postre",
      "sin horno",
      "probiótico"
    ]
  },
  {
    "id": "kefir_35",
    "nombre": "Queso Tipo Cotija con Kéfir de Leche",
    "descripcion": "Queso firme, seco y rallable hecho con kéfir filtrado 48 horas y prensado 5 días: ideal para tacos y ensaladas.",
    "idealPara": [
      "Queso rallable",
      "Tacos y ensaladas",
      "Elaboración de quesos"
    ],
    "tipo": "interno",
    "tipoPreparacion": "queso",
    "precaucion": "El kéfir debe filtrarse SIEMPRE en refrigeración para evitar contaminaciones. Si aparece moho, coloración extraña u olor desagradable, no lo consumas.",
    "ingredientes": [
      "1 litro de kéfir de leche ya fermentado",
      "1 cucharadita de sal o al gusto",
      "Colador fino o filtro para queso",
      "Manta de cielo o tela fina",
      "Molde o recipiente pequeño con tapa"
    ],
    "preparacion": [
      "Fermentá: prepará 1 litro de kéfir y dejá fermentar hasta obtener un kéfir bien cuajado.",
      "Filtrá 48 horas: colocá la manta de cielo sobre un colador y verté el kéfir. Refrigerá y dejá escurrir 48 horas.",
      "Retirá el exceso de suero: cuando esté muy espeso, retiralo de la tela y eliminá el líquido restante.",
      "Añadí la sal y mezclá muy bien para distribuirla de manera uniforme.",
      "Prensá y da forma: colocá la masa en un molde forrado con tela limpia. Presioná firme y refrigerá 12-24 horas.",
      "Prensá y secá 5 días: desmoldá y continuá en refrigeración. Volteá el queso cada día y cambiá la tela diariamente.",
      "Cuando esté firme y se pueda cortar sin deformarse, estará listo para rallar."
    ],
    "dosis": "Rinde 200-450 g de queso firme.",
    "almacenamiento": "En recipiente limpio y cerrado, siempre refrigerado; consumir en pocos días.",
    "keywords": [
      "kefir",
      "queso",
      "cotija",
      "rallable",
      "tacos",
      "fermentado",
      "probiótico",
      "prensado"
    ]
  },
  {
    "id": "kefir_36",
    "nombre": "Tepache Probiótico de Mango con Suero de Kéfir",
    "descripcion": "Tepache de mango con panela y canela, fermentado 24-48 horas y reforzado con suero de kéfir.",
    "idealPara": [
      "Bebida refrescante",
      "Fermentados",
      "Sabor tropical"
    ],
    "tipo": "interno",
    "tipoPreparacion": "bebida",
    "precaucion": "No cierres herméticamente durante la fermentación inicial: puede acumular presión. Si aparece moho, colores extraños u olor a podrido, desechalo.",
    "ingredientes": [
      "50 ml de suero de kéfir",
      "700 ml de agua",
      "300 g de mango maduro sin cáscara ni semilla",
      "50-80 g de panela",
      "1 trocito de canela (opcional)"
    ],
    "preparacion": [
      "Lavá muy bien el mango y todos los utensilios.",
      "Cortá el mango en trozos y colocalo en un frasco de vidrio limpio.",
      "Agregá el agua, la panela y el suero de kéfir. Mezclá bien.",
      "Cubrí el frasco sin cerrarlo herméticamente, para que escape el gas.",
      "Dejá fermentar a temperatura ambiente 24 horas; si está fresco, puede necesitar hasta 48.",
      "Cuando tenga aroma agradable, sabor ligeramente ácido y algo de efervescencia, colalo, pasalo a una botella limpia y refrigeralo."
    ],
    "dosis": "Rinde 1 litro.",
    "almacenamiento": "Refrigerado, consumir en 3-4 días.",
    "keywords": [
      "kefir",
      "tepache",
      "mango",
      "panela",
      "fermentado",
      "suero",
      "probiótico"
    ]
  },
  {
    "id": "kefir_37",
    "nombre": "Barras Frías de Kéfir y Coco",
    "descripcion": "Barras congeladas de kéfir griego con coco rallado y chía: frescas, cremosas y listas sin horno.",
    "idealPara": [
      "Snack frío",
      "Verano",
      "Sin horno"
    ],
    "tipo": "interno",
    "tipoPreparacion": "helado",
    "precaucion": "Para barras más firmes usá kéfir griego bien espeso y bien escurrido.",
    "ingredientes": [
      "300 g de kéfir griego bien filtrado",
      "80 g de coco rallado sin azúcar",
      "2 cucharadas de semillas de chía",
      "1 cucharadita de vainilla",
      "Estevia al gusto",
      "2 cucharadas de nueces o almendras picadas (opcional)"
    ],
    "preparacion": [
      "Kéfir: colocá el kéfir en una tela fina o colador con tela.",
      "Dejalo filtrar en el refrigerador 6-8 horas hasta que esté bien espeso y medí 300 g.",
      "Mezclá el kéfir filtrado con la vainilla y la estevia.",
      "Incorporá el coco rallado, la chía y las nueces.",
      "Forrá un recipiente con papel vegetal y verté la mezcla.",
      "Extendé y presioná para formar una capa uniforme de 1-2 cm.",
      "Tápalo y refrigerá 4-6 horas.",
      "Cortá en barras y decorá. Congelá 1-2 horas antes de cortar si querés una forma más firme."
    ],
    "dosis": "Rinde 8-10 barras.",
    "almacenamiento": "En el congelador, hasta 1 mes.",
    "keywords": [
      "kefir",
      "barras",
      "coco",
      "chia",
      "congelado",
      "snack",
      "verano",
      "probiótico"
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
  imagen = excluded.imagen,
  gratis = excluded.gratis,
  recetas = excluded.recetas,
  version = excluded.version;