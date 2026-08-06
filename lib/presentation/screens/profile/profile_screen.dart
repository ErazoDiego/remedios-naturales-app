import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_profile.dart';
import '../../providers/user_provider.dart';

/// Pantalla de perfil del usuario.
///
/// - Sin sesión: invita a crear una cuenta / iniciar sesión.
/// - Con sesión: muestra nombre, email, estadísticas y cierre de sesión.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _logout() async {
    final userProvider = context.read<UserProvider>();
    final result = await userProvider.signOut();

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión cerrada. Volviste al modo sin conexión.'),
          backgroundColor: AppConstants.sageGreenTitle,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'No se pudo cerrar sesión'),
          backgroundColor: AppConstants.alertRed,
        ),
      );
    }
  }

  Future<void> _editName() async {
    final userProvider = context.read<UserProvider>();
    final controller =
        TextEditingController(text: userProvider.profile?.nombre ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            prefixIcon: Icon(TablerIcons.user),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      await userProvider.updateName(newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.profile;

    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.user_circle, size: 20),
            SizedBox(width: 8),
            Text('Mi perfil'),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: userProvider.isInitializing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: userProvider.isLoggedIn
                  ? _buildLoggedIn(profile)
                  : _buildAnonymous(),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // VISTA LOGUEADO
  // ═══════════════════════════════════════════════════════════════════
  List<Widget> _buildLoggedIn(UserProfile? profile) {
    final nombre = profile?.nombre.isNotEmpty == true
        ? profile!.nombre
        : (profile?.email ?? 'Usuario');
    final email = profile?.email ?? '';
    final fecha = profile?.fechaRegistro;
    final favoritosCount = profile?.favoritos.length ?? 0;
    final historialCount = profile?.historial.length ?? 0;
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return [
      // ═══════════════════════════════════════════════════════════
      // CARD DE IDENTIDAD
      // ═══════════════════════════════════════════════════════════
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.sageGreenCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.borderLight,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppConstants.sageGreenTitle,
              child: Text(
                inicial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            if (fecha != null)
              Text(
                'Miembro desde ${_formatDate(fecha)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textTertiary,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _editName,
                  icon: const Icon(
                    TablerIcons.edit,
                    size: 16,
                    color: AppConstants.sageGreenTitle,
                  ),
                  label: const Text(
                    'Editar nombre',
                    style: TextStyle(color: AppConstants.sageGreenTitle),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // ═══════════════════════════════════════════════════════════
      // ESTADÍSTICAS
      // ═══════════════════════════════════════════════════════════
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: TablerIcons.heart,
              value: '$favoritosCount',
              label: 'Favoritos',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: TablerIcons.history,
              value: '$historialCount',
              label: 'Historial',
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),

      // ═══════════════════════════════════════════════════════════
      // SINCRONIZACIÓN
      // ═══════════════════════════════════════════════════════════
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.borderLight,
            width: 0.5,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              TablerIcons.cloud_lock,
              size: 22,
              color: AppConstants.sageGreenTitle,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tus datos están sincronizados en la nube.\n'
                'La app también funciona sin conexión.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstants.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // ═══════════════════════════════════════════════════════════
      // CERRAR SESIÓN
      // ═══════════════════════════════════════════════════════════
      SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(TablerIcons.logout, size: 18),
          label: const Text('Cerrar sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.alertRed,
            side: const BorderSide(color: AppConstants.alertRed),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════
  // VISTA ANÓNIMO
  // ═══════════════════════════════════════════════════════════════════
  List<Widget> _buildAnonymous() {
    return [
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.borderLight,
            width: 0.5,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              TablerIcons.cloud_off,
              size: 48,
              color: AppConstants.sageGreenTitle,
            ),
            SizedBox(height: 16),
            Text(
              'Tus datos viven en este dispositivo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Creá una cuenta para sincronizar tus favoritos e '
              'historial en la nube y tenerlos en cualquier dispositivo. '
              'Sin cuenta, la app sigue funcionando igual.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: () => context.go('/login'),
          child: const Text(
            'Iniciar sesión',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: () => context.go('/register'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.sageGreenTitle,
            side: const BorderSide(color: AppConstants.sageGreenTitle),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Crear cuenta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppConstants.sageGreenTitle),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
