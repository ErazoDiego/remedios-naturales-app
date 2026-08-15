import 'package:go_router/go_router.dart';
import '../../data/models/receta_usuario.dart';
import '../../data/services/auth_service.dart';
import '../../features/biblioteca/presentation/biblioteca_screen.dart';
import '../../features/biblioteca/presentation/coleccion_screen.dart';
import '../../features/biblioteca/presentation/receta_coleccion_screen.dart';
import '../../features/biblioteca/presentation/tienda_screen.dart';
import '../../features/lista_compras/presentation/lista_compras_screen.dart';
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
import '../../presentation/screens/forgot_password/forgot_password_screen.dart';
import '../../presentation/screens/reset_password/reset_password_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/mis_recetas/mis_recetas_screen.dart';
import '../../presentation/screens/receta_usuario_form/receta_usuario_form_screen.dart';
import '../../presentation/screens/receta_usuario_detail/receta_usuario_detail_screen.dart';
import '../../presentation/screens/premium/premium_screen.dart';
import '../../presentation/widgets/app_shell.dart';

/// Configuración de rutas de la aplicación
///
/// - 5 tabs raíz (Inicio/Buscar/Biblioteca/Favoritos/Perfil) viven dentro
///   de un StatefulShellRoute.indexedStack: preservan estado entre cambios
///   de tab. La biblioteca (y sus sub-pantallas) vive dentro de su tab.
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
          // ─── Tab Biblioteca (colecciones) ───
          // Las sub-pantallas viven DENTRO de la rama: el bottom nav
          // persiste en tienda, colección y detalle de receta.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/biblioteca',
                builder: (context, state) => const BibliotecaScreen(),
                routes: [
                  // 'tienda' va antes que ':coleccionId' para que no sea
                  // capturado como id de colección.
                  GoRoute(
                    path: 'tienda',
                    builder: (context, state) => const TiendaScreen(),
                  ),
                  GoRoute(
                    path: ':coleccionId',
                    builder: (context, state) => ColeccionScreen(
                      coleccionId: state.pathParameters['coleccionId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: ':recetaId',
                        builder: (context, state) => RecetaColeccionScreen(
                          coleccionId:
                              state.pathParameters['coleccionId']!,
                          recetaId: state.pathParameters['recetaId']!,
                        ),
                      ),
                    ],
                  ),
                ],
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

      // Recuperar contraseña: solicitar el link por email
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Contraseña nueva: solo se llega con la sesión de recovery del
      // deep link (email → link → evento passwordRecovery). Sin sesión
      // activa no hay token validado → a login.
      GoRoute(
        path: '/reset-password',
        redirect: (context, state) {
          final isLoggedIn = AuthService().isLoggedIn;
          return isLoggedIn ? null : '/login';
        },
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Premium (compra única)
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),

      // Lista de compras (full-screen, fuera de las 5 tabs: la lista es
      // del usuario, no un lugar de la app)
      GoRoute(
        path: '/lista-compras',
        builder: (context, state) => const ListaComprasScreen(),
      ),

      // ═══════════════════════════════════════════════════════════
      // MIS RECETAS (recetas propias del usuario - premium)
      // ═══════════════════════════════════════════════════════════
      GoRoute(
        path: '/mis-recetas',
        builder: (context, state) => const MisRecetasScreen(),
      ),

      // Crear receta nueva
      GoRoute(
        path: '/mis-recetas/nueva',
        builder: (context, state) => const RecetaUsuarioFormScreen(),
      ),

      // Detalle de receta propia (la receta viaja en `extra`; sin
      // extra = deep link inválido → volvemos a la lista)
      GoRoute(
        path: '/mis-recetas/:id',
        redirect: (context, state) =>
            state.extra == null ? '/mis-recetas' : null,
        builder: (context, state) => RecetaUsuarioDetailScreen(
          receta: state.extra! as RecetaUsuario,
        ),
      ),

      // Editar receta propia
      GoRoute(
        path: '/mis-recetas/:id/editar',
        redirect: (context, state) =>
            state.extra == null ? '/mis-recetas' : null,
        builder: (context, state) => RecetaUsuarioFormScreen(
          receta: state.extra! as RecetaUsuario,
        ),
      ),
    ],
  );
}
