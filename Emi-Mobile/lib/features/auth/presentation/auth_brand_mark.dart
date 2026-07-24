import 'package:flutter/material.dart';

import '../../../app/theme/emi_theme.dart';

/// Neobrutalism-lite brand mark shared by auth screens: solid orange badge
/// with a thin dark border, no shadow (the shadow lives on the form card
/// below it so the two never stack per desain.md 6.4/24).
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key, this.icon = Icons.school_outlined});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: EmiColors.primary,
            borderRadius: BorderRadius.circular(EmiRadii.pill),
            border: Border.all(color: EmiColors.border, width: 1.5),
          ),
          child: Icon(icon, size: 30, color: EmiColors.textPrimary),
        ),
        const SizedBox(height: EmiSpacing.sm),
        Text('EMI Kolaka', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
