import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield !initial.every((r) => r == ConnectivityResult.none);
  await for (final results in connectivity.onConnectivityChanged) {
    yield !results.every((r) => r == ConnectivityResult.none);
  }
});
