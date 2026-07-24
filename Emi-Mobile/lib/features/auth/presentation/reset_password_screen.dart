import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/error_message.dart';
import '../data/auth_providers.dart';
import 'auth_brand_mark.dart';
import 'login_validator.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _validator = const LoginValidator();
  bool _loading = false;
  bool _done = false;
  AppError? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EmiSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthBrandMark(icon: Icons.key_outlined),
                  const SizedBox(height: EmiSpacing.xl),
                  EmiCard(
                    padding: const EdgeInsets.all(EmiSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Buat Kata Sandi Baru',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: EmiSpacing.xs),
                          Text(
                            'Isi email, kode dari tautan, dan kata sandi baru.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: EmiColors.textSecondary),
                          ),
                          const SizedBox(height: EmiSpacing.lg),
                          TextFormField(
                            key: const Key('resetEmailField'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline, size: 20),
                            ),
                            validator: _validator.email,
                          ),
                          const SizedBox(height: EmiSpacing.md),
                          TextFormField(
                            key: const Key('resetTokenField'),
                            controller: _tokenController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Kode dari Tautan',
                              prefixIcon: Icon(
                                Icons.confirmation_number_outlined,
                                size: 20,
                              ),
                            ),
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true)
                                ? 'Kode wajib diisi.'
                                : null,
                          ),
                          const SizedBox(height: EmiSpacing.md),
                          TextFormField(
                            key: const Key('resetPasswordField'),
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Kata Sandi Baru',
                              prefixIcon: Icon(Icons.lock_outline, size: 20),
                            ),
                            validator: _validator.password,
                          ),
                          const SizedBox(height: EmiSpacing.md),
                          TextFormField(
                            key: const Key('resetConfirmPasswordField'),
                            controller: _confirmController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Ulangi Kata Sandi',
                              prefixIcon: Icon(Icons.lock_outline, size: 20),
                            ),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'Ulangi kata sandi wajib diisi.';
                              }
                              if (value != _passwordController.text) {
                                return 'Kata sandi belum sesuai.';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: EmiSpacing.sm),
                            ErrorMessage(message: _error!.message),
                          ],
                          if (_done) ...[
                            const SizedBox(height: EmiSpacing.sm),
                            Text(
                              'Kata sandi berhasil diubah.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: EmiColors.success),
                            ),
                          ],
                          const SizedBox(height: EmiSpacing.lg),
                          ElevatedButton(
                            key: const Key('resetPasswordButton'),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Simpan Kata Sandi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: EmiSpacing.lg),
                  TextButton(
                    onPressed: _loading ? null : () => context.go('/login'),
                    child: const Text('Kembali ke Login'),
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
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _done = false;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: _emailController.text.trim(),
            token: _tokenController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmController.text,
          );
      if (!mounted) return;
      setState(() => _done = true);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AppError
            ? error
            : const AppError(
                type: AppErrorType.validation,
                message:
                    'Tautan sudah tidak berlaku. Silakan minta tautan baru.',
              ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
