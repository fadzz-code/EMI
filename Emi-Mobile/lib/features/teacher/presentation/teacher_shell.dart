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
    this.onBack,
  });

  final String title;
  final Widget child;
  final String? fallbackRoute;
  final Future<void> Function()? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final location = GoRouterState.of(context).uri.path;
    return PopScope(
      canPop: onBack == null && (fallbackRoute == null || context.canPop()),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (onBack != null) {
          await onBack!();
        } else if (fallbackRoute != null) {
          context.go(fallbackRoute!);
        }
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
                        onPressed: () async {
                          if (onBack != null) {
                            await onBack!();
                          } else if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(fallbackRoute!);
                          }
                        },
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
                    if (fallbackRoute == null)
                      IconButton(
                        tooltip: 'Profil',
                        onPressed: () => context.go('/teacher/profile'),
                        icon: const Icon(Icons.account_circle_outlined),
                      ),
                  ],
                ),
              ),
              Expanded(child: child),
              if (fallbackRoute == null) _TeacherBottomNav(location: location),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherBottomNav extends StatelessWidget {
  const _TeacherBottomNav({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.dashboard_outlined,
        Icons.dashboard,
        'Beranda',
        '/teacher/dashboard',
      ),
      (Icons.groups_outlined, Icons.groups, 'Kelas', '/teacher/classes'),
      (Icons.menu_book_outlined, Icons.menu_book, 'Modul', '/teacher/modules'),
      (Icons.quiz_outlined, Icons.quiz, 'Kuis', '/teacher/quizzes'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: EmiColors.surface,
        border: Border(top: BorderSide(color: EmiColors.border, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(EmiSpacing.xs, 6, EmiSpacing.xs, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final selected =
              location == item.$4 || location.startsWith('${item.$4}/');
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(EmiRadii.pill),
              onTap: () => context.go(item.$4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.$2 : item.$1,
                      color: selected ? EmiColors.textPrimary : Colors.black54,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$3,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected
                            ? EmiColors.textPrimary
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EmiSpacing.md,
              EmiSpacing.md,
              EmiSpacing.md,
              EmiSpacing.xs,
            ),
            child: Text(
              'Menu EMI',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          _Item(
            label: 'Beranda',
            icon: Icons.dashboard_outlined,
            route: '/teacher/dashboard',
            selected:
                location == '/teacher/dashboard' || location == '/teacher',
          ),
          _Item(
            label: 'Kelas',
            icon: Icons.school_outlined,
            route: '/teacher/classes',
            selected: location.startsWith('/teacher/classes'),
          ),
          _Item(
            label: 'Modul Kelas',
            icon: Icons.menu_book_outlined,
            route: '/teacher/modules',
            selected: location.startsWith('/teacher/modules'),
          ),
          _Item(
            label: 'Kuis Kelas',
            icon: Icons.description_outlined,
            route: '/teacher/quizzes',
            selected: location.startsWith('/teacher/quizzes'),
          ),
          _Item(
            label: 'Budaya Mekongga',
            icon: Icons.public_outlined,
            route: '/teacher/culture',
            selected: location.startsWith('/teacher/culture'),
          ),
          _Item(
            label: 'Speaking',
            icon: Icons.mic_none_outlined,
            route: '/teacher/speaking',
            selected: location.startsWith('/teacher/speaking'),
          ),
          _Item(
            label: 'Progress',
            icon: Icons.trending_up_outlined,
            route: '/teacher/progress',
            selected: location.startsWith('/teacher/progress'),
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
    this.route,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final String? route;
  final bool selected;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    selected: selected,
    selectedTileColor: EmiColors.secondary,
    onTap: () {
      Navigator.of(context).pop();
      if (route != null && !selected) context.go(route!);
    },
  );
}
