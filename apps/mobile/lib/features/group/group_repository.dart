import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(apiClientProvider));
});

class GroupRepository {
  GroupRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> createGroup(String name) =>
      _api.post('/groups', data: {'name': name});

  Future<Map<String, dynamic>> getGroup(String groupId) =>
      _api.get('/groups/$groupId');

  Future<Map<String, dynamic>> createInvite(String groupId) =>
      _api.post('/groups/$groupId/invites');

  Future<Map<String, dynamic>> acceptInvite(String token) =>
      _api.post('/invites/$token/accept');

  Future<Map<String, dynamic>> setActiveGroup(String groupId) =>
      _api.patch('/users/me/active-group', data: {'groupId': groupId});

  Future<void> leaveGroup(String groupId, {String? transferAdminToUserId}) =>
      _api.post(
        '/groups/$groupId/leave',
        data: transferAdminToUserId != null
            ? {'transferAdminToUserId': transferAdminToUserId}
            : {},
      );

  Future<void> transferAdmin(String groupId, String newAdminUserId) =>
      _api.post('/groups/$groupId/admin/transfer', data: {'newAdminUserId': newAdminUserId});

  Future<void> deleteGroup(String groupId) => _api.delete('/groups/$groupId');

  Future<void> removeMember(String groupId, String userId) =>
      _api.delete('/groups/$groupId/members/$userId');
}
