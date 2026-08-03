import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/recetas_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/hierbas_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RemediosNaturalesApp());
}

class RemediosNaturalesApp extends StatelessWidget {
  const RemediosNaturalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecetasProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
