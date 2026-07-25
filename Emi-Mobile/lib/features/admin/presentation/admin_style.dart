import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';

/// Visual tokens for the Admin shell (AppBar, Drawer, quick navigation,
/// dashboard) and its hero/metric cards. Mirrors the bold-but-tidy
/// neobrutalism look used on the auth screens (dark border + solid offset
/// shadow), scoped to Admin only so other roles are unaffected.
abstract final class AdminStyle {
  static const ink = EmiColors.textPrimary;

  static const heroBorderWidth = 2.0;
  static const cardBorderWidth = 1.5;
  static const heroRadius = 20.0;
  static const cardRadius = 16.0;
  static const chipRadius = EmiRadii.pill;

  static const heroShadow = BoxShadow(
    color: ink,
    offset: Offset(4, 5),
    blurRadius: 0,
  );

  static const metricShadow = BoxShadow(
    color: ink,
    offset: Offset(3, 3),
    blurRadius: 0,
  );
}
