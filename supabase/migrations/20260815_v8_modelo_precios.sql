-- =============================================
-- Remedios Naturales - Migración v8
-- Nuevo modelo de precios: membresías + lifetime
-- Aplicada: 2026-08-15 (SQL Editor de Supabase)
-- =============================================
--
-- CONTEXTO: el viejo premium era una compra única (bool). El nuevo
-- modelo (2026-08-15) tiene:
--   - Membresía mensual/anual (vencen): premium_until (timestamptz).
--   - Lifetime (compra permanente): lifetime (bool).
--   - Packs (compras individuales PARA SIEMPRE): packs (text[]), ya
--     existente desde la v5 — no se toca.
--
-- El acceso total se DERIVA en la app:
--   esPremiumActivo = lifetime OR premium_until > now()
--
-- La columna `premium` (v5) se DROP: sin clientes reales no hay datos
-- que migrar (app en desarrollo, nunca publicada).
--
-- NO requiere nuevas políticas: la v1 ya tiene `perfiles_update_own`
-- (UPDATE con auth.uid() = id) y la v3 ya otorgó grants. Agregar
-- columnas no cambia el RLS.

alter table public.perfiles
  drop column if exists premium;

alter table public.perfiles
  add column if not exists lifetime boolean not null default false;

alter table public.perfiles
  add column if not exists premium_until timestamptz;
