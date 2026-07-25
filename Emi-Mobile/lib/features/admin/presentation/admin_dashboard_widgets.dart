import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';
import 'admin_style.dart';

/// Hero header used only by [AdminDashboardScreen]. Same information shape
/// as the shared `RoleHeroHeader` (greeting, name, message, icon, action)
/// but with a bolder dark border + solid offset shadow to match the auth
/// screens' visual language. Kept separate from `role_dashboard_widgets.dart`
/// so Teacher/Student, which also use `RoleHeroHeader`, are unaffected.
class AdminHeroHeader extends StatelessWidget {
  const AdminHeroHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.message,
    required this.icon,
    this.action,
  });

  final String greeting;
  final String name;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.lg),
      decoration: BoxDecoration(
        color: EmiColors.secondary,
        borderRadius: BorderRadius.circular(AdminStyle.heroRadius),
        border: Border.all(
          color: AdminStyle.ink,
          width: AdminStyle.heroBorderWidth,
        ),
        boxShadow: const [AdminStyle.heroShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: EmiColors.surface,
              borderRadius: BorderRadius.circular(EmiRadii.pill),
              border: Border.all(color: AdminStyle.ink, width: 1.5),
            ),
            child: Icon(icon, size: 30, color: AdminStyle.ink),
          ),
          const SizedBox(width: EmiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AdminStyle.ink),
                ),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AdminStyle.ink),
                ),
                const SizedBox(height: EmiSpacing.xs),
                Text(message, style: const TextStyle(color: AdminStyle.ink)),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Metric tile used only by [AdminDashboardScreen]. Same shape as the
/// shared `SimpleStatItem` but with a thin dark border and a solid offset
/// shadow on the highlighted variant.
class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: highlight ? EmiColors.surfaceAccent : EmiColors.surface,
        borderRadius: BorderRadius.circular(AdminStyle.cardRadius),
        border: Border.all(
          color: AdminStyle.ink,
          width: AdminStyle.cardBorderWidth,
        ),
        boxShadow: highlight ? const [AdminStyle.metricShadow] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: EmiColors.primary),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Quick-action tile used only by [AdminDashboardScreen]. Same shape as the
/// shared `QuickActionItem` but the icon container gets a thin dark border
/// so it reads consistently with the rest of the Admin surface.
class AdminQuickActionItem extends StatelessWidget {
  const AdminQuickActionItem({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AdminStyle.cardRadius),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(EmiSpacing.xs),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: EmiColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(EmiRadii.pill),
                  border: Border.all(color: AdminStyle.ink, width: 1.5),
                ),
                child: Icon(icon, color: AdminStyle.ink),
              ),
              const SizedBox(height: EmiSpacing.xs),
              SizedBox(
                height: 40,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
