import 'package:flutter/material.dart';

import 'masroof_logo.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.body, this.action, this.icon, this.useLogo = false});

  final String title;
  final String body;
  final Widget? action;
  final IconData? icon;
  final bool useLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (useLogo)
            const Opacity(opacity: 0.9, child: MasroofLogo(size: 64))
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon ?? Icons.inbox_rounded, size: 32, color: theme.colorScheme.primary),
            ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
