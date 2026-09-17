import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.action,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String? action;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    action: json['action'] as String?,
    read: json['read'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

typedef ChannelPreferences = Map<String, ({bool inApp, bool email})>;

class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  Future<({List<AppNotification> items, int unread})> inbox() async {
    final response = await _api.get('/notifications', query: {'per_page': 50});
    return (
      items: [for (final n in response['data'] as List) AppNotification.fromJson(n as Map<String, dynamic>)],
      unread: (response['meta'] as Map)['unread_count'] as int,
    );
  }

  Future<void> markRead(String id) => _api.post('/notifications/$id/read', const {});

  Future<void> markAllRead() => _api.post('/notifications/read-all', const {});

  Future<ChannelPreferences> preferences() async {
    final response = await _api.get('/notification-preferences');
    return _parse(response['data'] as Map<String, dynamic>);
  }

  Future<ChannelPreferences> updatePreference(String type, {required bool inApp, required bool email}) async {
    final response = await _api.put('/notification-preferences', {
      'preferences': {
        type: {'in_app': inApp, 'email': email},
      },
    });
    return _parse(response['data'] as Map<String, dynamic>);
  }

  ChannelPreferences _parse(Map<String, dynamic> data) => {
    for (final MapEntry(:key, :value) in data.entries)
      key: (inApp: (value as Map<String, dynamic>)['in_app'] as bool, email: value['email'] as bool),
  };
}
