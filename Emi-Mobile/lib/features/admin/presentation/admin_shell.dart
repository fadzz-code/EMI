import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../auth/domain/session_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_providers.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.child,
    this.fallbackRoute,
  });

  final String title;
  final Widget child;
  final String? fallbackRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      drawer: _AdminDrawer(user: user, location: location),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.md),
              decoration: const BoxDecoration(
                color: EmiColors.background,
                border: Border(
                  bottom: BorderSide(color: EmiColors.border, width: 2),
                ),
              ),
              child: Row(
                children: [
                  if (fallbackRoute == null)
                    Builder(
                      builder: (context) => IconButton(
                        key: const Key('adminMenuButton'),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu),
                      ),
                    )
                  else
                    IconButton(
                      key: const Key('adminBackButton'),
                      tooltip: 'Kembali',
                      onPressed: () => _back(context, fallbackRoute!),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  const SizedBox(width: EmiSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  void _back(BuildContext context, String route) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(route);
    }
  }
}

class _AdminDrawer extends ConsumerWidget {
  const _AdminDrawer({required this.user, required this.location});

  final SessionUser? user;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(EmiSpacing.md),
              child: Row(
                children: [
                  _Avatar(user: user),
                  const SizedBox(width: EmiSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Admin EMI',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (user?.email != null) Text(user!.email),
                        const Text('Admin'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _Item(
              label: 'Beranda',
              icon: Icons.dashboard_outlined,
              route: '/admin/dashboard',
              selected: location == '/admin/dashboard',
            ),
            for (final feature in AdminFeature.values.where(
              (feature) => feature.isMobileImplemented,
            ))
              _Item(
                label: feature.label,
                icon: _icon(feature),
                route: feature.route,
                selected: location.startsWith(feature.route),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Keluar'),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(AdminFeature feature) => switch (feature) {
    AdminFeature.approvals => Icons.how_to_reg_outlined,
    AdminFeature.users => Icons.people_outline,
    AdminFeature.schools => Icons.apartment_outlined,
    AdminFeature.classes => Icons.school_outlined,
    AdminFeature.modules => Icons.menu_book_outlined,
    AdminFeature.dictionary => Icons.translate_outlined,
    AdminFeature.quizzes => Icons.quiz_outlined,
    AdminFeature.culture => Icons.public_outlined,
    AdminFeature.speaking => Icons.mic_none_outlined,
    AdminFeature.reports => Icons.bar_chart_outlined,
    AdminFeature.settings => Icons.settings_outlined,
  };
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final SessionUser? user;

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      (user?.fullName.isNotEmpty ?? false)
          ? user!.fullName.characters.first
          : 'A',
    );
    final url = user?.avatarUrl?.trim();
    return CircleAvatar(
      radius: 28,
      backgroundColor: EmiColors.secondary,
      child: url == null || url.isEmpty
          ? fallback
          : ClipOval(
              child: Image.network(
                url,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(child: fallback),
              ),
            ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.icon,
    required this.route,
    required this.selected,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      selectedTileColor: EmiColors.secondary,
      onTap: () {
        Navigator.of(context).pop();
        if (!selected) context.go(route);
      },
    );
  }
}
