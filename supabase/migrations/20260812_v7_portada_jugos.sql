-- =============================================
-- Remedios Naturales - Migración v7 - PORTADA
-- Colección: "Jugos y batidos naturales"
-- Aplicar en el SQL Editor de Supabase (re-aplicable).
-- =============================================
--
-- Carga la imagen de portada de la colección 'jugos' (thumbnail de la
-- biblioteca, opción A). El asset ya viaja dentro del APK
-- (assets/images/recetas/portada_jugos.webp); la app hace fallback al
-- ícono + color si el campo es null o el asset no carga.
--
-- Nota: la columna 'imagen' NO existía en colecciones (solo en
-- recetas_usuario y dentro del JSONB recetas). Por eso el UPDATE v7
-- original falló con 42703. Este script la crea primero (idempotente).

alter table public.colecciones
    add column if not exists imagen text;

update public.colecciones
set imagen = 'assets/images/recetas/portada_jugos.webp',
    actualizado_en = now()
where id = 'jugos';
