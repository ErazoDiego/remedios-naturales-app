import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/recetas_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/hierbas_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase (auth + base de datos)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

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
        ChangeNotifierProvider(create: (_) => HierbasProvider()),
      ],
      child: MaterialApp.router(
        title: 'Remedios Naturales',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
