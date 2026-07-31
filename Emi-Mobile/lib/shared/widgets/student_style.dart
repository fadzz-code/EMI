import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';

/// Visual language for the Student role — the calmest, friendliest surface
/// in the app. It shares the same "soft card" family as the Teacher role
/// and the login screen (white surfaces, orange accent, a faint blue-tinted
/// page background and light-blue secondary fills) so the three roles read
/// as one family, but with no hard ink borders or offset shadows anywhere.
///
/// Depth comes only from gentle drop shadows; grouping comes from spacing
/// and soft tinted fills rather than boxes inside boxes.
abstract final class StudentStyle {
  /// Page background: white with a faint cool cast, matching the login and
  /// teacher page tone (not the warm orange `EmiColors.background`).
  static const pageBackground = Color(0xFFF3F6FC);

  /// Soft blue-white fill for secondary surfaces: chips, tags, inactive
  /// tabs, icon badges, notice cards.
  static const tint = Color(0xFFEAF0FB);
  static const tintStrong = Color(0xFFDCE6F8);

  /// Warm accent tint used for the hero/greeting surface so the student
  /// home still feels welcoming rather than purely clinical.
  static const heroTintStart = Color(0xFFFFB877);
  static const heroTintEnd = Color(0xFFFF8A3D);

  static const surface = Colors.white;
  static const ink = EmiColors.textPrimary;
  static const inkMuted = EmiColors.textSecondary;

  static const cardRadius = 20.0;
  static const heroRadius = 24.0;
  static const chipRadius = 999.0;
  static const buttonRadius = 16.0;

  /// Soft, diffuse shadow used instead of a hard ink border wherever a
  /// surface needs to lift off the page.
  static List<BoxShadow> softShadow({double opacity = 0.06}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> heroShadow() => [
    BoxShadow(
      color: EmiColors.primary.withValues(alpha: 0.28),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  /// Muted background tint for a status, keyed to the canonical status
  /// string. Falls back to the neutral blue tint.
  static Color statusFill(String status) => switch (status) {
    'published' || 'completed' || 'active' || 'done' => const Color(0xFFDDF5E8),
    'in_progress' || 'processing' => const Color(0xFFE7F0FF),
    'pending' || 'open' || 'not_started' => const Color(0xFFFFF3CC),
    'failed' || 'closed' || 'locked' => const Color(0xFFFFE1E3),
    'archived' => const Color(0xFFECE7E4),
    _ => tintStrong,
  };

  static Color statusText(String status) => switch (status) {
    'published' || 'completed' || 'active' || 'done' => const Color(0xFF207A4C),
    'in_progress' || 'processing' => const Color(0xFF2563A8),
    'pending' || 'open' || 'not_started' => const Color(0xFF8A6500),
    'failed' || 'closed' || 'locked' => const Color(0xFFA62932),
    'archived' => const Color(0xFF685952),
    _ => ink,
  };
}
