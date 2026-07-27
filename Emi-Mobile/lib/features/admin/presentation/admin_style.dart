import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';

/// Visual language for the Admin role — same calm "soft card" family as the
/// Teacher and Student roles and the login screen (white surfaces, orange
/// accent, a faint blue-tinted page background and light-blue secondary
/// fills). Admin keeps a higher information density than the other roles,
/// but drops all hard ink borders and solid offset shadows in favour of
/// gentle drop shadows and tinted fills.
abstract final class AdminStyle {
  /// Page background: white with a faint cool cast, matching the login and
  /// other-role page tone.
  static const pageBackground = Color(0xFFF3F6FC);

  /// Soft blue-white fill for secondary surfaces: chips, tags, inactive
  /// states, icon badges, notice cards.
  static const tint = Color(0xFFEAF0FB);
  static const tintStrong = Color(0xFFDCE6F8);

  static const surface = Colors.white;
  static const ink = EmiColors.textPrimary;
  static const inkMuted = EmiColors.textSecondary;

  static const heroRadius = 24.0;
  static const cardRadius = 20.0;
  static const chipRadius = EmiRadii.pill;

  /// Retained for backwards-compatible call sites; borders are no longer
  /// drawn, so these widths are effectively unused but kept to avoid
  /// touching every reference at once.
  static const heroBorderWidth = 0.0;
  static const cardBorderWidth = 0.0;

  /// Soft, diffuse shadow used instead of a hard ink border wherever a
  /// surface needs to lift off the page.
  static List<BoxShadow> softShadow({double opacity = 0.06}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> heroGlow() => [
    BoxShadow(
      color: EmiColors.primary.withValues(alpha: 0.28),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  /// Muted background tint for a status, keyed to the canonical status
  /// string. Falls back to the neutral blue tint.
  static Color statusFill(String status) => switch (status) {
    'published' ||
    'completed' ||
    'active' ||
    'approved' => const Color(0xFFDDF5E8),
    'in_progress' || 'processing' => const Color(0xFFE7F0FF),
    'pending' || 'draft' => const Color(0xFFFFF3CC),
    'failed' || 'rejected' || 'inactive' => const Color(0xFFFFE1E3),
    'archived' => const Color(0xFFECE7E4),
    _ => tintStrong,
  };

  static Color statusText(String status) => switch (status) {
    'published' ||
    'completed' ||
    'active' ||
    'approved' => const Color(0xFF207A4C),
    'in_progress' || 'processing' => const Color(0xFF2563A8),
    'pending' || 'draft' => const Color(0xFF8A6500),
    'failed' || 'rejected' || 'inactive' => const Color(0xFFA62932),
    'archived' => const Color(0xFF685952),
    _ => ink,
  };
}
