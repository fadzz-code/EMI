import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/emi_theme.dart';
import '../../features/auth/domain/session_user.dart';
import '../../features/auth/presentation/auth_controller.dart';

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
      backgroundColor: EmiColors.background,
      drawer: _StudentDrawer(user: user, location: location),
      body: SafeArea(
        child: Column(
          children: [
            if (title != null)
              Container(
                constraints: const BoxConstraints(minHeight: 64),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.md),
                decoration: const BoxDecoration(
                  color: EmiColors.surface,
                  border: Border(
                    bottom: BorderSide(color: EmiColors.border, width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        key: const Key('studentMenuButton'),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu),
                        tooltip: 'Buka menu',
                      ),
                    ),
                    const SizedBox(width: EmiSpacing.sm),
                    Expanded(
                      child: Text(
                        title!,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
      backgroundColor: EmiColors.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(EmiSpacing.md),
              color: EmiColors.surfaceSoft,
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: EmiColors.border),
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
    );
    final avatarUrl = user?.avatarUrl?.trim();

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: EmiColors.border, width: 1.5),
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: EmiColors.secondary,
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
    return ListTile(
      minVerticalPadding: EmiSpacing.sm,
      leading: Icon(
        icon,
        size: 22,
        color: selected ? EmiColors.primary : EmiColors.textPrimary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? EmiColors.primary : EmiColors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: EmiColors.primarySoft,
      onTap: () {
        Navigator.of(context).pop();
        if (!selected) context.go(route);
      },
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

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: EmiColors.surface,
        border: Border(top: BorderSide(color: EmiColors.border, width: 1.5)),
      ),
      child: Row(
        children: List.generate(labels.length, (item) {
          final active = item == index;
          final color = active ? EmiColors.primary : Colors.black54;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(item),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icons[item], size: 22, color: color),
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
    );
  }
}
