import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';
import 'admin_style.dart';

/// Compact page header used at the top of Admin list/detail screens:
/// icon badge + title + one-line subtitle. Soft-shadow card, no border.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
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
        color: AdminStyle.surface,
        borderRadius: BorderRadius.circular(AdminStyle.cardRadius),
        boxShadow: AdminStyle.softShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AdminStyle.tint,
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
                  ).textTheme.titleLarge?.copyWith(color: AdminStyle.ink),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AdminStyle.inkMuted,
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

/// Section label used to break long screens into readable groups.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader(
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
                    color: AdminStyle.tint,
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
                  ).textTheme.titleMedium?.copyWith(color: AdminStyle.ink),
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
              ).textTheme.bodySmall?.copyWith(color: AdminStyle.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Soft-shadow container: the main surface unit for Admin screens. No border
/// anywhere — depth comes from a gentle drop shadow.
class AdminCard extends StatelessWidget {
  const AdminCard({
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
        color: AdminStyle.surface,
        borderRadius: BorderRadius.circular(AdminStyle.cardRadius),
        boxShadow: AdminStyle.softShadow(),
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AdminStyle.cardRadius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Full-width search field with a soft, borderless pill look.
class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
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
        color: AdminStyle.tint,
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: TextField(
        key: fieldKey,
        controller: controller,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: AdminStyle.ink),
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
          prefixIcon: const Icon(Icons.search, color: AdminStyle.inkMuted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, color: AdminStyle.inkMuted),
                ),
        ),
        onSubmitted: onSubmitted,
        onChanged: onChanged,
      ),
    );
  }
}

/// Status badge/chip: filled color pill with no border, colored by the
/// canonical status string.
class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({
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
            ? AdminStyle.statusFill(status!)
            : AdminStyle.tintStrong);
    final onFill =
        textColor ??
        (status != null ? AdminStyle.statusText(status!) : AdminStyle.ink);
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

/// Compact metric tile used in the dashboard summary grid.
class AdminMetricTile extends StatelessWidget {
  const AdminMetricTile({
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
      padding: const EdgeInsets.all(EmiSpacing.sm),
      decoration: BoxDecoration(
        color: AdminStyle.surface,
        borderRadius: BorderRadius.circular(AdminStyle.cardRadius),
        boxShadow: AdminStyle.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: highlight ? EmiColors.primarySoft : AdminStyle.tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: EmiColors.primary),
          ),
          const SizedBox(height: EmiSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: highlight ? EmiColors.primary : AdminStyle.ink,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AdminStyle.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty/error placeholder: soft tinted icon badge, title and
/// message, with an optional retry action. No dashed borders.
class AdminPlaceholder extends StatelessWidget {
  const AdminPlaceholder({
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
        color: AdminStyle.surface,
        borderRadius: BorderRadius.circular(AdminStyle.cardRadius),
        boxShadow: AdminStyle.softShadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AdminStyle.tint,
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
            ).textTheme.titleMedium?.copyWith(color: AdminStyle.ink),
          ),
          const SizedBox(height: EmiSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AdminStyle.inkMuted),
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
