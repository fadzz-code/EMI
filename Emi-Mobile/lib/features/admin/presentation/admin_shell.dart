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
    this.onBack,
  });

  final String title;
  final Widget child;
  final String? fallbackRoute;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final location = GoRouterState.of(context).uri.path;

    final showQuickNavigation =
        fallbackRoute == null && MediaQuery.viewInsetsOf(context).bottom == 0;
    final segments = location
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    final domain = segments.length > 1 ? segments[1] : 'dashboard';

    return PopScope(
      canPop: fallbackRoute == null || context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && fallbackRoute != null && context.mounted) {
          context.go(fallbackRoute!);
        }
      },
      child: Scaffold(
        key: Key('adminScreen-$domain'),
        drawer: _AdminDrawer(user: user, location: location),
        bottomNavigationBar: showQuickNavigation
            ? SafeArea(
                top: false,
                child: AdminQuickNavigation(location: location),
              )
            : null,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.md),
                decoration: const BoxDecoration(
                  color: EmiColors.background,
                  border: Border(
                    bottom: BorderSide(color: EmiColors.border, width: 1.5),
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
                        onPressed:
                            onBack ?? () => _back(context, fallbackRoute!),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    const SizedBox(width: EmiSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        key: Key('adminTitle-$domain'),
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
              icon: Icons.home_outlined,
              route: '/admin/dashboard',
              selected: location == '/admin/dashboard',
            ),
            _Item(
              label: 'Persetujuan',
              icon: Icons.how_to_reg_outlined,
              route: AdminFeature.approvals.route,
              selected: location.startsWith(AdminFeature.approvals.route),
            ),
            _Group(
              label: 'Sekolah & Kelas',
              icon: Icons.school_outlined,
              selected:
                  location.startsWith('/admin/schools') ||
                  location.startsWith('/admin/classes'),
              children: [
                _ItemData(
                  'Sekolah',
                  Icons.apartment_outlined,
                  '/admin/schools',
                  location.startsWith('/admin/schools'),
                ),
                _ItemData(
                  'Kelas & Penempatan',
                  Icons.school_outlined,
                  '/admin/classes',
                  location.startsWith('/admin/classes'),
                ),
              ],
            ),
            _Item(
              label: 'Guru & Siswa',
              icon: Icons.groups_outlined,
              route: AdminFeature.users.route,
              selected: location.startsWith(AdminFeature.users.route),
            ),
            for (final feature in [
              AdminFeature.dictionary,
              AdminFeature.knowledge,
              AdminFeature.modules,
              AdminFeature.quizzes,
              AdminFeature.speaking,
              AdminFeature.culture,
              AdminFeature.reports,
              AdminFeature.settings,
            ])
              _Item(
                label: feature.label,
                icon: _icon(feature),
                route: feature.route,
                selected: location.startsWith(feature.route),
              ),
            _Item(
              label: 'Profil',
              icon: Icons.person_outline,
              route: '/admin/profile',
              selected: location.startsWith('/admin/profile'),
            ),
            const Divider(height: 1),
            ListTile(
              key: const Key('adminLogoutButton'),
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
    AdminFeature.knowledge => Icons.psychology_alt_outlined,
    AdminFeature.quizzes => Icons.quiz_outlined,
    AdminFeature.culture => Icons.public_outlined,
    AdminFeature.speaking => Icons.mic_none_outlined,
    AdminFeature.reports => Icons.bar_chart_outlined,
    AdminFeature.settings => Icons.settings_outlined,
  };
}

class AdminQuickNavigation extends StatelessWidget {
  const AdminQuickNavigation({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Beranda',
        Icons.home_outlined,
        '/admin/dashboard',
        location == '/admin/dashboard',
        'adminQuickHome',
      ),
      (
        'Persetujuan',
        Icons.how_to_reg_outlined,
        '/admin/approvals',
        location.startsWith('/admin/approvals'),
        'adminQuickApprovals',
      ),
      (
        'Progress',
        Icons.bar_chart_outlined,
        '/admin/reports',
        location.startsWith('/admin/reports'),
        'adminQuickProgress',
      ),
      (
        'Pengaturan',
        Icons.settings_outlined,
        '/admin/settings',
        location.startsWith('/admin/settings'),
        'adminQuickSettings',
      ),
    ];
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: InkWell(
                key: Key(item.$5),
                onTap: item.$4 ? null : () => context.go(item.$3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$2, size: 22),
                    const SizedBox(height: 2),
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.icon,
    required this.selected,
    required this.children,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final List<_ItemData> children;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: Icon(icon),
    title: Text(label),
    initiallyExpanded: selected,
    children: [
      for (final child in children)
        _Item(
          label: child.label,
          icon: child.icon,
          route: child.route,
          selected: child.selected,
          indented: true,
        ),
    ],
  );
}

class _ItemData {
  const _ItemData(this.label, this.icon, this.route, this.selected);

  final String label;
  final IconData icon;
  final String route;
  final bool selected;
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
    this.indented = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool selected;
  final bool indented;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.only(
          left: indented ? EmiSpacing.lg : EmiSpacing.md,
          right: EmiSpacing.md,
        ),
        leading: Icon(icon, size: 22),
        title: Text(label),
        selected: selected,
        selectedTileColor: EmiColors.secondary,
        onTap: () {
          Navigator.of(context).pop();
          if (!selected) context.go(route);
        },
      ),
    );
  }
}
