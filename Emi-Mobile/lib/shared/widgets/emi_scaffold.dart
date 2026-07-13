import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';

class EmiScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (title != null)
              Container(
                height: 64,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.md),
                decoration: const BoxDecoration(
                  color: EmiColors.background,
                  border: Border(
                    bottom: BorderSide(color: EmiColors.border, width: 2),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge,
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
      height: 80,
      decoration: const BoxDecoration(
        color: EmiColors.surface,
        border: Border(top: BorderSide(color: EmiColors.border, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(labels.length, (item) {
          final active = item == index;
          return InkWell(
            borderRadius: BorderRadius.circular(EmiRadii.pill),
            onTap: () => onTap(item),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: active ? EmiSpacing.md : EmiSpacing.xs,
                vertical: active ? 4 : EmiSpacing.xs,
              ),
              decoration: active
                  ? BoxDecoration(
                      color: EmiColors.success,
                      border: Border.all(color: EmiColors.border, width: 2),
                      borderRadius: BorderRadius.circular(EmiRadii.pill),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icons[item], size: 20),
                  const SizedBox(height: 4),
                  Text(
                    labels[item],
                    style: Theme.of(context).textTheme.labelSmall,
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
