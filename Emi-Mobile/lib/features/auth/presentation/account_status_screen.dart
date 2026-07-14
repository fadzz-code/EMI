import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

class AccountStatusScreen extends ConsumerWidget {
  const AccountStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final copy = _copyFor(auth.status, auth.error?.message);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(EmiSpacing.lg),
            child: EmiCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(copy.icon, size: 48, color: EmiColors.primary),
                  const SizedBox(height: EmiSpacing.md),
                  Text(
                    copy.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: EmiSpacing.sm),
                  Text(copy.message),
                  const SizedBox(height: EmiSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => ref
                                .read(authControllerProvider.notifier)
                                .logout(),
                      child: const Text('Kembali ke Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

({String title, String message, IconData icon}) _copyFor(
  AuthStatus status,
  String? errorMessage,
) {
  return switch (status) {
    AuthStatus.pendingApproval => (
      title: 'Akun Sedang Menunggu Persetujuan',
      message:
          'Admin akan memeriksa data sekolah dan kelas kamu terlebih dahulu. Kamu dapat masuk setelah akun disetujui.',
      icon: Icons.hourglass_top_outlined,
    ),
    AuthStatus.registrationRejected => (
      title: 'Registrasi Ditolak',
      message: errorMessage ?? 'Registrasi akun ditolak. Hubungi Admin EMI.',
      icon: Icons.block_outlined,
    ),
    AuthStatus.accountDisabled => (
      title: 'Akun Dinonaktifkan',
      message: errorMessage ?? 'Akun dinonaktifkan. Hubungi Admin EMI.',
      icon: Icons.lock_outline,
    ),
    AuthStatus.forbidden => (
      title: 'Akses Ditolak',
      message:
          errorMessage ?? 'Akun tidak memiliki izin untuk membuka halaman ini.',
      icon: Icons.gpp_bad_outlined,
    ),
    _ => (
      title: 'Status Akun',
      message: errorMessage ?? 'Silakan kembali ke halaman login.',
      icon: Icons.info_outline,
    ),
  };
}
