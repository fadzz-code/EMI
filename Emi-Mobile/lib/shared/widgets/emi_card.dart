import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';

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
        border: Border.all(color: EmiColors.border, width: 2),
        borderRadius: BorderRadius.circular(EmiRadii.card),
        boxShadow: const [EmiShadows.hard],
      ),
      child: Material(color: EmiColors.surface, child: child),
    );
  }
}
