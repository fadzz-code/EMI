import 'session_user.dart';

abstract class AuthRepository {
  Future<SessionUser> login({required String email, required String password});
  Future<SessionUser?> restoreSession();
  Future<SessionUser> currentUser();
  Future<SessionUser> updateProfile({required String fullName, String? phone});
  Future<SessionUser> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });
  Future<void> logout();
}
