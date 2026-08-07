-- =============================================
-- Remedios Naturales - Migración v2
-- Recetas propias del usuario (feature premium)
-- Aplicada: 2026-08-07 (SQL Editor de Supabase)
-- =============================================

-- RECETAS USUARIO: recetas creadas por el usuario (premium)
-- Columnas alineadas con el modelo Receta de la app (lib/data/models/receta.dart)
create table public.recetas_usuario (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users (id) on delete cascade,
  nombre text not null,
  descripcion text not null default '',
  ideal_para text[] not null default '{}',
  tipo text not null default '',
  tipo_preparacion text not null default '',
  cuando_usar text,
  precaucion text not null default '',
  ingredientes text[] not null default '{}',
  preparacion text[] not null default '{}',
  dosis text not null default '',
  almacenamiento text not null default '',
  imagen text,
  imagen_placeholder text,
  creado_at timestamptz not null default now(),
  actualizado_at timestamptz not null default now()
);

-- RLS + políticas: cada usuario solo ve/modifica sus propias recetas
alter table public.recetas_usuario enable row level security;

create policy "recetas_usuario_select_own" on public.recetas_usuario
  for select using (auth.uid() = usuario_id);

create policy "recetas_usuario_insert_own" on public.recetas_usuario
  for insert with check (auth.uid() = usuario_id);

create policy "recetas_usuario_update_own" on public.recetas_usuario
  for update using (auth.uid() = usuario_id);

create policy "recetas_usuario_delete_own" on public.recetas_usuario
  for delete using (auth.uid() = usuario_id);

-- Índice para listar "mis recetas" rápido (ordenadas por actualización)
create index recetas_usuario_usuario_idx on public.recetas_usuario (usuario_id, actualizado_at desc);

-- GRANTS: Supabase NO otorga permisos automáticos a tablas creadas vía
-- SQL Editor. Sin estos grants PostgREST responde 42501 "permission denied
-- for table" (verificado empíricamente). Las políticas RLS filtran igual:
-- anon/authenticated solo ven filas propias (auth.uid()).
grant all on public.recetas_usuario to authenticated;
grant all on public.recetas_usuario to service_role;
grant all on public.recetas_usuario to anon;
