import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../auth/domain/session_user.dart';
import '../../auth/presentation/auth_controller.dart';

class TeacherShell extends ConsumerWidget {
  const TeacherShell({
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
    return PopScope(
      canPop: fallbackRoute == null || context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && fallbackRoute != null) context.go(fallbackRoute!);
      },
      child: Scaffold(
        drawer: _TeacherDrawer(user: user, location: location),
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
                          key: const Key('teacherMenuButton'),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu),
                        ),
                      )
                    else
                      IconButton(
                        key: const Key('teacherBackButton'),
                        tooltip: 'Kembali',
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(fallbackRoute!),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    const SizedBox(width: EmiSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
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
}

class _TeacherDrawer extends ConsumerWidget {
  const _TeacherDrawer({required this.user, required this.location});

  final SessionUser? user;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
    child: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    (user?.fullName.isNotEmpty ?? false)
                        ? user!.fullName.characters.first
                        : 'G',
                  ),
                ),
                const SizedBox(height: EmiSpacing.sm),
                Text(
                  user?.fullName ?? 'Guru EMI',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (user?.email != null) Text(user!.email),
                const Text('Guru'),
              ],
            ),
          ),
          const Divider(height: 1),
          _Item(
            label: 'Beranda',
            icon: Icons.dashboard_outlined,
            route: '/teacher/dashboard',
            selected:
                location == '/teacher/dashboard' || location == '/teacher',
          ),
          _Item(
            label: 'Kelas',
            icon: Icons.groups_outlined,
            route: '/teacher/classes',
            selected: location.startsWith('/teacher/classes'),
          ),
          _Item(
            label: 'Modul Kelas',
            icon: Icons.menu_book_outlined,
            route: '/teacher/modules',
            selected: location.startsWith('/teacher/modules'),
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
  Widget build(BuildContext context) => ListTile(
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
