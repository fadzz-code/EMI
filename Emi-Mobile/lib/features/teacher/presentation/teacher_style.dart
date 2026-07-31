import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';

/// Fresh visual language for the Teacher role only — designed from scratch,
/// not copied from Admin's neobrutalism (hard border + offset shadow) look.
///
/// Palette constraint: white surfaces, orange accents, and a soft
/// blue-tinted white for the page background and secondary fills — the
/// same family of colors used on the login screen, but expressed here as a
/// calm, modern "soft card" style: no hard ink borders, gentle drop
/// shadows, generous rounding, and a light-blue tint for anything
/// secondary (chips, tags, inactive states).
abstract final class TeacherStyle {
  /// Page background: white with a faint blue cast, matching the login
  /// screen's page tone (not the warm orange-tinted `EmiColors.background`
  /// used elsewhere in the app).
  static const pageBackground = Color(0xFFF3F6FC);

  /// Soft blue-white fill for secondary surfaces: chips, tags, inactive
  /// tabs, notice cards. Same family as the login field fill.
  static const tint = Color(0xFFEAF0FB);
  static const tintStrong = Color(0xFFDCE6F8);

  static const surface = Colors.white;
  static const ink = EmiColors.textPrimary;
  static const inkMuted = EmiColors.textSecondary;

  static const pagePadding = EdgeInsets.all(16);
  static const sectionGap = 24.0;
  static const itemGap = 12.0;
  static const minTouchTarget = 48.0;

  static const cardRadius = 18.0;
  static const heroRadius = 24.0;
  static const chipRadius = 999.0;
  static const buttonRadius = 14.0;

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final scheme = base.colorScheme.copyWith(
      primary: EmiColors.primary,
      surface: surface,
      surfaceContainer: tint,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
    );
    final rounded = OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
      borderSide: BorderSide.none,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: pageBackground,
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: rounded,
        enabledBorder: rounded,
        focusedBorder: rounded.copyWith(
          borderSide: const BorderSide(color: EmiColors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, minTouchTarget),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(minTouchTarget),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minTileHeight: 64,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  /// Soft, diffuse shadow used instead of a hard ink border everywhere a
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
}
