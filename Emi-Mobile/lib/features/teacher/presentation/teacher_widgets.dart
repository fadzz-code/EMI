import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';
import 'teacher_style.dart';

/// Compact page header used at the top of Teacher list/detail screens:
/// icon badge + title + one-line subtitle. Soft-shadow card, no border —
/// a fresh, calmer alternative to the bold-bordered headers used
/// elsewhere in the app.
class TeacherPageHeader extends StatelessWidget {
  const TeacherPageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: TeacherStyle.surface,
        borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
        boxShadow: TeacherStyle.softShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: TeacherStyle.tint,
              borderRadius: BorderRadius.circular(EmiRadii.pill),
            ),
            child: Icon(icon, color: EmiColors.primary, size: 22),
          ),
          const SizedBox(width: EmiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: TeacherStyle.ink),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TeacherStyle.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Section label used to break long forms/detail screens into readable
/// groups. No divider line — just spacing and a small tinted icon chip,
/// so groups feel like soft breathing room rather than ruled-off blocks.
class TeacherSectionHeader extends StatelessWidget {
  const TeacherSectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.icon,
    this.leading = true,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: leading ? EmiSpacing.lg : 0,
        bottom: EmiSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: TeacherStyle.tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: EmiColors.primary),
                ),
                const SizedBox(width: EmiSpacing.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: TeacherStyle.ink),
                ),
              ),
              ?trailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: TeacherStyle.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-width search field with a soft, borderless look — pill-shaped
/// tinted background instead of an outlined box.
class TeacherSearchField extends StatelessWidget {
  const TeacherSearchField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.label,
    this.onSubmitted,
    this.onChanged,
    this.onClear,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TeacherStyle.tint,
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: TextField(
        key: fieldKey,
        controller: controller,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: TeacherStyle.ink),
        decoration: InputDecoration(
          labelText: label,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: EmiSpacing.md,
            vertical: EmiSpacing.sm,
          ),
          prefixIcon: const Icon(Icons.search, color: TeacherStyle.inkMuted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, color: TeacherStyle.inkMuted),
                ),
        ),
        onSubmitted: onSubmitted,
        onChanged: onChanged,
      ),
    );
  }
}

/// Segmented navigation used to switch between sections within one screen
/// (e.g. class detail tabs). Underline-indicator style instead of a
/// bordered pill strip — the active tab gets an orange underline and bold
/// text, inactive tabs stay muted.
class TeacherSegmentedTabs extends StatelessWidget {
  const TeacherSegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TeacherStyle.tint,
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < labels.length; index++)
              InkWell(
                borderRadius: BorderRadius.circular(EmiRadii.pill),
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: EmiSpacing.md,
                    vertical: EmiSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: selected == index
                        ? TeacherStyle.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(EmiRadii.pill),
                    boxShadow: selected == index
                        ? TeacherStyle.softShadow(opacity: 0.08)
                        : null,
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontWeight: selected == index
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected == index
                          ? EmiColors.primary
                          : TeacherStyle.inkMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tinted stat chip used for compact metric summaries — a soft rounded
/// tag rather than a bordered box.
class TeacherStatChip extends StatelessWidget {
  const TeacherStatChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.md,
        vertical: EmiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TeacherStyle.tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: EmiColors.primary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: TeacherStyle.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Pagination control shown below a list: `< Halaman X dari Y >`, styled
/// as a floating soft pill. Behavior/text stay identical to what tests
/// expect (same "Halaman X dari Y" label); only the visual chrome changes.
class TeacherPaginationBar extends StatelessWidget {
  const TeacherPaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.onPrevious,
    required this.onNext,
    this.previousKey,
    this.nextKey,
  });

  final int currentPage;
  final int lastPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Key? previousKey;
  final Key? nextKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: TeacherStyle.surface,
          borderRadius: BorderRadius.circular(EmiRadii.pill),
          boxShadow: TeacherStyle.softShadow(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: previousKey,
              tooltip: 'Halaman sebelumnya',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left, color: TeacherStyle.ink),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.xs),
              child: Text(
                'Halaman $currentPage dari $lastPage',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: TeacherStyle.ink),
              ),
            ),
            IconButton(
              key: nextKey,
              tooltip: 'Halaman berikutnya',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right, color: TeacherStyle.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status badge/chip: filled color pill with no border, text color chosen
/// for contrast against the fill.
class TeacherStatusChip extends StatelessWidget {
  const TeacherStatusChip({
    super.key,
    required this.label,
    this.color = TeacherStyle.tintStrong,
    this.textColor,
  });

  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor ?? TeacherStyle.ink,
        ),
      ),
    );
  }
}

/// Soft-shadow list-item container: the main surface unit for Teacher
/// screens. No border anywhere — depth comes entirely from a gentle drop
/// shadow, keeping the whole role visually calmer than Admin.
class TeacherListCard extends StatelessWidget {
  const TeacherListCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(EmiSpacing.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TeacherStyle.surface,
        borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
        boxShadow: TeacherStyle.softShadow(),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
