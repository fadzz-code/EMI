import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';
import 'auth_style.dart';

/// Brand mark shared by auth screens: small orange square logo badge with
/// a dark border, followed by the "EMI" wordmark — matching the reference
/// mock's top-left lockup.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key, this.icon = Icons.school_outlined});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: EmiColors.primary,
            borderRadius: BorderRadius.circular(AuthStyle.badgeRadius),
            border: Border.all(color: AuthStyle.ink, width: 2),
          ),
          child: Icon(icon, size: 22, color: AuthStyle.ink),
        ),
        const SizedBox(width: EmiSpacing.sm),
        Text(
          'EMI',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: AuthStyle.ink),
        ),
      ],
    );
  }
}
