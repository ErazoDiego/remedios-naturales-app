-- =============================================
-- Remedios Naturales - Migración v5
-- Premium y packs de compra en perfiles
-- Aplicada: 2026-08-10 (SQL Editor de Supabase)
-- =============================================
--
-- CONTEXTO: modelo premium freemium de Yuyo.
--   - premium (bool): compra única que desbloquea todas las recetas,
--     sin anuncios, favoritos/mis recetas ilimitados.
--   - packs (text[]): contenidos comprados por separado (ej: jugos,
--     kefir). IDs de packs en un array Postgres.
--
-- NO requiere nuevas políticas: la v1 ya tiene `perfiles_update_own`
-- (UPDATE con auth.uid() = id) y la v3 ya otorgó grants a
-- authenticated/service_role. Agregar columnas no cambia el RLS.

alter table public.perfiles
  add column if not exists premium boolean not null default false;

alter table public.perfiles
  add column if not exists packs text[] not null default '{}';
