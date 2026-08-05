-- =============================================
-- Remedios Naturales - Migración v1
-- Tablas de usuario: perfiles, favoritos, historial
-- Aplicada: 2026-08-04 (SQL Editor de Supabase)
-- =============================================

-- 1. PERFILES: datos básicos de cada usuario
create table public.perfiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nombre text not null default '',
  fecha_registro timestamptz not null default now()
);

-- RLS + políticas: cada usuario solo ve/modifica su propio perfil
alter table public.perfiles enable row level security;

create policy "perfiles_select_own" on public.perfiles
  for select using (auth.uid() = id);

create policy "perfiles_insert_own" on public.perfiles
  for insert with check (auth.uid() = id);

create policy "perfiles_update_own" on public.perfiles
  for update using (auth.uid() = id);

-- 2. FAVORITOS: recetas guardadas por usuario
create table public.favoritos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users (id) on delete cascade,
  receta_id text not null,
  creado_at timestamptz not null default now(),
  unique (usuario_id, receta_id)
);

alter table public.favoritos enable row level security;

create policy "favoritos_select_own" on public.favoritos
  for select using (auth.uid() = usuario_id);

create policy "favoritos_insert_own" on public.favoritos
  for insert with check (auth.uid() = usuario_id);

create policy "favoritos_delete_own" on public.favoritos
  for delete using (auth.uid() = usuario_id);

-- 3. HISTORIAL: recetas visitadas por usuario
create table public.historial (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users (id) on delete cascade,
  receta_id text not null,
  visto_at timestamptz not null default now(),
  unique (usuario_id, receta_id)
);

alter table public.historial enable row level security;

create policy "historial_select_own" on public.historial
  for select using (auth.uid() = usuario_id);

create policy "historial_insert_own" on public.historial
  for insert with check (auth.uid() = usuario_id);

create policy "historial_delete_own" on public.historial
  for delete using (auth.uid() = usuario_id);

-- Índices para que las consultas de cada usuario sean rápidas
create index favoritos_usuario_idx on public.favoritos (usuario_id);
create index historial_usuario_idx on public.historial (usuario_id);
