import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/legal/privacy_policy.dart';
import '../data/auth_providers.dart';
import '../domain/auth_repository.dart';
import '../domain/session_user.dart';
import 'auth_banner.dart';
import 'auth_brand_mark.dart';
import 'auth_card.dart';
import 'auth_controller.dart';
import 'auth_field.dart';
import 'auth_style.dart';
import 'auth_theme_scope.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  var _role = UserRole.student;
  var _schools = const <PublicSchoolOption>[];
  var _classes = const <PublicClassOption>[];
  String? _schoolId;
  String? _classId;
  AppError? _error;
  var _loadingOptions = true;
  var _privacyPolicyAccepted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSchools);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return AuthThemeScope(
      child: Scaffold(
        backgroundColor: AuthStyle.pageBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(EmiSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthBrandMark(icon: Icons.person_add_alt_outlined),
                    const SizedBox(height: EmiSpacing.xl),
                    AuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Daftar Akun EMI',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: AuthStyle.ink),
                            ),
                            const SizedBox(height: EmiSpacing.xs),
                            Text(
                              'Data akan diverifikasi Admin sebelum akun bisa digunakan.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: EmiColors.textSecondary),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: EmiSpacing.md),
                              AuthBanner(message: _error!.message),
                            ],
                            const SizedBox(height: EmiSpacing.lg),
                            AuthDropdownField<UserRole>(
                              label: 'Role',
                              value: _role,
                              items: const [
                                DropdownMenuItem(
                                  value: UserRole.student,
                                  child: Text('Siswa'),
                                ),
                                DropdownMenuItem(
                                  value: UserRole.teacher,
                                  child: Text('Guru'),
                                ),
                              ],
                              onChanged: auth.isLoading
                                  ? null
                                  : (value) => setState(
                                      () => _role = value ?? UserRole.student,
                                    ),
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            AuthField(
                              label: 'Nama lengkap',
                              controller: _nameController,
                              validator: (value) =>
                                  (value ?? '').trim().length < 3
                                  ? 'Nama minimal 3 karakter.'
                                  : null,
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            AuthField(
                              label: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => _validEmail(value ?? '')
                                  ? null
                                  : 'Email tidak valid.',
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            AuthField(
                              label: 'Password',
                              controller: _passwordController,
                              obscureText: true,
                              validator: _passwordError,
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            AuthField(
                              label: 'Konfirmasi password',
                              controller: _passwordConfirmationController,
                              obscureText: true,
                              validator: (value) =>
                                  value != _passwordController.text
                                  ? 'Konfirmasi password tidak sama.'
                                  : null,
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            AuthDropdownField<String>(
                              label: 'Sekolah',
                              value: _schoolId,
                              items: _schools
                                  .map(
                                    (school) => DropdownMenuItem(
                                      value: school.id,
                                      child: Text(
                                        school.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              validator: (value) => value == null
                                  ? 'Sekolah wajib dipilih.'
                                  : null,
                              onChanged: auth.isLoading || _loadingOptions
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _schoolId = value;
                                        _classId = null;
                                        _classes = const [];
                                      });
                                      if (value != null) _loadClasses(value);
                                    },
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            AuthDropdownField<String>(
                              label: 'Kelas',
                              value: _classId,
                              items: _classes
                                  .map(
                                    (schoolClass) => DropdownMenuItem(
                                      value: schoolClass.id,
                                      child: Text(
                                        schoolClass.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              validator: (value) =>
                                  value == null ? 'Kelas wajib dipilih.' : null,
                              onChanged: auth.isLoading || _loadingOptions
                                  ? null
                                  : (value) => setState(() => _classId = value),
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            FormField<bool>(
                              initialValue: _privacyPolicyAccepted,
                              validator: (_) => _privacyPolicyAccepted
                                  ? null
                                  : 'Persetujuan kebijakan privasi wajib diberikan.',
                              builder: (field) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CheckboxListTile(
                                    key: const Key('privacyPolicyCheckbox'),
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    value: _privacyPolicyAccepted,
                                    onChanged: auth.isLoading
                                        ? null
                                        : (value) {
                                            setState(
                                              () => _privacyPolicyAccepted =
                                                  value ?? false,
                                            );
                                            field.didChange(value);
                                          },
                                    title: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        const Text('Saya menyetujui '),
                                        TextButton(
                                          key: const Key(
                                            'registrationPrivacyPolicyLink',
                                          ),
                                          onPressed: () =>
                                              openPrivacyPolicy(context),
                                          child: const Text(
                                            'Kebijakan Privasi',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (field.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: EmiSpacing.md,
                                      ),
                                      child: Text(
                                        field.errorText!,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: EmiSpacing.lg),
                            ElevatedButton(
                              onPressed: auth.isLoading || _loadingOptions
                                  ? null
                                  : _submit,
                              child: auth.isLoading
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Daftar'),
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            const Divider(color: AuthStyle.divider),
                            const SizedBox(height: EmiSpacing.md),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  Text(
                                    'Sudah punya akun? ',
                                    style: TextStyle(
                                      color: EmiColors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: auth.isLoading
                                        ? null
                                        : () => context.go('/login'),
                                    child: Text(
                                      'Masuk',
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

  Future<void> _loadSchools() async {
    try {
      final schools = await ref
          .read(authRepositoryProvider)
          .listPublicSchools();
      if (!mounted) return;
      setState(() {
        _schools = schools;
        _loadingOptions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AppError
            ? error
            : const AppError(
                type: AppErrorType.unknown,
                message: 'Gagal memuat sekolah.',
              );
        _loadingOptions = false;
      });
    }
  }

  Future<void> _loadClasses(String schoolId) async {
    setState(() => _loadingOptions = true);
    try {
      final classes = await ref
          .read(authRepositoryProvider)
          .listPublicClasses(schoolId);
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _loadingOptions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AppError
            ? error
            : const AppError(
                type: AppErrorType.unknown,
                message: 'Gagal memuat kelas.',
              );
        _loadingOptions = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            AuthRegistrationPayload(
              fullName: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              passwordConfirmation: _passwordConfirmationController.text,
              requestedRole: _role,
              schoolId: _schoolId!,
              classId: _classId!,
              privacyPolicyAccepted: _privacyPolicyAccepted,
              privacyPolicyVersion: kPrivacyPolicyVersion,
            ),
          );
      if (mounted) context.go('/account-status');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ref.read(authControllerProvider).error);
    }
  }

  bool _validEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  String? _passwordError(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Password minimal 8 karakter.';
    if (!RegExp('[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Password wajib berisi huruf dan angka.';
    }
    return null;
  }
}
