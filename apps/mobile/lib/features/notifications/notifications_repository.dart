import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<List<dynamic>> list({bool unreadOnly = false}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/notifications',
      query: {if (unreadOnly) 'unreadOnly': 'true'},
    );
    return res['items'] as List<dynamic>;
  }

  Future<void> markRead(String id) => _api.patch('/notifications/$id/read');
  Future<void> markAllRead() => _api.post('/notifications/read-all');
}
