import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/admin_providers.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminDashboardProvider);
    return AdminShell(
      title: 'Dashboard Admin',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(adminDashboardProvider.future),
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(adminDashboardProvider),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              Container(
                padding: const EdgeInsets.all(EmiSpacing.lg),
                decoration: BoxDecoration(
                  color: EmiColors.secondary,
                  border: Border.all(color: EmiColors.border, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [EmiShadows.hard],
                ),
                child: Text(
                  'Pusat Pengelolaan EMI',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: EmiSpacing.lg),
              if (data.items.isEmpty)
                const EmiCard(
                  child: Text('Dashboard belum mengirim ringkasan.'),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: EmiSpacing.md,
                  mainAxisSpacing: EmiSpacing.md,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    for (final item in data.items)
                      EmiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.value,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: EmiSpacing.xs),
                            Text(
                              item.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.helper != null)
                              Text(
                                item.helper!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: EmiSpacing.lg),
              Text('Shortcut', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: EmiSpacing.md),
              Wrap(
                spacing: EmiSpacing.sm,
                runSpacing: EmiSpacing.sm,
                children: [
                  for (final feature in AdminFeature.values.where(
                    (feature) => feature.isMobileImplemented,
                  ))
                    OutlinedButton(
                      onPressed: () => context.go(feature.route),
                      child: Text(feature.label),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(adminListProvider(query)),
          ),
          data: (data) => data.items.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(EmiSpacing.md),
                  children: const [
                    EmiCard(child: Text('Data belum tersedia.')),
                  ],
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
                            : Text(item.subtitle!),
                        trailing: item.status == null
                            ? const Icon(Icons.chevron_right)
                            : Text(item.status!),
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
        error: (error, _) => _ErrorState(
          message: error.toString(),
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
                  if (item.subtitle != null) Text(item.subtitle!),
                  if (item.status != null) Text('Status: ${item.status}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        EmiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: EmiSpacing.sm),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
