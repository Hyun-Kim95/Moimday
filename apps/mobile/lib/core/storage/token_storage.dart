import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

class TokenStorage {
  final _storage = const FlutterSecureStorage();

  Future<String?> getAccessToken() => _storage.read(key: 'access');
  Future<String?> getRefreshToken() => _storage.read(key: 'refresh');

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
