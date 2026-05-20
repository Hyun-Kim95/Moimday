import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingPrefsProvider = Provider<OnboardingPrefs>((ref) => OnboardingPrefs());

final onboardingCompletedProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingPrefsProvider).isCompleted();
});

class OnboardingPrefs {
  static const _key = 'onboarding_completed';

  Future<bool> isCompleted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key) ?? false;
  }

  Future<void> setCompleted() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
  }
}
