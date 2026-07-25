import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../auth/domain/session_user.dart';
import '../../auth/presentation/auth_controller.dart';
import 'teacher_style.dart';

class TeacherShell extends ConsumerWidget {
  const TeacherShell({
    super.key,
    required this.title,
    required this.child,
    this.fallbackRoute,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final String? fallbackRoute;
  final Future<void> Function()? onBack;
  final List<Widget> actions;

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
        backgroundColor: TeacherStyle.pageBackground,
        drawer: _TeacherDrawer(user: user, location: location),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.md),
                decoration: BoxDecoration(
                  color: TeacherStyle.pageBackground,
                  boxShadow: TeacherStyle.softShadow(opacity: 0.04),
                ),
                child: Row(
                  children: [
                    if (fallbackRoute == null)
                      Builder(
                        builder: (context) => IconButton(
                          key: const Key('teacherMenuButton'),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: TeacherStyle.ink,
                          ),
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
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: TeacherStyle.ink,
                        ),
                      ),
                    const SizedBox(width: EmiSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: TeacherStyle.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...actions,
                    if (fallbackRoute == null)
                      IconButton(
                        tooltip: 'Profil',
                        onPressed: () => context.go('/teacher/profile'),
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          color: TeacherStyle.ink,
                        ),
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
        Icons.dashboard_rounded,
        'Beranda',
        '/teacher/dashboard',
      ),
      (
        Icons.groups_outlined,
        Icons.groups_rounded,
        'Kelas',
        '/teacher/classes',
      ),
      (
        Icons.menu_book_outlined,
        Icons.menu_book_rounded,
        'Modul',
        '/teacher/modules',
      ),
      (Icons.quiz_outlined, Icons.quiz_rounded, 'Kuis', '/teacher/quizzes'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(EmiSpacing.sm, 8, EmiSpacing.sm, 8),
      decoration: BoxDecoration(
        color: TeacherStyle.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final selected =
              location == item.$4 || location.startsWith('${item.$4}/');
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(EmiRadii.pill),
              onTap: () => context.go(item.$4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? TeacherStyle.tint : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.$2 : item.$1,
                      color: selected
                          ? EmiColors.primary
                          : TeacherStyle.inkMuted,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$3,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? EmiColors.primary
                            : TeacherStyle.inkMuted,
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
    backgroundColor: TeacherStyle.surface,
    child: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.all(EmiSpacing.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [EmiColors.primary, Color(0xFFFFA968)],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  foregroundColor: EmiColors.primary,
                  child: Text(
                    (user?.fullName.isNotEmpty ?? false)
                        ? user!.fullName.characters.first
                        : 'G',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: EmiSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Guru EMI',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      if (user?.email != null)
                        Text(
                          user!.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      Text(
                        'Guru',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EmiSpacing.md,
              EmiSpacing.md,
              EmiSpacing.md,
              EmiSpacing.xs,
            ),
            child: Text(
              'Menu EMI',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: TeacherStyle.inkMuted),
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: EmiSpacing.xs),
            child: Divider(height: 1, color: TeacherStyle.tint),
          ),
          ListTile(
            key: const Key('teacherLogoutButton'),
            leading: const Icon(
              Icons.logout_rounded,
              color: TeacherStyle.inkMuted,
            ),
            title: const Text(
              'Keluar',
              style: TextStyle(color: TeacherStyle.inkMuted),
            ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.sm, vertical: 2),
    child: Material(
      color: selected ? TeacherStyle.tint : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon,
          color: selected ? EmiColors.primary : TeacherStyle.ink,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? EmiColors.primary : TeacherStyle.ink,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: selected,
        onTap: () {
          Navigator.of(context).pop();
          if (route != null && !selected) context.go(route!);
        },
      ),
    ),
  );
}
