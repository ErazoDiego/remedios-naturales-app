-- =============================================
-- Remedios Naturales - Migración v6
-- Biblioteca de Colecciones (catálogo público)
-- Aplicada: 2026-08-11 (SQL Editor de Supabase)
-- =============================================
--
-- CONTEXTO: módulo aislado de la app para vender colecciones de
-- recetas NUEVAS (jugos, sin TACC...) que se descargan al comprar
-- (diseño: docs/diseno_biblioteca.md).
--
--   - colecciones: catálogo público. Las recetas viven en una columna
--     JSONB (mismo formato Receta de la app + campo opcional
--     'keywords' para el buscador propio de la biblioteca). Contenido
--     de solo lectura: se sube por SQL Editor, no se edita desde la app.
--   - RLS: SELECT para todos (anon + authenticated): la tienda se ve
--     sin login. Sin políticas de write: RLS bloquea todo lo demás
--     (service_role tiene BYPASSRLS y sube el contenido).
--   - Las COMPRAS no usan tabla nueva: viven en perfiles.packs (v5)
--     con ids 'yuyo_pack_<coleccion_id>'.
--   - 'version' permite refrescar el cache local: el dueño sube el
--     contador al actualizar contenido y la app re-descarga.

create table public.colecciones (
  id text primary key,                -- 'jugos', 'sin_tacc' (≠ ids de sistemas)
  nombre text not null,
  descripcion text not null default '',
  icono text not null default 'leaf', -- nombre de ícono TablerIcons
  color text not null default 'verde',-- familia visual: 'verde' | 'gris'
  activa boolean not null default true,
  orden int not null default 0,       -- posición en la tienda
  recetas jsonb not null default '[]',-- array de recetas (formato Receta + keywords)
  version int not null default 1,     -- sube al actualizar contenido
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- RLS: lectura pública (tienda visible sin login), escritura solo
-- service_role (sin políticas de write → RLS bloquea a los demás).
alter table public.colecciones enable row level security;

create policy "colecciones_select_public" on public.colecciones
  for select to anon, authenticated using (true);

-- Grants (lección de la v3: sin grants PostgREST responde 42501)
grant select on public.colecciones to anon;
grant select on public.colecciones to authenticated;
grant all on public.colecciones to service_role;
