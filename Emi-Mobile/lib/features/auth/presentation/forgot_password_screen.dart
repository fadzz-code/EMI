import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../data/auth_providers.dart';
import 'auth_banner.dart';
import 'auth_brand_mark.dart';
import 'auth_card.dart';
import 'auth_field.dart';
import 'auth_style.dart';
import 'auth_theme_scope.dart';
import 'login_validator.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _validator = const LoginValidator();
  bool _loading = false;
  String? _message;
  AppError? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthThemeScope(
      child: Scaffold(
        backgroundColor: AuthStyle.pageBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(EmiSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthBrandMark(icon: Icons.lock_reset_outlined),
                    const SizedBox(height: EmiSpacing.xl),
                    AuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Lupa Kata Sandi',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: AuthStyle.ink),
                            ),
                            const SizedBox(height: EmiSpacing.xs),
                            Text(
                              'Masukkan email akunmu. Jika email terdaftar, petunjuk akan dikirim.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: EmiColors.textSecondary),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: EmiSpacing.md),
                              AuthBanner(message: _error!.message),
                            ],
                            if (_message != null) ...[
                              const SizedBox(height: EmiSpacing.md),
                              AuthBanner(
                                message: _message!,
                                tone: AuthBannerTone.success,
                              ),
                            ],
                            const SizedBox(height: EmiSpacing.lg),
                            AuthField(
                              fieldKey: const Key('forgotEmailField'),
                              label: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: _validator.email,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: EmiSpacing.lg),
                            ElevatedButton(
                              key: const Key('sendResetLinkButton'),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Kirim Permintaan Reset'),
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            const Divider(color: AuthStyle.divider),
                            const SizedBox(height: EmiSpacing.md),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  Text(
                                    'Saya sudah punya tautan? ',
                                    style: TextStyle(
                                      color: EmiColors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _loading
                                        ? null
                                        : () => context.go('/reset-password'),
                                    child: Text(
                                      'Buka di sini',
                                      style: TextStyle(
                                        color: EmiColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: EmiSpacing.xs),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  Text(
                                    'Sudah ingat kata sandi? ',
                                    style: TextStyle(
                                      color: EmiColors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _loading
                                        ? null
                                        : () => context.go('/login'),
                                    child: Text(
                                      'Kembali ke halaman masuk',
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
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _message = 'Jika email terdaftar, petunjuk akan dikirim.');
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AppError
            ? error
            : const AppError(
                type: AppErrorType.unknown,
                message: 'Petunjuk belum bisa dikirim. Coba lagi.',
              ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
