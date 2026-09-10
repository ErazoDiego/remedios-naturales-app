-- ============================================================
-- v10: Imágenes de la colección kefir (gratis)
-- Fecha: 2026-08-31
--
-- 1) Asigna la imagen local a cada receta de la colección 'kefir':
--    imagen = 'assets/images/recetas/' || id || '.webp'
--    (el buscador construye esa ruta con el id de la receta).
-- 2) Asigna la portada de la colección (imagen a nivel colección).
-- 3) Bumpea version a 2 → fuerza a los clientes a re-descargar
--    la colección y reemplazar el caché local (que traía imagen nula).
-- 4) Alinea el nombre de la receta kefir_06 con el recetario:
--    'Refresco de Sandía, Jamaica y Suero de Kéfir'
--
-- Ejecutar en el SQL Editor de Supabase (una sola vez).
-- ============================================================

-- 1) Imagen por receta + portada de colección + version bump
update public.colecciones
set
  imagen = 'assets/images/recetas/portada_kefir.webp',
  version = 2,
  recetas = (
    select jsonb_agg(
             case
               when r->>'id' = 'kefir_06'
               then r
                 || jsonb_build_object(
                      'imagen', 'assets/images/recetas/' || (r->>'id') || '.webp',
                      'nombre', 'Refresco de Sandía, Jamaica y Suero de Kéfir'
                    )
               else r || jsonb_build_object(
                      'imagen', 'assets/images/recetas/' || (r->>'id') || '.webp'
                    )
             end
             order by (substring(r->>'id', 7))::int
           )
    from jsonb_array_elements(recetas) r
    where r->>'id' like 'kefir%'
  )
where id = 'kefir';
