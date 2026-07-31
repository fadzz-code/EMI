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
      child: Theme(
        data: TeacherStyle.theme(context),
        child: Scaffold(
          backgroundColor: TeacherStyle.pageBackground,
          drawer: _TeacherDrawer(user: user, location: location),
          appBar: AppBar(
            backgroundColor: TeacherStyle.pageBackground,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            leadingWidth: 64,
            leading: fallbackRoute == null
                ? Builder(
                    builder: (context) => IconButton(
                      key: const Key('teacherMenuButton'),
                      tooltip: 'Menu',
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                    ),
                  )
                : IconButton(
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
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
            title: Text(title, overflow: TextOverflow.ellipsis),
            actions: [
              ...actions,
              if (fallbackRoute == null)
                IconButton(
                  tooltip: 'Profil',
                  onPressed: () => context.go('/teacher/profile'),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(top: false, child: child),
          bottomNavigationBar: fallbackRoute == null
              ? _TeacherBottomNav(location: location)
              : null,
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
    final selectedIndex = items.indexWhere(
      (item) => location == item.$4 || location.startsWith('${item.$4}/'),
    );
    return NavigationBar(
      height: 72,
      backgroundColor: TeacherStyle.surface,
      indicatorColor: TeacherStyle.tintStrong,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) => context.go(items[index].$4),
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.$1),
            selectedIcon: Icon(item.$2, color: EmiColors.primary),
            label: item.$3,
          ),
      ],
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
            label: 'Kamus',
            icon: Icons.menu_book_outlined,
            route: '/teacher/dictionary',
            selected: location.startsWith('/teacher/dictionary'),
          ),
          _Item(
            label: 'Chatbot AI',
            icon: Icons.auto_awesome_outlined,
            route: '/teacher/chatbot',
            selected: location.startsWith('/teacher/chatbot'),
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
