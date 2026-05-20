import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(apiClientProvider));
});

class HomeRepository {
  HomeRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> getHome(String groupId) =>
      _api.get('/groups/$groupId/home');

  Future<Map<String, dynamic>> getCalendar(String groupId, {String? from, String? to}) =>
      _api.get('/groups/$groupId/calendar', query: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });
}
