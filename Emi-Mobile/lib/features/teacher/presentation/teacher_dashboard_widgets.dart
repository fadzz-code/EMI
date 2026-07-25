import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';
import '../data/teacher_repository.dart';
import 'teacher_style.dart';

/// Hero header used only by [TeacherDashboardScreen]. A soft, orange
/// gradient card with a floating white icon badge — no hard border, no
/// stacked drop shadows — a calmer greeting card than the rest of the app.
class TeacherHeroHeader extends StatelessWidget {
  const TeacherHeroHeader({
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
          colors: [EmiColors.primary, Color(0xFFFFA968)],
        ),
        borderRadius: BorderRadius.circular(TeacherStyle.heroRadius),
        boxShadow: TeacherStyle.heroShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: EmiColors.primary),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: EmiSpacing.xs),
                Text(
                  message,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92)),
                ),
              ],
            ),
          ),
          if (action != null)
            IconTheme(
              data: const IconThemeData(color: Colors.white),
              child: action!,
            ),
        ],
      ),
    );
  }
}

/// Notice/tip card used only by [TeacherDashboardScreen]: a soft blue-tint
/// panel with a small circular icon badge.
class TeacherNoticeCard extends StatelessWidget {
  const TeacherNoticeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: TeacherStyle.tint,
        borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: EmiColors.primary),
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
                  ).textTheme.titleMedium?.copyWith(color: TeacherStyle.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: TeacherStyle.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick-action tile: compact rounded tile with a tinted icon badge on top
/// and a label below — sized to sit comfortably in a `Wrap`.
class TeacherQuickAction extends StatelessWidget {
  const TeacherQuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: TeacherStyle.surface,
    borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
    elevation: 0,
    child: InkWell(
      borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
      onTap: onTap,
      child: Container(
        width: 92,
        height: 112,
        padding: const EdgeInsets.all(EmiSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
          boxShadow: TeacherStyle.softShadow(),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: TeacherStyle.tint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: EmiColors.primary),
            ),
            const SizedBox(height: EmiSpacing.xs),
            SizedBox(
              height: 36,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: TeacherStyle.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Metric tile: soft card, colored icon chip, big value, small label.
class TeacherDashboardMetricTile extends StatelessWidget {
  const TeacherDashboardMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.valueMaxLines = 1,
    this.captionMaxLines = 1,
    this.compactValue = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final int valueMaxLines;
  final int captionMaxLines;
  final bool compactValue;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(EmiSpacing.md),
    decoration: BoxDecoration(
      color: TeacherStyle.surface,
      borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
      boxShadow: TeacherStyle.softShadow(),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: TeacherStyle.tint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: EmiColors.primary),
        ),
        const SizedBox(height: EmiSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: TeacherStyle.inkMuted, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              value,
              maxLines: valueMaxLines,
              overflow: TextOverflow.ellipsis,
              style:
                  (compactValue
                          ? Theme.of(context).textTheme.titleMedium
                          : Theme.of(context).textTheme.titleLarge)
                      ?.copyWith(color: TeacherStyle.ink),
            ),
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            maxLines: captionMaxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: TeacherStyle.inkMuted, fontSize: 11),
          ),
      ],
    ),
  );
}

/// Activity tile: soft card with a circular avatar and two-line subtitle.
class TeacherActivityTile extends StatelessWidget {
  const TeacherActivityTile({super.key, required this.activity});

  final TeacherActivity activity;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: EmiSpacing.sm),
    decoration: BoxDecoration(
      color: TeacherStyle.surface,
      borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
      boxShadow: TeacherStyle.softShadow(),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: TeacherStyle.tint,
        foregroundColor: EmiColors.primary,
        child: Text(activity.studentName.characters.first.toUpperCase()),
      ),
      title: Text(
        activity.studentName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: TeacherStyle.ink),
      ),
      subtitle: Text(
        '${_activityLabel(activity.type)}\n${activity.title}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: TeacherStyle.inkMuted),
      ),
    ),
  );

  String _activityLabel(String type) => switch (type) {
    'quiz_submitted' => 'Kuis dikumpulkan',
    'module_completed' => 'Modul diselesaikan',
    'speaking_submitted' => 'Latihan speaking dikirim',
    'speaking_reviewed' => 'Speaking sudah dinilai',
    _ => 'Aktivitas belajar',
  };
}
