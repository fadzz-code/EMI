import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/error_message.dart';
import 'auth_brand_mark.dart';
import 'auth_controller.dart';
import 'login_validator.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _validator = const LoginValidator();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: EmiColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(EmiSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - EmiSpacing.lg * 2,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AuthBrandMark(),
                        const SizedBox(height: EmiSpacing.xl),
                        EmiCard(
                          hero: true,
                          padding: const EdgeInsets.all(EmiSpacing.lg),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Masuk EMI',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: EmiSpacing.xs),
                                Text(
                                  'Gunakan akun Admin, Guru, atau Siswa yang sudah disetujui pengelola.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: EmiColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: EmiSpacing.lg),
                                TextFormField(
                                  key: const Key('emailField'),
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.mail_outline,
                                      size: 20,
                                    ),
                                  ),
                                  validator: _validator.email,
                                ),
                                const SizedBox(height: EmiSpacing.md),
                                TextFormField(
                                  key: const Key('passwordField'),
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      key: const Key('togglePasswordButton'),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  validator: _validator.password,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () => context.go('/forgot-password'),
                                    child: const Text('Lupa Kata Sandi?'),
                                  ),
                                ),
                                if (auth.error != null) ...[
                                  const SizedBox(height: EmiSpacing.xs),
                                  ErrorMessage(message: auth.error!.message),
                                ],
                                const SizedBox(height: EmiSpacing.sm),
                                ElevatedButton(
                                  key: const Key('loginButton'),
                                  onPressed: auth.isLoading ? null : _submit,
                                  child: auth.isLoading
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Masuk'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: EmiSpacing.lg),
                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => context.go('/register'),
                          child: const Text('Belum punya akun? Daftar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }
}
