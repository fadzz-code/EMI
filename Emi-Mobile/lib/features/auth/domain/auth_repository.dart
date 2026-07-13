import 'session_user.dart';

abstract class AuthRepository {
  Future<SessionUser> login({required String email, required String password});
  Future<SessionUser?> restoreSession();
  Future<SessionUser> currentUser();
  Future<void> logout();
}
