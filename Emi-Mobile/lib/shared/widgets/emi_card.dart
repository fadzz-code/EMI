import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';

/// Canonical flat card: single 1.5px border, no shadow. Per desain.md 6.4/24,
/// shadow is reserved for true hero/primary elements (rendered directly with
/// EmiShadows where needed), never for standard list/detail/form cards, to
/// avoid the "double box" look of a bordered card stacked on a hard shadow.
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
