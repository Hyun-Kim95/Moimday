import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'unauthorized_handler.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});

class ApiClient {
  ApiClient(this._tokens) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        final data = e.response?.data;
        if (data is Map && data['error'] is Map) {
          final err = data['error'] as Map;
          final code = err['code']?.toString() ?? 'UNKNOWN';
          if (e.response?.statusCode == 401 || code == 'UNAUTHORIZED') {
            await _tokens.clear();
            await globalUnauthorizedHandler?.call();
          }
          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              error: ApiException(
                code: code,
                message: err['message']?.toString() ?? '일시적인 오류가 발생했어요.',
                statusCode: e.response?.statusCode ?? 500,
              ),
            ),
          );
          return;
        }
        handler.next(e);
      },
    ));
  }

  final TokenStorage _tokens;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get<T>(path, queryParameters: query);
    return res.data as T;
  }

  Future<T> post<T>(String path, {Object? data, Map<String, dynamic>? headers}) async {
    final res = await _dio.post<T>(path, data: data, options: Options(headers: headers));
    return res.data as T;
  }

  Future<T> put<T>(String path, {Object? data, Map<String, dynamic>? headers}) async {
    final res = await _dio.put<T>(path, data: data, options: Options(headers: headers));
    return res.data as T;
  }

  Future<T> patch<T>(String path, {Object? data, Map<String, dynamic>? headers}) async {
    final res = await _dio.patch<T>(path, data: data, options: Options(headers: headers));
    return res.data as T;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}
