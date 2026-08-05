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

/// Configuración de rutas de la aplicación
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Home
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      
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
      
      // Búsqueda
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchScreen(initialQuery: query);
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
      
      // Favoritos
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
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

      // Perfil
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
