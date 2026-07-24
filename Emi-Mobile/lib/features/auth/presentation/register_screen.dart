import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/error_message.dart';
import '../data/auth_providers.dart';
import '../domain/auth_repository.dart';
import '../domain/session_user.dart';
import 'auth_controller.dart';

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

    return Scaffold(
      backgroundColor: EmiColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(EmiSpacing.lg),
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
                      Icons.person_add_alt_outlined,
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Daftar Akun EMI',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: EmiSpacing.xs),
                          Text(
                            'Data akan diverifikasi Admin sebelum akun bisa digunakan.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: EmiColors.textSecondary),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: EmiSpacing.sm),
                            ErrorMessage(message: _error!.message),
                          ],
                          const SizedBox(height: EmiSpacing.lg),
                          DropdownButtonFormField<UserRole>(
                            initialValue: _role,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                            ),
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
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                            ),
                            validator: (value) =>
                                (value ?? '').trim().length < 3
                                ? 'Nama minimal 3 karakter.'
                                : null,
                          ),
                          const SizedBox(height: EmiSpacing.md),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline, size: 20),
                            ),
                            validator: (value) => _validEmail(value ?? '')
                                ? null
                                : 'Email tidak valid.',
                          ),
                          const SizedBox(height: EmiSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline, size: 20),
                            ),
                            validator: _passwordError,
                          ),
                          const SizedBox(height: EmiSpacing.md),
                          TextFormField(
                            controller: _passwordConfirmationController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Konfirmasi password',
                              prefixIcon: Icon(Icons.lock_outline, size: 20),
                            ),
                            validator: (value) =>
                                value != _passwordController.text
                                ? 'Konfirmasi password tidak sama.'
                                : null,
                          ),
                          const SizedBox(height: EmiSpacing.md),
                          DropdownButtonFormField<String>(
                            initialValue: _schoolId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Sekolah',
                            ),
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
                            validator: (value) =>
                                value == null ? 'Sekolah wajib dipilih.' : null,
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
                          DropdownButtonFormField<String>(
                            initialValue: _classId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Kelas',
                            ),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: EmiSpacing.lg),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () => context.go('/login'),
                    child: const Text('Sudah punya akun? Login'),
                  ),
                ],
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
