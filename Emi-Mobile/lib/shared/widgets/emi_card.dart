import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';

/// Canonical flat card: single thin 1.5px border, no shadow, ever. This is
/// "neobrutalism tipis" (thin), not the heavy offset-shadow style. Do not
/// add a shadow option back — a border plus a solid offset shadow reads as
/// two stacked black edges, which looks like one thick border.
class EmiCard extends StatelessWidget {
  const EmiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(EmiSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(color: EmiColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: Material(color: EmiColors.surface, child: child),
    );
  }
}
