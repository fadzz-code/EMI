import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';

class RoleHeroHeader extends StatelessWidget {
  const RoleHeroHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.message,
    required this.icon,
    this.action,
  });

  final String greeting;
  final String name;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.lg),
      decoration: BoxDecoration(
        color: EmiColors.secondary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [EmiShadows.hard],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: EmiColors.surface,
              borderRadius: BorderRadius.circular(EmiRadii.pill),
            ),
            child: Icon(icon, size: 32),
          ),
          const SizedBox(width: EmiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: EmiSpacing.xs),
                Text(message),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class SimpleStatItem extends StatelessWidget {
  const SimpleStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: highlight ? EmiColors.surfaceAccent : EmiColors.surface,
        borderRadius: BorderRadius.circular(EmiRadii.card),
        boxShadow: highlight ? const [EmiShadows.hard] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class QuickActionItem extends StatelessWidget {
  const QuickActionItem({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(EmiRadii.card),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(EmiSpacing.xs),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: EmiColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(EmiRadii.pill),
                ),
                child: Icon(icon),
              ),
              const SizedBox(height: EmiSpacing.xs),
              SizedBox(
                height: 40,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FriendlyState extends StatelessWidget {
  const FriendlyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.lg),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const SizedBox(height: EmiSpacing.xl),
        Icon(icon, size: 64),
        const SizedBox(height: EmiSpacing.md),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EmiSpacing.sm),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: EmiSpacing.lg),
          Center(
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ),
        ],
      ],
    );
  }
}
