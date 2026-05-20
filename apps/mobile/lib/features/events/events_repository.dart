import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(apiClientProvider));
});

class EventsRepository {
  EventsRepository(this._api);
  final ApiClient _api;
  final _uuid = const Uuid();

  Future<List<dynamic>> listEvents(String groupId, {String filter = 'all'}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/groups/$groupId/events',
      query: {'filter': filter},
    );
    return res['events'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getEvent(String eventId) =>
      _api.get('/events/$eventId');

  Future<Map<String, dynamic>> createPollEvent(String groupId, Map<String, dynamic> body) =>
      _api.post('/groups/$groupId/events', data: body);

  Future<Map<String, dynamic>> createFixedEvent(String groupId, Map<String, dynamic> body) =>
      _api.post('/groups/$groupId/events', data: body);

  Future<void> submitVotes(String eventId, List<Map<String, String>> votes) => _api.put(
        '/events/$eventId/date-votes',
        data: {'votes': votes},
        headers: {'Idempotency-Key': _uuid.v4()},
      );

  Future<void> submitResponse(String eventId, String value, {String? note}) => _api.put(
        '/events/$eventId/responses',
        data: {'value': value, if (note != null) 'note': note},
        headers: {'Idempotency-Key': _uuid.v4()},
      );

  Future<Map<String, dynamic>> pollSummary(String eventId) =>
      _api.get('/events/$eventId/date-poll-summary');

  Future<Map<String, dynamic>> confirmDatetime(String eventId, String optionId) =>
      _api.post('/events/$eventId/confirm-datetime', data: {'optionId': optionId});

  Future<Map<String, dynamic>> finalizeEvent(String eventId) =>
      _api.post('/events/$eventId/finalize');

  Future<Map<String, dynamic>> cancelEvent(String eventId) =>
      _api.post('/events/$eventId/cancel');

  Future<Map<String, dynamic>> nudge(String eventId, String phase) =>
      _api.post('/events/$eventId/nudge', data: {'phase': phase});

  Future<List<dynamic>> listComments(String eventId) async {
    final res = await _api.get<Map<String, dynamic>>('/events/$eventId/comments');
    return res['items'] as List<dynamic>;
  }

  Future<void> addComment(String eventId, String body) =>
      _api.post('/events/$eventId/comments', data: {'body': body});

  Future<Map<String, dynamic>> patchEvent(
    String eventId,
    int version,
    Map<String, dynamic> body,
  ) =>
      _api.patch(
        '/events/$eventId',
        data: body,
        headers: {'If-Match': version.toString()},
      );

  Future<Map<String, dynamic>> extendPollDeadline(
    String eventId, {
    required String pollDeadlineAt,
    List<Map<String, dynamic>>? addOptions,
  }) =>
      _api.post(
        '/events/$eventId/extend-poll-deadline',
        data: {
          'pollDeadlineAt': pollDeadlineAt,
          if (addOptions != null && addOptions.isNotEmpty)
            'optionChanges': {'add': addOptions},
        },
      );

  Future<Map<String, dynamic>> replaceDateOptions(
    String eventId,
    List<Map<String, dynamic>> options,
  ) =>
      _api.put('/events/$eventId/date-options', data: {'options': options});

  Future<void> deleteComment(String commentId) => _api.delete('/comments/$commentId');
}
