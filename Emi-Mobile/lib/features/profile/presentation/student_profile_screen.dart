import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../auth/domain/session_user.dart';
import '../../auth/presentation/auth_controller.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return EmiScaffold(
      title: 'Profil',
      currentIndex: 4,
      onNavTap: (index) => _go(context, index),
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          if (auth.error != null) ...[
            EmiCard(child: Text(auth.error!.message)),
            const SizedBox(height: EmiSpacing.md),
          ],
          _ProfileHeader(user: user),
          const SizedBox(height: EmiSpacing.lg),
          EmiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileRow(label: 'Email', value: user?.email ?? '-'),
                _ProfileRow(label: 'Telepon', value: user?.phone ?? '-'),
                _ProfileRow(label: 'Role', value: user?.role.value ?? '-'),
                _ProfileRow(label: 'Status', value: user?.status ?? '-'),
                _ProfileRow(
                  label: 'Sekolah',
                  value: user?.activeSchoolName ?? '-',
                ),
                _ProfileRow(
                  label: 'Kelas',
                  value: user?.activeClassName ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: EmiSpacing.lg),
          ElevatedButton.icon(
            onPressed: user == null || auth.isLoading
                ? null
                : () => _showEditProfile(user),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil'),
          ),
          const SizedBox(height: EmiSpacing.sm),
          OutlinedButton.icon(
            onPressed: user == null || auth.isLoading
                ? null
                : _showChangePassword,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Ganti Password'),
          ),
          const SizedBox(height: EmiSpacing.lg),
          OutlinedButton(
            onPressed: auth.isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, int index) {
    if (index == 0) context.go('/student/dashboard');
    if (index == 1) context.go('/student/modules');
    if (index == 2) context.go('/student/dictionary');
    if (index == 3) context.go('/student/quizzes');
    if (index == 4) context.go('/student/profile');
  }

  Future<void> _showEditProfile(SessionUser user) async {
    _nameController.text = user.fullName;
    _phoneController.text = user.phone ?? '';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telepon'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('Nama wajib diisi.');
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          fullName: name,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
    if (mounted && ref.read(authControllerProvider).error == null) {
      _snack('Profil diperbarui.');
    }
  }

  Future<void> _showChangePassword() async {
    _currentPasswordController.clear();
    _passwordController.clear();
    _passwordConfirmationController.clear();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password saat ini'),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password baru'),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              controller: _passwordConfirmationController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    if (_passwordController.text != _passwordConfirmationController.text) {
      _snack('Konfirmasi password tidak sama.');
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .updatePassword(
          currentPassword: _currentPasswordController.text,
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
        );
    if (mounted && ref.read(authControllerProvider).error == null) {
      _snack('Password diperbarui.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final SessionUser? user;

  @override
  Widget build(BuildContext context) {
    return EmiCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: EmiColors.secondary,
            backgroundImage: user?.avatarUrl == null
                ? null
                : NetworkImage(user!.avatarUrl!),
            child: user?.avatarUrl == null
                ? Text(
                    (user?.fullName.isNotEmpty ?? false)
                        ? user!.fullName.characters.first
                        : '?',
                  )
                : null,
          ),
          const SizedBox(width: EmiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? '-',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(user?.email ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(value),
        ],
      ),
    );
  }
}
