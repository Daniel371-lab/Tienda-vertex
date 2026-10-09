import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/vertex_logo.dart';
import '../controllers/auth_controller.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(loginControllerProvider);
    _emailCtrl = TextEditingController(text: s.email);
    _passwordCtrl = TextEditingController(text: s.password);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final ctrl = ref.read(loginControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: VertexLogo(markSize: 56, wordmarkSize: 22)),
                  const SizedBox(height: 32),
                  Text(
                    'Panel de administración',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acceso restringido',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // Email
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Text(
                      'Correo electrónico',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    onChanged: ctrl.setEmail,
                    decoration: const InputDecoration(
                      hintText: 'tu@email.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Text(
                      'Contraseña',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: state.obscurePassword,
                    onChanged: ctrl.setPassword,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        onPressed: ctrl.toggleObscure,
                        icon: Icon(
                          state.obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 18, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: state.isSubmitting ? null : _submit,
                      icon: state.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(
                        state.isSubmitting ? 'Ingresando...' : 'Ingresar',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Acceso exclusivo para administración',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    await ref.read(loginControllerProvider.notifier).signIn();
    // El router detectará el cambio de sesión y navegará solo.
  }
}