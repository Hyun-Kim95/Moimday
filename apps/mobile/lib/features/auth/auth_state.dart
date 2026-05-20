import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

final sessionProvider = AsyncNotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

class GroupSummary {
  GroupSummary({
    required this.id,
    required this.name,
    required this.isAdmin,
    required this.memberCount,
  });

  factory GroupSummary.fromJson(Map<String, dynamic> json) => GroupSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        isAdmin: json['isAdmin'] as bool? ?? false,
        memberCount: json['memberCount'] as int? ?? 0,
      );

  final String id;
  final String name;
  final bool isAdmin;
  final int memberCount;
}

class Session {
  Session({
    required this.userId,
    required this.displayName,
    this.activeGroupId,
    this.groups = const [],
    this.isGroupAdmin = false,
  });

  final String userId;
  final String displayName;
  final String? activeGroupId;
  final List<GroupSummary> groups;
  final bool isGroupAdmin;

  /// 호환: 기존 `groupId` 참조.
  String? get groupId => activeGroupId;

  bool get hasGroup => activeGroupId != null;
}

class SessionNotifier extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    try {
      return _sessionFromMe(await ref.read(authRepositoryProvider).me());
    } catch (_) {
      return null;
    }
  }

  Session _sessionFromMe(Map<String, dynamic> me) {
    final groupsRaw = me['groups'] as List<dynamic>? ?? [];
    final groups = groupsRaw
        .map((g) => GroupSummary.fromJson(g as Map<String, dynamic>))
        .toList();
    final active =
        me['activeGroupId'] as String? ?? me['groupId'] as String?;
    return Session(
      userId: me['id'] as String,
      displayName: me['displayName'] as String,
      activeGroupId: active,
      groups: groups,
      isGroupAdmin: me['isGroupAdmin'] as bool? ?? false,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final me = await ref.read(authRepositoryProvider).me();
      return _sessionFromMe(me);
    });
  }

  Future<void> clear() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
