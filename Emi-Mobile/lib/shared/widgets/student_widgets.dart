import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';
import 'student_style.dart';

/// Compact page header used at the top of Student list/detail screens:
/// icon badge + title + one-line subtitle. Soft-shadow card, no border.
class StudentPageHeader extends StatelessWidget {
  const StudentPageHeader({
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
        color: StudentStyle.surface,
        borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
        boxShadow: StudentStyle.softShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: StudentStyle.tint,
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
                  ).textTheme.titleLarge?.copyWith(color: StudentStyle.ink),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: StudentStyle.inkMuted,
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

/// Welcoming hero/greeting surface for the student home: a warm orange
/// gradient card with a soft glow, a rounded icon badge, greeting text and
/// one primary call-to-action.
class StudentHeroCard extends StatelessWidget {
  const StudentHeroCard({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
    this.icon = Icons.school_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String greeting;
  final String name;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [StudentStyle.heroTintStart, StudentStyle.heroTintEnd],
        ),
        borderRadius: BorderRadius.circular(StudentStyle.heroRadius),
        boxShadow: StudentStyle.heroShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(EmiRadii.pill),
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: EmiSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: EmiSpacing.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: EmiSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: EmiColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: EmiSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      StudentStyle.buttonRadius,
                    ),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section label used to break long screens into readable groups.
class StudentSectionHeader extends StatelessWidget {
  const StudentSectionHeader(
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
                    color: StudentStyle.tint,
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
                  ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
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
              ).textTheme.bodySmall?.copyWith(color: StudentStyle.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-width search field with a soft, borderless pill look.
class StudentSearchField extends StatelessWidget {
  const StudentSearchField({
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
        color: StudentStyle.tint,
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: TextField(
        key: fieldKey,
        controller: controller,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: StudentStyle.ink),
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
          prefixIcon: const Icon(Icons.search, color: StudentStyle.inkMuted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, color: StudentStyle.inkMuted),
                ),
        ),
        onSubmitted: onSubmitted,
        onChanged: onChanged,
      ),
    );
  }
}

/// Soft-shadow container: the main surface unit for Student screens. No
/// border anywhere — depth comes from a gentle drop shadow.
class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(EmiSpacing.md),
    this.clip = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StudentStyle.surface,
        borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
        boxShadow: StudentStyle.softShadow(),
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Compact 2-line metric tile used in the dashboard summary grid.
class StudentMetricTile extends StatelessWidget {
  const StudentMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: StudentStyle.surface,
        borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
        boxShadow: StudentStyle.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: highlight ? EmiColors.primarySoft : StudentStyle.tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: EmiColors.primary),
          ),
          const SizedBox(height: EmiSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: highlight ? EmiColors.primary : StudentStyle.ink,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: StudentStyle.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Tinted stat pill for compact inline metric summaries.
class StudentStatChip extends StatelessWidget {
  const StudentStatChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.md,
        vertical: EmiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: StudentStyle.tint,
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
            ).textTheme.labelSmall?.copyWith(color: StudentStyle.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Status badge/chip: filled color pill with no border, colored by the
/// canonical status string.
class StudentStatusChip extends StatelessWidget {
  const StudentStatusChip({
    super.key,
    required this.label,
    this.status,
    this.color,
    this.textColor,
  });

  final String label;
  final String? status;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final fill =
        color ??
        (status != null
            ? StudentStyle.statusFill(status!)
            : StudentStyle.tintStrong);
    final onFill =
        textColor ??
        (status != null ? StudentStyle.statusText(status!) : StudentStyle.ink);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: onFill,
        ),
      ),
    );
  }
}

/// A soft, rounded progress bar with an optional caption.
class StudentProgressBar extends StatelessWidget {
  const StudentProgressBar({super.key, required this.value, this.caption});

  final double value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(EmiRadii.pill),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: StudentStyle.tintStrong,
            valueColor: const AlwaysStoppedAnimation(EmiColors.primary),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: EmiSpacing.xs),
          Text(
            caption!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: StudentStyle.inkMuted),
          ),
        ],
      ],
    );
  }
}

/// Pagination control shown below a list: `< Halaman X dari Y >`, styled as
/// a floating soft pill.
class StudentPaginationBar extends StatelessWidget {
  const StudentPaginationBar({
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
          color: StudentStyle.surface,
          borderRadius: BorderRadius.circular(EmiRadii.pill),
          boxShadow: StudentStyle.softShadow(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: previousKey,
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left, color: StudentStyle.ink),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.xs),
              child: Text(
                'Halaman $currentPage dari $lastPage',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: StudentStyle.ink),
              ),
            ),
            IconButton(
              key: nextKey,
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right, color: StudentStyle.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Friendly empty/error placeholder: soft tinted icon badge, title and
/// message, with an optional retry action. No dashed borders.
class StudentPlaceholder extends StatelessWidget {
  const StudentPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Coba Lagi',
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EmiSpacing.lg),
      decoration: BoxDecoration(
        color: StudentStyle.surface,
        borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
        boxShadow: StudentStyle.softShadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: StudentStyle.tint,
              borderRadius: BorderRadius.circular(EmiRadii.pill),
            ),
            child: Icon(icon, size: 32, color: EmiColors.primary),
          ),
          const SizedBox(height: EmiSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
          ),
          const SizedBox(height: EmiSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: StudentStyle.inkMuted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: EmiSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}
