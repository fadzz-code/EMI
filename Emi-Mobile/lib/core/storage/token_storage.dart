import '../../features/auth/domain/session_user.dart';

abstract class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> saveSessionUser(SessionUser user);
  Future<SessionUser?> readSessionUser();
  Future<void> deleteAccessToken();
  Future<void> clearSession();
}
