import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';
import 'auth_style.dart';

/// Card used only by the auth screens (login, register, forgot password,
/// reset password), matching a specific reference mock: white card, thick
/// dark rounded border, and a solid (non-blurred) offset shadow.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(EmiSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AuthStyle.cardRadius),
        boxShadow: const [
          BoxShadow(color: AuthStyle.ink, offset: Offset(6, 8), blurRadius: 0),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AuthStyle.cardBackground,
          borderRadius: BorderRadius.circular(AuthStyle.cardRadius),
          border: Border.all(
            color: AuthStyle.ink,
            width: AuthStyle.cardBorderWidth,
          ),
        ),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}
