import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers.dart';
import '../sync/sync_engine.dart';

/// Thin status strip explaining offline state and unsynced changes.
class SyncBanner extends ConsumerStatefulWidget {
  const SyncBanner({super.key});

  @override
  ConsumerState<SyncBanner> createState() => _SyncBannerState();
}

class _SyncBannerState extends ConsumerState<SyncBanner> {
  @override
  Widget build(BuildContext context) {
    ref.listen(syncStatusProvider, (previous, next) {
      final status = next.value;
      if (status != null && status.rejected > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.syncRejected)));
      }
    });

    final status = ref.watch(syncStatusProvider).value;
    final pending = ref.watch(pendingChangesProvider).value ?? 0;
    final offline = status?.phase == SyncPhase.offline;
    if (!offline && pending == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final text = offline ? context.l10n.syncOffline : context.l10n.syncPending(pending);
    return Material(
      color: offline
          ? theme.colorScheme.secondary.withValues(alpha: 0.18)
          : theme.colorScheme.primary.withValues(alpha: 0.08),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(offline ? Icons.cloud_off_rounded : Icons.cloud_upload_outlined, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
              if (status?.phase == SyncPhase.syncing)
                const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
      ),
    );
  }
}
