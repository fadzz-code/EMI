import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/error_message.dart';
import '../data/auth_providers.dart';
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
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: EmiColors.primarySoft,
                      borderRadius: BorderRadius.circular(EmiRadii.pill),
                    ),
                    child: const Icon(
                      Icons.lock_reset_outlined,
                      size: 32,
                      color: EmiColors.primary,
                    ),
                  ),
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
                            'Lupa Kata Sandi',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: EmiSpacing.xs),
                          Text(
                            'Masukkan email akunmu. Jika email terdaftar, petunjuk akan dikirim.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: EmiColors.textSecondary),
                          ),
                          const SizedBox(height: EmiSpacing.lg),
                          TextFormField(
                            key: const Key('forgotEmailField'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline, size: 20),
                            ),
                            validator: _validator.email,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: EmiSpacing.sm),
                            ErrorMessage(message: _error!.message),
                          ],
                          if (_message != null) ...[
                            const SizedBox(height: EmiSpacing.sm),
                            Text(
                              _message!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: EmiColors.success),
                            ),
                          ],
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
                                : const Text('Kirim Tautan'),
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => context.go('/reset-password'),
                            child: const Text('Saya sudah punya tautan'),
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
