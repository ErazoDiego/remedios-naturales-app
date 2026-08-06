import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/user_provider.dart';

/// Pantalla de registro con email y contraseña.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá tu email';
    }
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+(\.[\w\-]+)+$');
    if (!regex.hasMatch(value.trim())) {
      return 'El email no es válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresá una contraseña';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Repetí la contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final userProvider = context.read<UserProvider>();
    final result = await userProvider.signUp(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'No se pudo crear la cuenta'),
          backgroundColor: AppConstants.alertRed,
        ),
      );
      return;
    }

    if (result.emailConfirmationRequired) {
      // El proyecto pide confirmar email: avisar y volver al login
      _showEmailConfirmationDialog();
    } else {
      // Sesión creada: volver al inicio ya logueado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada! Tus favoritos se sincronizaron.'),
          backgroundColor: AppConstants.sageGreenTitle,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  void _showEmailConfirmationDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          TablerIcons.mail_opened,
          size: 40,
          color: AppConstants.sageGreenTitle,
        ),
        title: const Text('Revisá tu email'),
        content: Text(
          'Te enviamos un link de confirmación a '
          '${_emailController.text}. '
          'Confirmá tu cuenta y después iniciá sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: AppConstants.sageGreenTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.user_plus, size: 20),
            SizedBox(width: 8),
            Text('Crear cuenta'),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header decorativo
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
                child: const Column(
                  children: [
                    Icon(
                      TablerIcons.cloud_upload,
                      size: 40,
                      color: AppConstants.sageGreenTitle,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Creá tu cuenta gratuita',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.sageGreenTitle,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tus favoritos e historial se sincronizarán '
                      'en la nube y quedarán disponibles en cualquier '
                      'dispositivo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppConstants.sageGreenSubtitle,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'tu@email.com',
                  prefixIcon: Icon(TablerIcons.mail),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  helperText: 'Mínimo 6 caracteres',
                  prefixIcon: const Icon(TablerIcons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? TablerIcons.eye
                          : TablerIcons.eye_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),

              // Confirmar contraseña
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Repetí la contraseña',
                  prefixIcon: const Icon(TablerIcons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? TablerIcons.eye
                          : TablerIcons.eye_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: _validateConfirm,
              ),
              const SizedBox(height: 24),

              // Botón de registro
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Registrarme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Link a login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Ya tenés cuenta?',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _submitting ? null : () => context.go('/login'),
                    child: const Text(
                      'Iniciá sesión',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.sageGreenTitle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
