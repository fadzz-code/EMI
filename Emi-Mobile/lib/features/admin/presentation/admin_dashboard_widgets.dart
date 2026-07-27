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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB877), Color(0xFFFF8A3D)],
        ),
        borderRadius: BorderRadius.circular(AdminStyle.heroRadius),
        boxShadow: AdminStyle.heroGlow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(EmiRadii.pill),
            ),
            child: Icon(icon, size: 30, color: Colors.white),
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
                  message,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92)),
                ),
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
        color: AdminStyle.surface,
        borderRadius: BorderRadius.circular(AdminStyle.cardRadius),
        boxShadow: AdminStyle.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: highlight ? EmiColors.primarySoft : AdminStyle.tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: EmiColors.primary),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: highlight ? EmiColors.primary : AdminStyle.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AdminStyle.inkMuted),
          ),
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
                  color: AdminStyle.tint,
                  borderRadius: BorderRadius.circular(EmiRadii.pill),
                ),
                child: Icon(icon, color: EmiColors.primary),
              ),
              const SizedBox(height: EmiSpacing.xs),
              SizedBox(
                height: 40,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AdminStyle.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
