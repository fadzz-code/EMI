import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/error_message.dart';
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
                  child: EmiCard(
                    padding: const EdgeInsets.all(EmiSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Masuk EMI',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: EmiSpacing.xs),
                          const Text(
                            'Gunakan akun Admin, Guru, atau Siswa yang sudah disetujui pengelola.',
                          ),
                          const SizedBox(height: EmiSpacing.lg),
                          TextFormField(
                            key: const Key('emailField'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
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
                              suffixIcon: IconButton(
                                key: const Key('togglePasswordButton'),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: _validator.password,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (auth.error != null) ...[
                            const SizedBox(height: EmiSpacing.md),
                            ErrorMessage(message: auth.error!.message),
                          ],
                          const SizedBox(height: EmiSpacing.lg),
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
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => context.go('/forgot-password'),
                            child: const Text('Lupa Kata Sandi'),
                          ),
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => context.go('/register'),
                            child: const Text('Daftar akun Guru/Siswa'),
                          ),
                        ],
                      ),
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
