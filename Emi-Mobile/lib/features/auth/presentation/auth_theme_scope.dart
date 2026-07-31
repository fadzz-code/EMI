import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';
import 'auth_style.dart';

/// Input/button styling scoped to auth screens only (login, register,
/// forgot/reset password), matching the reference mock: light-blue filled
/// fields with a solid dark border, and a solid orange button with a dark
/// border and no elevation shadow (the card carries the offset shadow
/// instead). The rest of the app keeps the app-wide `EmiTheme.light()`.
class AuthThemeScope extends StatelessWidget {
  const AuthThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: AuthStyle.fieldFill,
          hintStyle: TextStyle(color: AuthStyle.ink.withValues(alpha: 0.55)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: EmiSpacing.md,
            vertical: EmiSpacing.md,
          ),
          border: _border(),
          enabledBorder: _border(),
          focusedBorder: _border(color: EmiColors.primary),
          errorBorder: _border(color: AuthStyle.errorText),
          focusedErrorBorder: _border(color: AuthStyle.errorText),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: EmiColors.primary,
            foregroundColor: AuthStyle.ink,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(
              horizontal: EmiSpacing.lg,
              vertical: EmiSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AuthStyle.buttonRadius),
              side: const BorderSide(
                color: AuthStyle.ink,
                width: AuthStyle.borderWidth,
              ),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: EmiColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      child: child,
    );
  }

  static OutlineInputBorder _border({Color color = AuthStyle.ink}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AuthStyle.fieldRadius),
      borderSide: BorderSide(color: color, width: AuthStyle.borderWidth),
    );
  }
}
