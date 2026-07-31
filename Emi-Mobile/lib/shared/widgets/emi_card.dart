import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';

/// Canonical flat card: single thin 1.5px border, no shadow, ever. This is
/// "neobrutalism tipis" (thin), not the heavy offset-shadow style. Do not
/// add a shadow option back — a border plus a solid offset shadow reads as
/// two stacked black edges, which looks like one thick border.
///
/// The fill color lives on the SAME `BoxDecoration` as the border/radius
/// (not on a separate `Material` sitting inside the padding). Splitting
/// them used to leave the rounded corners unpainted, letting the page
/// background peek through — this keeps the white fill and the border
/// perfectly in sync with the rounded shape.
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
      decoration: BoxDecoration(
        color: EmiColors.surface,
        border: Border.all(color: EmiColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(EmiRadii.card),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
