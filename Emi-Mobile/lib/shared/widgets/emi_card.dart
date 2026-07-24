import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';

/// Canonical card: single 1.5px border, flat by default. Per desain.md
/// 6.4/24, shadow is reserved for true hero/primary elements (one card per
/// screen at most) and must never stack with another shadowed/bordered
/// element, to avoid the "double box" look of a bordered card sitting on a
/// hard shadow box.
class EmiCard extends StatelessWidget {
  const EmiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(EmiSpacing.md),
    this.hero = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Set true only for the single primary card of a screen (e.g. the auth
  /// form card). Adds the canonical short neobrutalism shadow. Never nest
  /// another bordered/shadowed EmiCard or badge on top of a hero card.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(color: EmiColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(EmiRadii.card),
        boxShadow: hero ? const [EmiShadows.hard] : null,
      ),
      child: Material(color: EmiColors.surface, child: child),
    );
  }
}
