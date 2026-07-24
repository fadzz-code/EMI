import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../shared/widgets/emi_card.dart';
import '../theme/emi_theme.dart';

class UnsupportedRoleScreen extends ConsumerWidget {
  const UnsupportedRoleScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final role = auth.user?.role.value ?? 'tidak dikenal';
    final title =
        message ??
        (auth.status == AuthStatus.unsupportedRole
            ? 'Role $role belum tersedia di mobile.'
            : 'Halaman tidak tersedia.');

    return Scaffold(
      backgroundColor: EmiColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(EmiSpacing.lg),
            child: EmiCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: EmiSpacing.md),
                  const Text(
                    'Untuk sementara, role selain siswa menggunakan versi web EMI.',
                  ),
                  const SizedBox(height: EmiSpacing.lg),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    child: const Text('Logout'),
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
