import 'package:go_router/go_router.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/category/category_screen.dart';
import '../../presentation/screens/remedy_detail/remedy_detail_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/by_symptom/by_symptom_screen.dart';
import '../../presentation/screens/favorites/favorites_screen.dart';
import '../../presentation/screens/herbolario/herbolario_screen.dart';
import '../../presentation/screens/herba_detail/herba_detail_screen.dart';
import '../../presentation/screens/fundamentals/fundamentals_screen.dart';
import '../../presentation/screens/safety/safety_screen.dart';
import '../../presentation/screens/about/about_screen.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/register/register_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/widgets/app_shell.dart';

/// Configuración de rutas de la aplicación
///
/// - 4 tabs raíz (Inicio/Buscar/Favoritos/Perfil) viven dentro de un
///   StatefulShellRoute.indexedStack: preservan estado entre cambios de tab.
/// - El resto (detalles de receta, hierbas, categorías, auth...) son
///   pantallas full-screen SIN bottom nav, con botón atrás.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // ═══════════════════════════════════════════════════════════════
      // SHELL CON BOTTOM NAV - 4 tabs
      // ═══════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // ─── Tab Inicio ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // ─── Tab Buscar ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) {
                  final query =
                      state.uri.queryParameters['q'] ?? '';
                  return SearchScreen(initialQuery: query);
                },
              ),
            ],
          ),
          // ─── Tab Favoritos ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          // ─── Tab Perfil ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════
      // PANTALLAS FULL-SCREEN (sin bottom nav)
      // ═══════════════════════════════════════════════════════════════

      // Categoría (sistema corporal)
      GoRoute(
        path: '/category/:systemId',
        builder: (context, state) {
          final systemId = state.pathParameters['systemId']!;
          return CategoryScreen(systemId: systemId);
        },
      ),

      // Detalle de receta
      GoRoute(
        path: '/remedy/:recipeId',
        builder: (context, state) {
          final recipeId = state.pathParameters['recipeId']!;
          return RemedyDetailScreen(recipeId: recipeId);
        },
      ),

      // Por síntoma
      GoRoute(
        path: '/symptom/:condition',
        builder: (context, state) {
          final condition = state.pathParameters['condition']!;
          return BySymptomScreen(condition: condition);
        },
      ),

      // Herbolario (directorio de hierbas)
      GoRoute(
        path: '/herbolario',
        builder: (context, state) => const HerbolarioScreen(),
      ),

      // Detalle de hierba
      GoRoute(
        path: '/herba/:herbaId',
        builder: (context, state) {
          final herbaId = state.pathParameters['herbaId']!;
          return HerbaDetailScreen(herbaId: herbaId);
        },
      ),

      // Fundamentos
      GoRoute(
        path: '/fundamentals',
        builder: (context, state) => const FundamentalsScreen(),
      ),

      // Seguridad
      GoRoute(
        path: '/safety',
        builder: (context, state) => const SafetyScreen(),
      ),

      // Acerca de
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),

      // Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Registro
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
}
