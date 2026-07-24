import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';

class EmiCard extends StatelessWidget {
  const EmiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(EmiSpacing.md),
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Only true "hero"/primary cards should set this to true. Regular list
  /// items, detail sections, and form cards must stay flat (no shadow) per
  /// desain.md 6.4/24: max one border and one shadow per visual area.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(color: EmiColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(EmiRadii.card),
        boxShadow: elevated ? const [EmiShadows.hard] : null,
      ),
      child: Material(color: EmiColors.surface, child: child),
    );
  }
}
