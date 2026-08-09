-- =============================================
-- Remedios Naturales - Migración v4
-- Políticas UPDATE para favoritos e historial
-- Aplicada: 2026-08-09 (SQL Editor de Supabase)
-- =============================================
--
-- CAUSA: el servicio usa `upsert ... onConflict(usuario_id, receta_id)`
-- (user_service.dart addFavorite/addToHistory/migrateLocalToCloud).
-- Cuando la fila YA existe, PostgREST ejecuta un UPDATE — y las
-- políticas de la v1 solo cubrían SELECT/INSERT/DELETE. RLS entonces
-- bloquea con 42501 "new row violates row-level security policy":
--   - La 1ª vez que visitás una receta funciona (INSERT).
--   - La 2ª vez que la volvés a visitar falla (UPDATE) y el historial
--     no se actualiza (visto_at viejo, no sube al tope).
--   - Lo mismo con favoritos repetidos y con migrateLocalToCloud.

-- FAVORITOS
create policy "favoritos_update_own" on public.favoritos
  for update using (auth.uid() = usuario_id);

-- HISTORIAL
create policy "historial_update_own" on public.historial
  for update using (auth.uid() = usuario_id);
