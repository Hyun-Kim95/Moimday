import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<Map<String, dynamic>> signInWithOAuth({
    required String provider,
    String? idToken,
    String? accessToken,
  }) async {
    final body = <String, dynamic>{};
    if (idToken != null) body['idToken'] = idToken;
    if (accessToken != null) body['accessToken'] = accessToken;

    final data = await _api.post<Map<String, dynamic>>(
      '/auth/oauth/$provider',
      data: body,
    );
    await _tokens.saveTokens(
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
    return data;
  }

  Future<void> logout() => _tokens.clear();

  Future<Map<String, dynamic>> me() => _api.get<Map<String, dynamic>>('/users/me');

  Future<void> registerPushToken(String platform, String token) async {
    await _api.put('/users/me/push-token', data: {'platform': platform, 'token': token});
  }

  ApiException? asApiError(Object e) {
    if (e is DioException && e.error is ApiException) return e.error as ApiException;
    return null;
  }
}
