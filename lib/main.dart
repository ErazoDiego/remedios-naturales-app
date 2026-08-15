import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/services/ads_service.dart';
import 'core/theme/app_theme.dart';
import 'data/services/auth_service.dart';
import 'presentation/providers/recetas_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/hierbas_provider.dart';
import 'presentation/providers/mis_recetas_provider.dart';
import 'presentation/providers/premium_provider.dart';
import 'presentation/providers/biblioteca_provider.dart';
import 'features/lista_compras/presentation/lista_compras_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase (auth + base de datos).
  //
  // detectSessionInUri: false → el deep link de auth lo manejamos NOSOTROS
  // (ver _handleAuthDeeplink más abajo). Con el observer del SDK, el deep
  // link que lanza la app en frío se procesa DURANTE Supabase.initialize y
  // el evento passwordRecovery se emite antes de que el árbol esté montado
  // → la navegación a /reset-password se pierde y la app abre en el home.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      detectSessionInUri: false,
    ),
  );

  // El UserProvider arranca ANTES de la UI: su suscripción a
  // onAuthStateChange debe estar viva cuando el deep link inicial se
  // procese, para no perder el evento passwordRecovery (que además queda
  // pendiente en consumePendingPasswordRecovery para el listener).
  final auth = AuthService();
  final userProvider = UserProvider(auth: auth);
  await userProvider.init();

  // Deep link de recuperación de contraseña.
  //
  // El stream de app_links entrega el link inicial (el que lanzó la app,
  // onListen del plugin) y los que llegan con la app ya abierta
  // (onNewIntent). No se usa getInitialLink: en Android el plugin emite el
  // link inicial por el stream al primer listener, y llamarlo además
  // duplicaría el canje del código.
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen(
    (uri) => _handleAuthDeeplink(uri),
    onError: (Object e, StackTrace s) =>
        debugPrint('Error en stream de deep links: $e'),
  );

  // Inicializa AdMob (fire-and-forget: no bloquea el arranque)
  MobileAds.instance.initialize();

  // Precarga un intersticial (test) para que esté listo al navegar
  AdsService.instance.preloadInterstitial();

  runApp(RemediosNaturalesApp(userProvider: userProvider));
}

/// Procesa el deep link de recuperación de contraseña.
///
/// Filtra por scheme/host (el intent-filter de Android ya restringe, acá
/// hay doble seguridad) y canjea el código contra Supabase. El evento
/// passwordRecovery que emite el canje lo captura el UserProvider, que
/// ya está suscrito a onAuthStateChange.
Future<void> _handleAuthDeeplink(Uri uri) async {
  if (uri.scheme != 'com.dae.yuyo' || uri.host != 'auth-callback') return;
  debugPrint('[deeplink] URI recibida: $uri');
  try {
    await Supabase.instance.client.auth.getSessionFromUrl(uri);
    debugPrint('[deeplink] Sesión procesada OK desde $uri');
  } catch (e) {
    debugPrint('[deeplink] Error procesando deep link de auth: $e');
  }
}

class RemediosNaturalesApp extends StatelessWidget {
  const RemediosNaturalesApp({super.key, required this.userProvider});

  final UserProvider userProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecetasProvider()),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => PremiumProvider()..init()),
        ChangeNotifierProvider(create: (_) => HierbasProvider()),
        ChangeNotifierProvider(create: (_) => MisRecetasProvider()),
        ChangeNotifierProvider(
          create: (_) => ListaComprasProvider()..init(),
        ),
        ChangeNotifierProvider(
          // IMPORTANTE: usar el context del create (parámetro), NO una
          // variable capturada del build: el context del build está ARRIBA
          // del MultiProvider y no resuelve al PremiumProvider → se crea
          // una segunda instancia vía el fallback de BibliotecaProvider y
          // la compra desde el diálogo premium "no hace nada" en la vista.
          create: (context) =>
              BibliotecaProvider(premium: context.read())..init(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Yuyo',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        // Escucha el deep link de recuperación de contraseña y navega.
        builder: (context, child) =>
            PasswordRecoveryListener(child: child ?? const SizedBox()),
      ),
    );
  }
}

/// Escucha el evento [AuthChangeEvent.passwordRecovery] y navega a la
/// pantalla de nueva contraseña.
///
/// Vive en el `builder` del MaterialApp.router: tiene acceso al contexto
/// del router y al UserProvider (ambos están por encima en el árbol).
class PasswordRecoveryListener extends StatefulWidget {
  const PasswordRecoveryListener({super.key, required this.child});

  final Widget child;

  @override
  State<PasswordRecoveryListener> createState() =>
      _PasswordRecoveryListenerState();
}

class _PasswordRecoveryListenerState extends State<PasswordRecoveryListener> {
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();

    // Evento passwordRecovery que llegó antes de montar la UI (deep link
    // en cold start: el canje ocurre en main() pre-runApp y el provider lo
    // guardó pendiente). La navegación va en un post-frame: en initState
    // el router todavía no puede resolver el contexto.
    if (userProvider.consumePendingPasswordRecovery()) {
      debugPrint('[deeplink] passwordRecovery pendiente → /reset-password');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/reset-password');
      });
    }

    _sub = userProvider.onPasswordRecovery.listen((_) {
      debugPrint('[deeplink] passwordRecovery por stream → /reset-password');
      if (!mounted) return;
      context.go('/reset-password');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
