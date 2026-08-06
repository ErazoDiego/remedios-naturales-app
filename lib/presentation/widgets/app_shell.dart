import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../core/constants/app_constants.dart';
import '../providers/user_provider.dart';

/// Shell de navegación principal con bottom nav de 4 tabs.
///
/// Usado por StatefulShellRoute.indexedStack: cada tab preserva su estado
/// (scroll, búsqueda, etc.) al cambiar de tab.
///
/// La tab Perfil muestra el avatar del usuario (inicial) si hay sesión,
/// o un ícono genérico si es anónimo.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isLoggedIn = userProvider.isLoggedIn;
    final nombre = userProvider.profile?.nombre ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    final profileIcon = isLoggedIn
        ? CircleAvatar(
            radius: 14,
            backgroundColor: AppConstants.sageGreenTitle,
            child: Text(
              inicial,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )
        : const Icon(
            TablerIcons.user,
            size: 24,
            color: AppConstants.sageGreenTitle,
          );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppConstants.sageGreenCard,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected
                  ? AppConstants.sageGreenTitle
                  : AppConstants.textTertiary,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppConstants.sageGreenTitle
                  : AppConstants.textTertiary,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            // Re-tocar la tab activa: volver a la raíz de esa tab
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(TablerIcons.home),
              label: 'Inicio',
            ),
            const NavigationDestination(
              icon: Icon(TablerIcons.search),
              label: 'Buscar',
            ),
            const NavigationDestination(
              icon: Icon(TablerIcons.heart),
              selectedIcon: Icon(TablerIcons.heart_filled),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: profileIcon,
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
