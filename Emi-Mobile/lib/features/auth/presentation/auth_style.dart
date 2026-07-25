import 'package:flutter/material.dart';

/// Visual tokens scoped ONLY to the auth flow (login, register, forgot
/// password, reset password). This mirrors a specific reference mock the
/// product owner supplied and is intentionally kept separate from the
/// app-wide `EmiColors`/`EmiTheme` so no other screen is affected.
abstract final class AuthStyle {
  static const ink = Color(0xFF1D1B17);
  static const pageBackground = Color(0xFFEEF1F7);
  static const cardBackground = Colors.white;
  static const fieldFill = Color(0xFFE9EFFB);
  static const errorBackground = Color(0xFFFBDCDC);
  static const errorText = Color(0xFFB3261E);
  static const successText = Color(0xFF1E7B3D);
  static const divider = Color(0xFFE1E5EC);

  static const cardRadius = 28.0;
  static const fieldRadius = 14.0;
  static const buttonRadius = 14.0;
  static const badgeRadius = 12.0;

  static const borderWidth = 2.0;
  static const cardBorderWidth = 2.5;
}
