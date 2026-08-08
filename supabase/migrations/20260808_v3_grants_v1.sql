-- =============================================
-- Remedios Naturales - Migración v3
-- GRANTS para tablas de la v1 (perfiles, favoritos, historial)
-- Aplicada: 2026-08-08 (SQL Editor de Supabase)
-- =============================================
-- La v1 creó las tablas con RLS y políticas pero SIN grants: el SQL
-- Editor de Supabase no otorga permisos automáticamente, por eso
-- PostgREST respondía 42501 "permission denied for table" a todo
-- authenticated (favoritos, historial y perfiles no funcionaban al
-- loguearse). Mismo problema que la v2 resolvió para recetas_usuario.
-- Las políticas RLS filtran igual: cada rol solo ve filas propias.

grant all on public.perfiles to authenticated;
grant all on public.perfiles to service_role;
grant all on public.perfiles to anon;

grant all on public.favoritos to authenticated;
grant all on public.favoritos to service_role;
grant all on public.favoritos to anon;

grant all on public.historial to authenticated;
grant all on public.historial to service_role;
grant all on public.historial to anon;
