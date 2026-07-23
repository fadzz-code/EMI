import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../auth/domain/session_user.dart';
import '../../auth/presentation/auth_controller.dart';
import 'admin_shell.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final currentPassword = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    currentPassword.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    return AdminShell(
      title: 'Profil Admin',
      fallbackRoute: '/admin/dashboard',
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          if (auth.error != null) EmiCard(child: Text(auth.error!.message)),
          EmiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Admin',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(user?.email ?? 'Belum tersedia'),
                Text('Telepon: ${user?.phone ?? 'Belum tersedia'}'),
                const Text('Peran: Admin'),
              ],
            ),
          ),
          const SizedBox(height: EmiSpacing.md),
          FilledButton.icon(
            key: const Key('adminEditProfile'),
            onPressed: user == null || auth.isLoading
                ? null
                : () => _edit(user),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil'),
          ),
          OutlinedButton.icon(
            key: const Key('adminChangePassword'),
            onPressed: user == null || auth.isLoading ? null : _changePassword,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Ganti Password'),
          ),
          const SizedBox(height: EmiSpacing.lg),
          OutlinedButton(
            key: const Key('adminLogout'),
            onPressed: auth.isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(SessionUser user) async {
    name.text = user.fullName;
    phone.text = user.phone ?? '';
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
            ),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Telepon'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (save != true) return;
    if (name.text.trim().isEmpty) return _snack('Nama wajib diisi.');
    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          fullName: name.text.trim(),
          phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        );
    if (mounted && ref.read(authControllerProvider).error == null) {
      _snack('Profil diperbarui.');
    }
  }

  Future<void> _changePassword() async {
    currentPassword.clear();
    password.clear();
    confirmation.clear();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password saat ini'),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password baru'),
            ),
            TextField(
              controller: confirmation,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (save != true) return;
    if (password.text != confirmation.text) {
      return _snack('Konfirmasi password tidak sama.');
    }
    await ref
        .read(authControllerProvider.notifier)
        .updatePassword(
          currentPassword: currentPassword.text,
          password: password.text,
          passwordConfirmation: confirmation.text,
        );
    if (mounted && ref.read(authControllerProvider).error == null) {
      _snack('Password diperbarui.');
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
