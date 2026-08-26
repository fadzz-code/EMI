import 'package:emi_mobile/core/storage/token_storage.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<void> clearSession() async => token = null;

  @override
  Future<void> deleteAccessToken() async => token = null;

  SessionUser? user;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<SessionUser?> readSessionUser() async => user;

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;

  @override
  Future<void> saveSessionUser(SessionUser user) async => this.user = user;
}

void main() {
  test('stores and clears token', () async {
    final storage = MemoryTokenStorage();
    await storage.saveAccessToken('safe-test-token');
    expect(await storage.readAccessToken(), 'safe-test-token');
    await storage.clearSession();
    expect(await storage.readAccessToken(), isNull);
  });
}
