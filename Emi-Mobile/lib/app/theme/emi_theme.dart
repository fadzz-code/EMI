import 'package:flutter/material.dart';

class EmiColors {
  const EmiColors._();

  static const primary = Color(0xFFFF8A3D);
  static const secondary = Color(0xFFFDD758);
  static const background = Color(0xFFFEF8F1);
  static const backgroundWarm = Color(0xFFFFF9F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFFFF1EB);
  static const surfaceAccent = Color(0xFFFEEAE0);
  static const textPrimary = Color(0xFF1D1B17);
  static const border = Color(0xFF1D1B17);
  static const success = Color(0xFF5BBE5D);
  static const warning = Color(0xFFFDD758);
  static const error = Color(0xFFBA1A1A);
}

class EmiRadii {
  const EmiRadii._();

  static const card = 12.0;
  static const button = 12.0;
  static const input = 12.0;
  static const pill = 9999.0;
}

class EmiSpacing {
  const EmiSpacing._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class EmiShadows {
  const EmiShadows._();

  static const hard = BoxShadow(
    color: EmiColors.border,
    offset: Offset(4, 4),
    blurRadius: 0,
    spreadRadius: 0,
  );
}

class EmiTheme {
  const EmiTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: EmiColors.primary,
      brightness: Brightness.light,
      primary: EmiColors.primary,
      secondary: EmiColors.secondary,
      surface: EmiColors.surface,
      error: EmiColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: EmiColors.background,
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: EmiColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: EmiColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: EmiColors.textPrimary,
        ),
        bodyMedium: TextStyle(color: EmiColors.textPrimary),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: EmiColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EmiColors.surface,
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(width: 3),
        errorBorder: _inputBorder(color: EmiColors.error),
        focusedErrorBorder: _inputBorder(color: EmiColors.error, width: 3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EmiColors.primary,
          foregroundColor: EmiColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: EmiSpacing.lg,
            vertical: EmiSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EmiRadii.button),
            side: const BorderSide(color: EmiColors.border, width: 2),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder({
    Color color = EmiColors.border,
    double width = 2,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(EmiRadii.input),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
