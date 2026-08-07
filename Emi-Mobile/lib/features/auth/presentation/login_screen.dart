import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../data/auth_providers.dart';
import 'auth_banner.dart';
import 'auth_brand_mark.dart';
import 'auth_card.dart';
import 'auth_controller.dart';
import 'auth_field.dart';
import 'auth_style.dart';
import 'auth_theme_scope.dart';
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
    final branding = ref.watch(loginBrandingProvider).valueOrNull;
    final hasBanner = branding?['enabled'] == true && branding?['image_url'] != null;

    return AuthThemeScope(
      child: Scaffold(
        backgroundColor: AuthStyle.pageBackground,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AuthBrandMark(),
                          if (hasBanner) ...[
                            const SizedBox(height: EmiSpacing.md),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AuthStyle.fieldRadius),
                              child: Image.network(
                                branding!['image_url'] as String,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                              ),
                            ),
                          ],
                          const SizedBox(height: EmiSpacing.xl),
                          AuthCard(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Masuk EMI',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(color: AuthStyle.ink),
                                  ),
                                  const SizedBox(height: EmiSpacing.xs),
                                  Text(
                                    'Gunakan akun Admin, Guru, atau Siswa yang sudah disetujui pengelola.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: EmiColors.textSecondary,
                                        ),
                                  ),
                                  if (auth.error != null) ...[
                                    const SizedBox(height: EmiSpacing.md),
                                    AuthBanner(message: auth.error!.message),
                                  ],
                                  const SizedBox(height: EmiSpacing.lg),
                                  AuthField(
                                    fieldKey: const Key('emailField'),
                                    label: 'Email',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: _validator.email,
                                  ),
                                  const SizedBox(height: EmiSpacing.md),
                                  AuthField(
                                    fieldKey: const Key('passwordField'),
                                    label: 'Password',
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
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
                                        color: AuthStyle.ink,
                                      ),
                                    ),
                                    validator: _validator.password,
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                  const SizedBox(height: EmiSpacing.sm),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : () =>
                                                context.go('/forgot-password'),
                                      child: const Text('Lupa Kata Sandi?'),
                                    ),
                                  ),
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
                                  const SizedBox(height: EmiSpacing.md),
                                  const Divider(color: AuthStyle.divider),
                                  const SizedBox(height: EmiSpacing.md),
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        Text(
                                          'Belum punya akun? ',
                                          style: TextStyle(
                                            color: EmiColors.textSecondary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: auth.isLoading
                                              ? null
                                              : () => context.go('/register'),
                                          child: Text(
                                            'Daftar',
                                            style: TextStyle(
                                              color: EmiColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
