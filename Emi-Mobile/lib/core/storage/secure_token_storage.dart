import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/session_user.dart';
import 'token_storage.dart';

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'emi_access_token';
  static const _sessionUserKey = 'emi_session_user';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<void> saveSessionUser(SessionUser user) =>
      _storage.write(key: _sessionUserKey, value: jsonEncode(user.toJson()));

  @override
  Future<SessionUser?> readSessionUser() async {
    final value = await _storage.read(key: _sessionUserKey);
    if (value == null || value.isEmpty) return null;
    return SessionUser.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAccessToken() => _storage.delete(key: _accessTokenKey);

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _sessionUserKey);
  }
}
