import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/network/network_status_controller.dart';
import '../../../shared/legal/privacy_policy.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_connectivity_banner.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../../auth/domain/session_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../teacher/presentation/teacher_shell.dart';
import 'avatar_validator.dart';

String _roleLabel(UserRole role) => switch (role) {
  UserRole.admin => 'Administrator',
  UserRole.teacher => 'Guru',
  UserRole.student => 'Siswa',
  UserRole.unknown => 'Tidak diketahui',
};

String _statusLabel(String status) => switch (status) {
  'approved' => 'Disetujui',
  'pending' => 'Menunggu persetujuan',
  'rejected' => 'Ditolak',
  'disabled' => 'Dinonaktifkan',
  _ => status,
};

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key, this.teacher = false});

  final bool teacher;

  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  final _avatarValidator = const AvatarValidator();
  final _picker = ImagePicker();
  XFile? _avatarPreview;
  double? _avatarProgress;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _deleteAccountPasswordController = TextEditingController();
  bool _isDeletingAccount = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _deleteAccountPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final networkMode = ref.watch(networkStatusControllerProvider).mode;

    final isStudent = user?.role == UserRole.student;

    final content = ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        StudentConnectivityBanner(mode: networkMode),
        if (auth.error != null) ...[
          StudentPlaceholder(
            icon: Icons.error_outline,
            title: 'Terjadi Kesalahan',
            message: auth.error!.message,
          ),
          const SizedBox(height: EmiSpacing.md),
        ],
        _ProfileHeader(
          user: user,
          previewPath: _avatarPreview?.path,
          progress: _avatarProgress,
          isBusy: auth.isLoading,
          onPick: user == null || auth.isLoading ? null : _pickAvatar,
          onDelete: user == null || user.avatarUrl == null || auth.isLoading
              ? null
              : _confirmDeleteAvatar,
        ),
        const StudentSectionHeader(
          'Informasi Akun',
          icon: Icons.badge_outlined,
        ),
        StudentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileRow(label: 'Email', value: user?.email ?? '-'),
              _ProfileRow(label: 'Telepon', value: user?.phone ?? '-'),
              _ProfileRow(
                label: 'Peran',
                value: user == null ? '-' : _roleLabel(user.role),
              ),
              _ProfileRow(
                label: 'Status',
                value: user == null ? '-' : _statusLabel(user.status),
              ),
              _ProfileRow(
                label: 'Sekolah',
                value: user?.activeSchoolName ?? '-',
              ),
              _ProfileRow(label: 'Kelas', value: user?.activeClassName ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: EmiSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: user == null || auth.isLoading
                ? null
                : () => _showEditProfile(user),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil'),
          ),
        ),
        const SizedBox(height: EmiSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: user == null || auth.isLoading
                ? null
                : _showChangePassword,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Ganti Password'),
          ),
        ),
        const SizedBox(height: EmiSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: auth.isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Logout'),
          ),
        ),
        const SizedBox(height: EmiSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            key: const Key('privacyPolicyLink'),
            onPressed: () => openPrivacyPolicy(context),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Kebijakan Privasi'),
          ),
        ),
        const SizedBox(height: EmiSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: EmiColors.error,
              side: const BorderSide(color: EmiColors.error),
            ),
            onPressed: user == null || auth.isLoading
                ? null
                : _showDeleteAccount,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Hapus Akun'),
          ),
        ),
      ],
    );

    if (widget.teacher) {
      return TeacherShell(title: 'Profil', child: content);
    }

    return EmiScaffold(
      title: 'Profil',
      currentIndex: isStudent ? 4 : null,
      onNavTap: isStudent ? (index) => _go(context, index) : null,
      child: content,
    );
  }

  void _go(BuildContext context, int index) {
    if (index == 0) context.go('/student/dashboard');
    if (index == 1) context.go('/student/modules');
    if (index == 2) context.go('/student/dictionary');
    if (index == 3) context.go('/student/quizzes');
    if (index == 4) context.go('/student/profile');
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final result = _avatarValidator.validate(
      fileName: picked.name,
      sizeBytes: await picked.length(),
    );
    if (!result.isValid) {
      _snack(result.message!);
      return;
    }

    setState(() {
      _avatarPreview = picked;
      _avatarProgress = 0;
    });
    await ref
        .read(authControllerProvider.notifier)
        .uploadAvatar(
          path: picked.path,
          fileName: picked.name,
          onSendProgress: (sent, total) {
            if (!mounted || total <= 0) return;
            setState(() => _avatarProgress = sent / total);
          },
        );
    if (!mounted) return;
    if (ref.read(authControllerProvider).error == null) {
      setState(() {
        _avatarPreview = null;
        _avatarProgress = null;
      });
      _snack('Avatar diperbarui.');
    } else {
      setState(() => _avatarProgress = null);
    }
  }

  Future<void> _confirmDeleteAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Avatar'),
        content: const Text('Avatar profil akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _avatarProgress = 0);
    await ref.read(authControllerProvider.notifier).deleteAvatar();
    if (!mounted) return;
    setState(() {
      _avatarPreview = null;
      _avatarProgress = null;
    });
    if (ref.read(authControllerProvider).error == null) {
      _snack('Avatar dihapus.');
    }
  }

  Future<void> _showEditProfile(SessionUser user) async {
    _nameController.text = user.fullName;
    _phoneController.text = user.phone ?? '';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
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
        scrollable: true,
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

  Future<void> _showDeleteAccount() async {
    if (_isDeletingAccount || ref.read(authControllerProvider).isLoading) {
      return;
    }
    _deleteAccountPasswordController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Hapus Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Akun dan data pribadi akan dihapus atau dianonimkan permanen. Catatan akademik tanpa identitas dapat dipertahankan untuk integritas riwayat sekolah. Tindakan ini tidak dapat dibatalkan. Masukkan password saat ini untuk mengonfirmasi.',
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              controller: _deleteAccountPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password saat ini'),
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
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
    if (confirmed != true || _isDeletingAccount) return;
    final password = _deleteAccountPasswordController.text;
    if (password.isEmpty) {
      _snack('Password saat ini wajib diisi.');
      return;
    }
    setState(() => _isDeletingAccount = true);
    await ref
        .read(authControllerProvider.notifier)
        .deleteAccount(currentPassword: password);
    if (mounted) setState(() => _isDeletingAccount = false);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.previewPath,
    required this.progress,
    required this.isBusy,
    required this.onPick,
    required this.onDelete,
  });

  final SessionUser? user;
  final String? previewPath;
  final double? progress;
  final bool isBusy;
  final VoidCallback? onPick;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final avatar = previewPath == null
        ? _NetworkAvatar(user: user)
        : CircleAvatar(
            radius: 36,
            backgroundImage: FileImage(File(previewPath!)),
          );

    return StudentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  avatar,
                  if (progress != null)
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(value: progress),
                    ),
                ],
              ),
              const SizedBox(width: EmiSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? '-',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: StudentStyle.ink),
                    ),
                    Text(
                      user?.email ?? '-',
                      style: const TextStyle(color: StudentStyle.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: EmiSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onPick,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pilih Avatar'),
                ),
              ),
              const SizedBox(width: EmiSpacing.sm),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkAvatar extends StatelessWidget {
  const _NetworkAvatar({required this.user});

  final SessionUser? user;

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      (user?.fullName.isNotEmpty ?? false)
          ? user!.fullName.characters.first
          : '?',
      style: const TextStyle(
        color: EmiColors.primary,
        fontWeight: FontWeight.w800,
        fontSize: 24,
      ),
    );
    final avatarUrl = user?.avatarUrl?.trim();

    return CircleAvatar(
      radius: 36,
      backgroundColor: StudentStyle.tint,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? fallback
          : ClipOval(
              child: Image.network(
                avatarUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(child: fallback),
              ),
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
          Text(
            label,
            style: const TextStyle(
              color: StudentStyle.inkMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(value, style: const TextStyle(color: StudentStyle.ink)),
        ],
      ),
    );
  }
}
