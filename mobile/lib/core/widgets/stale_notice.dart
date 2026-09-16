import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Shown above server-computed data served from the offline cache.
class StaleNotice extends StatelessWidget {
  const StaleNotice({super.key, required this.stale});

  final bool stale;

  @override
  Widget build(BuildContext context) {
    if (!stale) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: theme.hintColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(context.l10n.offlineData, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          ),
        ],
      ),
    );
  }
}
