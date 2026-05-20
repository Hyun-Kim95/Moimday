import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_status.dart';

/// 오프라인 시 쓰기 API 호출을 막고 안내한다 (PRD §8.8).
class OfflineWriteGuard {
  OfflineWriteGuard(this._ref);

  final WidgetRef _ref;

  bool get isOnline => _ref.read(connectivityStatusProvider).valueOrNull ?? true;

  bool blockWrite(BuildContext context) {
    if (isOnline) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('오프라인이에요. 연결된 뒤 다시 시도해 주세요.')),
    );
    return true;
  }
}
