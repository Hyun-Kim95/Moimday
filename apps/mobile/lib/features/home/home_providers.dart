import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import 'home_repository.dart';

final homeDataProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final groupId = ref.watch(sessionProvider).value?.activeGroupId;
  if (groupId == null) throw Exception('그룹이 없어요');
  return ref.watch(homeRepositoryProvider).getHome(groupId);
});
