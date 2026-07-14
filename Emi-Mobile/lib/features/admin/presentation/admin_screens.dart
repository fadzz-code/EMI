import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_providers.dart';
import '../data/admin_repository.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final summary = ref.watch(adminDashboardProvider);
    return AdminShell(
      title: 'Beranda Admin',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(adminDashboardProvider.future),
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => FriendlyState(
            icon: Icons.wifi_off_outlined,
            title: 'Data belum bisa dimuat',
            message: 'Periksa koneksi internetmu, lalu coba lagi.',
            onRetry: () => ref.invalidate(adminDashboardProvider),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              RoleHeroHeader(
                greeting: 'Selamat datang,',
                name: user?.fullName ?? 'Admin EMI',
                message: 'Mari periksa kegiatan EMI hari ini.',
                icon: Icons.admin_panel_settings_outlined,
                action: IconButton(
                  tooltip: 'Profil',
                  onPressed: () => context.go('/admin/profile'),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ),
              const SizedBox(height: EmiSpacing.xl),
              if (data.items.isEmpty)
                const FriendlyState(
                  icon: Icons.inbox_outlined,
                  title: 'Belum Ada Data',
                  message:
                      'Ringkasan akan muncul setelah data sekolah tersedia.',
                )
              else ...[
                Text(
                  'Ringkasan Utama',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: EmiSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: EmiSpacing.md,
                  mainAxisSpacing: EmiSpacing.md,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisExtent: 150,
                  children: [
                    for (final item in data.items)
                      SimpleStatItem(
                        label: item.label,
                        value: item.value,
                        icon: _metricIcon(item),
                        highlight: item.highlight,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: EmiSpacing.xl),
              Text(
                'Menu Cepat',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: EmiSpacing.md),
              Wrap(
                spacing: EmiSpacing.sm,
                runSpacing: EmiSpacing.sm,
                children: [
                  for (final feature in AdminFeature.values.where(
                    (feature) => feature.isMobileImplemented,
                  ))
                    QuickActionItem(
                      label: feature.label,
                      icon: _featureIcon(feature),
                      onTap: () => context.go(feature.route),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _metricIcon(AdminMetric metric) => switch (metric.iconName) {
    'approval' => Icons.how_to_reg_outlined,
    'school' => Icons.apartment_outlined,
    'class' => Icons.school_outlined,
    'users' => Icons.people_outline,
    _ => Icons.insights_outlined,
  };

  IconData _featureIcon(AdminFeature feature) => switch (feature) {
    AdminFeature.approvals => Icons.how_to_reg_outlined,
    AdminFeature.dictionary => Icons.translate_outlined,
    AdminFeature.quizzes => Icons.quiz_outlined,
    AdminFeature.reports => Icons.bar_chart_outlined,
    AdminFeature.settings => Icons.settings_outlined,
    _ => Icons.apps_outlined,
  };
}

class AdminListScreen extends ConsumerWidget {
  const AdminListScreen({super.key, required this.feature});

  final AdminFeature feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = AdminFeatureQuery(feature: feature);
    final page = ref.watch(adminListProvider(query));
    return AdminShell(
      title: feature.label,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(adminListProvider(query).future),
        child: page.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => FriendlyState(
            icon: Icons.wifi_off_outlined,
            title: 'Data belum bisa dimuat',
            message: 'Periksa koneksi internetmu, lalu coba lagi.',
            onRetry: () => ref.invalidate(adminListProvider(query)),
          ),
          data: (data) => data.items.isEmpty
              ? const FriendlyState(
                  icon: Icons.inbox_outlined,
                  title: 'Belum Ada Data',
                  message: 'Data akan muncul setelah kegiatan EMI dimulai.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(EmiSpacing.md),
                  itemCount: data.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: EmiSpacing.md),
                  itemBuilder: (context, index) {
                    final item = data.items[index];
                    return EmiCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title),
                        subtitle: item.subtitle == null
                            ? null
                            : Text(_simpleLabel(item.subtitle!)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('${feature.route}/${item.id}'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class AdminDetailScreen extends ConsumerWidget {
  const AdminDetailScreen({super.key, required this.feature, required this.id});

  final AdminFeature feature;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(
      adminDetailProvider(AdminDetailQuery(feature: feature, id: id)),
    );
    return AdminShell(
      title: feature.label,
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Data belum bisa dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: () => ref.invalidate(
            adminDetailProvider(AdminDetailQuery(feature: feature, id: id)),
          ),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            EmiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (item.subtitle != null) Text(_simpleLabel(item.subtitle!)),
                  if (item.status != null) Text(_simpleLabel(item.status!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _simpleLabel(String value) => switch (value) {
  'teacher' => 'Guru',
  'student' => 'Siswa',
  'admin' => 'Admin',
  'active' => 'Aktif',
  'inactive' => 'Tidak Aktif',
  _ => value,
};
