import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/coleccion.dart';

/// Repositorio del catálogo de colecciones (tabla pública `colecciones`).
///
/// - Online: lee el catálogo de Supabase (SELECT anónimo, la tienda se
///   ve sin login) y actualiza el cache local.
/// - Offline: devuelve el último catálogo cacheado (fallback).
///
/// El gating (quién tiene qué) NO vive acá: lo maneja PremiumProvider
/// con los packs del perfil. Este repositorio solo trae contenido.
class BibliotecaRepository {
  // Singleton (mismo patrón que UserService).
  static final BibliotecaRepository _instance = BibliotecaRepository._();
  factory BibliotecaRepository() => _instance;
  BibliotecaRepository._();

  static const String _cacheKey = 'biblioteca_cache';

  /// Cliente Supabase inyectable para tests.
  @visibleForTesting
  SupabaseClient? testClient;

  SupabaseClient get _client => testClient ?? Supabase.instance.client;

  /// Catálogo completo de colecciones activas, ordenadas por [orden].
  /// Devuelve lista vacía si falla la red y no hay cache.
  Future<List<Coleccion>> getCatalogo() async {
    try {
      final rows = await _client
          .from('colecciones')
          .select()
          .eq('activa', true)
          .order('orden');
      final catalogo = [
        for (final row in rows) Coleccion.fromJson(row),
      ];
      await _guardarEnCache(catalogo);
      return catalogo;
    } catch (_) {
      return _leerCache();
    }
  }

  /// Cache local del catálogo (SharedPreferences) para modo offline.
  Future<void> _guardarEnCache(List<Coleccion> catalogo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        json.encode([for (final c in catalogo) c.toJson()]),
      );
    } catch (_) {
      // Cache es best-effort: si falla, seguimos con el catálogo en línea.
    }
  }

  Future<List<Coleccion>> _leerCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return const [];
      final decoded = json.decode(raw) as List<dynamic>;
      return [
        for (final coleccion in decoded)
          Coleccion.fromJson(Map<String, dynamic>.from(coleccion as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }
}
