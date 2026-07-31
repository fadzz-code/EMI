import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/emi_theme.dart';
import '../../features/auth/domain/session_user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import 'student_style.dart';

class EmiScaffold extends ConsumerWidget {
  const EmiScaffold({
    super.key,
    required this.child,
    this.title,
    this.currentIndex,
    this.onNavTap,
  });

  final Widget child;
  final String? title;
  final int? currentIndex;
  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: StudentStyle.pageBackground,
      drawer: _StudentDrawer(user: user, location: location),
      body: SafeArea(
        child: Column(
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  EmiSpacing.md,
                  EmiSpacing.md,
                  EmiSpacing.md,
                  EmiSpacing.xs,
                ),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: EmiSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: StudentStyle.surface,
                    borderRadius: BorderRadius.circular(
                      StudentStyle.cardRadius,
                    ),
                    boxShadow: StudentStyle.softShadow(),
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          key: const Key('studentMenuButton'),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu, color: StudentStyle.ink),
                          tooltip: 'Buka menu',
                        ),
                      ),
                      const SizedBox(width: EmiSpacing.xs),
                      Expanded(
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: StudentStyle.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: child),
            if (currentIndex != null && onNavTap != null)
              _EmiBottomNav(index: currentIndex!, onTap: onNavTap!),
          ],
        ),
      ),
    );
  }
}

class _StudentDrawer extends StatelessWidget {
  const _StudentDrawer({required this.user, required this.location});

  final SessionUser? user;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: StudentStyle.pageBackground,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: EmiSpacing.sm,
            vertical: EmiSpacing.md,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(EmiSpacing.md),
              decoration: BoxDecoration(
                color: StudentStyle.surface,
                borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
                boxShadow: StudentStyle.softShadow(),
              ),
              child: Row(
                children: [
                  _DrawerAvatar(user: user),
                  const SizedBox(width: EmiSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Siswa EMI',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: StudentStyle.ink),
                        ),
                        Text(
                          'Ruang Siswa',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: EmiColors.primary),
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: StudentStyle.inkMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EmiSpacing.md),
            _DrawerItem(
              label: 'Beranda',
              icon: Icons.home_outlined,
              route: '/student/dashboard',
              selected: location == '/student/dashboard',
            ),
            _DrawerItem(
              label: 'Modul',
              icon: Icons.menu_book_outlined,
              route: '/student/modules',
              selected:
                  location.startsWith('/student/modules') ||
                  location.startsWith('/student/lessons'),
            ),
            _DrawerItem(
              label: 'Kamus',
              icon: Icons.translate_outlined,
              route: '/student/dictionary',
              selected: location.startsWith('/student/dictionary'),
            ),
            _DrawerItem(
              label: 'Kuis',
              icon: Icons.quiz_outlined,
              route: '/student/quizzes',
              selected: location.startsWith('/student/quizzes'),
            ),
            _DrawerItem(
              label: 'Progress Belajar',
              icon: Icons.trending_up_outlined,
              route: '/student/progress',
              selected: location == '/student/progress',
            ),
            _DrawerItem(
              label: 'Chatbot',
              icon: Icons.auto_awesome_outlined,
              route: '/student/chatbot',
              selected: location == '/student/chatbot',
            ),
            _DrawerItem(
              label: 'Budaya Mekongga',
              icon: Icons.public_outlined,
              route: '/student/culture',
              selected: location.startsWith('/student/culture'),
            ),
            _DrawerItem(
              label: 'Speaking',
              icon: Icons.mic_none_outlined,
              route: '/student/speaking',
              selected: location.startsWith('/student/speaking'),
            ),
            _DrawerItem(
              label: 'Profil',
              icon: Icons.person_outline,
              route: '/student/profile',
              selected: location.startsWith('/student/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerAvatar extends StatelessWidget {
  const _DrawerAvatar({required this.user});

  final SessionUser? user;

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      (user?.fullName.isNotEmpty ?? false)
          ? user!.fullName.characters.first
          : '?',
      style: const TextStyle(
        color: EmiColors.primary,
        fontWeight: FontWeight.w800,
      ),
    );
    final avatarUrl = user?.avatarUrl?.trim();

    return CircleAvatar(
      radius: 28,
      backgroundColor: StudentStyle.tint,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? fallback
          : ClipOval(
              child: Image.network(
                avatarUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(child: fallback),
              ),
            ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(EmiRadii.pill),
          onTap: () {
            Navigator.of(context).pop();
            if (!selected) context.go(route);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EmiSpacing.md,
              vertical: EmiSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected ? EmiColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(EmiRadii.pill),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? EmiColors.primary : StudentStyle.inkMuted,
                ),
                const SizedBox(width: EmiSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? EmiColors.primary : StudentStyle.ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmiBottomNav extends StatelessWidget {
  const _EmiBottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const labels = ['Beranda', 'Modul', 'Kamus', 'Kuis', 'Profil'];
    const icons = [
      Icons.home_outlined,
      Icons.menu_book_outlined,
      Icons.translate_outlined,
      Icons.quiz_outlined,
      Icons.person_outline,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EmiSpacing.md,
        EmiSpacing.xs,
        EmiSpacing.md,
        EmiSpacing.sm,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: StudentStyle.surface,
          borderRadius: BorderRadius.circular(EmiRadii.pill),
          boxShadow: StudentStyle.softShadow(opacity: 0.08),
        ),
        child: Row(
          children: List.generate(labels.length, (item) {
            final active = item == index;
            final color = active ? EmiColors.primary : StudentStyle.inkMuted;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(EmiRadii.pill),
                onTap: () => onTap(item),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: EmiSpacing.md,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? EmiColors.primarySoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(EmiRadii.pill),
                      ),
                      child: Icon(icons[item], size: 22, color: color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labels[item],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
