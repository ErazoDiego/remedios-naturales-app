/// Plantilla de configuración de Supabase.
///
/// Para usarla:
/// 1. Copiá este archivo como `supabase_config.dart` (en la misma carpeta)
/// 2. Reemplazá los valores con los de tu proyecto:
///    - Project URL: Settings > General > Project details
///    - Publishable key: Settings > API Keys (empieza con `sb_publishable_`)
///
/// `supabase_config.dart` está en .gitignore — nunca sube keys al repo.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://TU_REFERENCIA.supabase.co';

  static const String anonKey = 'TU_PUBLISHABLE_KEY';
}
