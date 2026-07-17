import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/teacher_repository.dart';

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
  Widget build(BuildContext context) => EmiCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(EmiRadii.card),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(EmiSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: EmiSpacing.sm),
            Expanded(
              child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

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
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26),
        const SizedBox(height: EmiSpacing.xs),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: EmiSpacing.xs),
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              value,
              maxLines: valueMaxLines,
              overflow: TextOverflow.ellipsis,
              style: compactValue
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            maxLines: captionMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    ),
  );
}

class TeacherActivityTile extends StatelessWidget {
  const TeacherActivityTile({super.key, required this.activity});

  final TeacherActivity activity;

  @override
  Widget build(BuildContext context) => EmiCard(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(activity.studentName.characters.first.toUpperCase()),
      ),
      title: Text(
        activity.studentName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_activityLabel(activity.type)}\n${activity.title}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
