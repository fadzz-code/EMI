import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';

enum EmiStatusTone {
  draft,
  published,
  processing,
  completed,
  pending,
  failed,
  archived,
  reviewed,
  neutral,
}

class EmiStatusBadge extends StatelessWidget {
  const EmiStatusBadge({
    super.key,
    required this.label,
    this.tone = EmiStatusTone.neutral,
    this.icon,
  });

  final String label;
  final EmiStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: colors.foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _StatusColors _colorsFor(EmiStatusTone tone) => switch (tone) {
    EmiStatusTone.draft => const _StatusColors(
      Color(0xFFF3EAE4),
      Color(0xFF5F4B42),
    ),
    EmiStatusTone.published => const _StatusColors(
      Color(0xFFDDF5E8),
      Color(0xFF207A4C),
    ),
    EmiStatusTone.processing => const _StatusColors(
      Color(0xFFE7F0FF),
      Color(0xFF2563A8),
    ),
    EmiStatusTone.completed => const _StatusColors(
      Color(0xFFDDF5E8),
      Color(0xFF207A4C),
    ),
    EmiStatusTone.pending => const _StatusColors(
      Color(0xFFFFF3CC),
      Color(0xFF8A6500),
    ),
    EmiStatusTone.failed => const _StatusColors(
      Color(0xFFFFE1E3),
      Color(0xFFA62932),
    ),
    EmiStatusTone.archived => const _StatusColors(
      Color(0xFFECE7E4),
      Color(0xFF685952),
    ),
    EmiStatusTone.reviewed => const _StatusColors(
      Color(0xFFEDE4FF),
      Color(0xFF6941A5),
    ),
    EmiStatusTone.neutral => const _StatusColors(
      EmiColors.surfaceAccent,
      EmiColors.textPrimary,
    ),
  };
}

class _StatusColors {
  const _StatusColors(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// Maps common backend status keys (draft/published/archived/pending/...)
/// to the canonical [EmiStatusTone] defined in `Docs/mobile/desain.md`.
EmiStatusTone emiStatusToneFromKey(String? key) => switch (key) {
  'draft' => EmiStatusTone.draft,
  'published' || 'active' || 'approved' => EmiStatusTone.published,
  'processing' || 'in_progress' => EmiStatusTone.processing,
  'completed' || 'submitted' => EmiStatusTone.completed,
  'pending' => EmiStatusTone.pending,
  'failed' || 'rejected' || 'error' => EmiStatusTone.failed,
  'archived' || 'inactive' => EmiStatusTone.archived,
  'reviewed' => EmiStatusTone.reviewed,
  _ => EmiStatusTone.neutral,
};
