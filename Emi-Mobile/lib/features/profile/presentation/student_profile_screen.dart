import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../auth/presentation/auth_controller.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return EmiScaffold(
      title: 'Profil',
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          EmiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? '-',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: EmiSpacing.md),
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
          OutlinedButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Logout'),
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
