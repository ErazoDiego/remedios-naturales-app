import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/services/ads_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/recetas_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/hierbas_provider.dart';
import 'presentation/providers/mis_recetas_provider.dart';
import 'presentation/providers/premium_provider.dart';
import 'presentation/providers/biblioteca_provider.dart';
import 'features/lista_compras/presentation/lista_compras_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase (auth + base de datos)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // Inicializa AdMob (fire-and-forget: no bloquea el arranque)
  MobileAds.instance.initialize();

  // Precarga un intersticial (test) para que esté listo al navegar
  AdsService.instance.preloadInterstitial();

  runApp(const RemediosNaturalesApp());
}

class RemediosNaturalesApp extends StatelessWidget {
  const RemediosNaturalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecetasProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
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
    _sub = context.read<UserProvider>().onPasswordRecovery.listen((_) {
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
