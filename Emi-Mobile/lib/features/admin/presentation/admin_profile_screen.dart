import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/legal/privacy_policy.dart';
import '../../auth/domain/session_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/avatar_validator.dart';
import 'admin_shell.dart';
import 'admin_style.dart';
import 'admin_widgets.dart';

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
  final _avatarValidator = const AvatarValidator();
  final _picker = ImagePicker();
  XFile? _avatarPreview;

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
          if (auth.error != null) ...[
            AdminCard(
              child: Text(
                auth.error!.message,
                style: const TextStyle(color: EmiColors.error),
              ),
            ),
            const SizedBox(height: EmiSpacing.md),
          ],
          AdminCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: auth.isLoading ? null : _pickAvatar,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AdminStyle.tint,
                    foregroundImage: _avatarPreview != null
                        ? FileImage(File(_avatarPreview!.path))
                        : user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: _avatarPreview == null && user?.avatarUrl == null
                        ? Text(
                            (user?.fullName.isNotEmpty == true
                                    ? user!.fullName[0]
                                    : 'A')
                                .toUpperCase(),
                            style: const TextStyle(
                              color: EmiColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: EmiSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Admin',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'Belum tersedia',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AdminStyle.inkMuted,
                        ),
                      ),
                      Text(
                        'Telepon: ${user?.phone ?? 'Belum tersedia'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AdminStyle.inkMuted,
                        ),
                      ),
                      const SizedBox(height: EmiSpacing.xs),
                      const Text(
                        'Peran: Admin',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EmiSpacing.md),
          OutlinedButton.icon(
            key: const Key('adminChangeAvatar'),
            onPressed: user == null || auth.isLoading ? null : _pickAvatar,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Ganti Foto Profil'),
          ),
          if (user?.avatarUrl != null) ...[
            const SizedBox(height: EmiSpacing.sm),
            TextButton.icon(
              key: const Key('adminDeleteAvatar'),
              onPressed: auth.isLoading
                  ? null
                  : () => ref
                        .read(authControllerProvider.notifier)
                        .deleteAvatar(),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus Foto Profil'),
            ),
          ],
          const SizedBox(height: EmiSpacing.sm),
          FilledButton.icon(
            key: const Key('adminEditProfile'),
            onPressed: user == null || auth.isLoading
                ? null
                : () => _edit(user),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil'),
          ),
          const SizedBox(height: EmiSpacing.sm),
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
          const SizedBox(height: EmiSpacing.sm),
          TextButton.icon(
            key: const Key('privacyPolicyLink'),
            onPressed: () => openPrivacyPolicy(context),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Kebijakan Privasi'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final validation = _avatarValidator.validate(
      fileName: file.name,
      sizeBytes: await File(file.path).length(),
    );
    if (!validation.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validation.message!)));
      }
      return;
    }
    setState(() => _avatarPreview = file);
    await ref
        .read(authControllerProvider.notifier)
        .uploadAvatar(path: file.path, fileName: file.name);
    if (mounted) setState(() => _avatarPreview = null);
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
