import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

class UserRepository {
  UserRepository(this._api);
  final ApiClient _api;

  Future<void> deleteAccount() => _api.delete('/users/me');

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    bool? autoReminderEnabled,
  }) =>
      _api.patch('/users/me', data: {
        if (displayName != null) 'displayName': displayName,
        if (autoReminderEnabled != null) 'autoReminderEnabled': autoReminderEnabled,
      });
}
