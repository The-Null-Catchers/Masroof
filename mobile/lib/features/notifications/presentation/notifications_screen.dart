import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_text.dart';
import '../../planning/application/planning_providers.dart';

/// App destinations for notification deep links from the API.
const _deepLinks = {'/budgets': '/plan', '/goals': '/plan', '/recurring': '/recurring', '/analytics': '/analytics'};

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final inbox = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if ((inbox.value?.unread ?? 0) > 0)
            TextButton(
              onPressed: () async {
                await ref.read(notificationsRepositoryProvider).markAllRead();
                ref.invalidate(notificationsProvider);
              },
              child: Text(l10n.markAllRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          await ref.read(notificationsProvider.future);
        },
        child: inbox.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              EmptyState(icon: Icons.cloud_off_rounded, title: l10n.genericError, body: describeError(context, e)),
            ],
          ),
          data: (data) => data.items.isEmpty
              ? ListView(
                  children: [EmptyState(icon: Icons.notifications_none_rounded, title: l10n.noNotifications, body: '')],
                )
              : ListView.separated(
                  itemCount: data.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = data.items[index];
                    return ListTile(
                      tileColor: n.read ? null : theme.colorScheme.primary.withValues(alpha: 0.05),
                      leading: Icon(
                        n.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                        color: n.read ? theme.hintColor : theme.colorScheme.primary,
                      ),
                      title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w700)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(n.body),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMd(context.localeCode).add_jm().format(n.createdAt.toLocal()),
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () async {
                        if (!n.read) {
                          await ref.read(notificationsRepositoryProvider).markRead(n.id);
                          ref.invalidate(notificationsProvider);
                        }
                        final target = _deepLinks[n.action];
                        if (target != null && context.mounted) context.go(target);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Header bell with unread badge.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).value?.unread ?? 0;
    return IconButton(
      tooltip: context.l10n.notifications,
      onPressed: () => context.push('/notifications'),
      icon: Badge.count(count: unread, isLabelVisible: unread > 0, child: const Icon(Icons.notifications_none_rounded)),
    );
  }
}

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  static const _types = [
    'budget_threshold',
    'bill_reminder',
    'recurring_reminder',
    'goal_reminder',
    'weekly_summary',
    'monthly_summary',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationPreferences)),
      body: prefs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            EmptyState(icon: Icons.cloud_off_rounded, title: l10n.genericError, body: describeError(context, e)),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final type in _types)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                      child: Text(
                        l10n.notificationTypeLabel(type),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    for (final channel in ['in_app', 'email'])
                      SwitchListTile(
                        dense: true,
                        title: Text(channel == 'in_app' ? l10n.inApp : l10n.emailChannel),
                        value: channel == 'in_app' ? data[type]?.inApp ?? false : data[type]?.email ?? false,
                        onChanged: (value) async {
                          final current = data[type] ?? (inApp: false, email: false);
                          try {
                            await ref
                                .read(notificationsRepositoryProvider)
                                .updatePreference(
                                  type,
                                  inApp: channel == 'in_app' ? value : current.inApp,
                                  email: channel == 'email' ? value : current.email,
                                );
                            ref.invalidate(notificationPreferencesProvider);
                          } catch (e) {
                            if (context.mounted) showErrorSnack(context, e);
                          }
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
