import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const kakaoKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY', defaultValue: '');
  if (kakaoKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoKey);
  }
  await initializeDateFormatting('ko_KR');
  runApp(const ProviderScope(child: MoimdayApp()));
}
