import 'session_user.dart';

class AuthRegistrationPayload {
  const AuthRegistrationPayload({
    required this.fullName,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.requestedRole,
    required this.schoolId,
    required this.classId,
  });

  final String fullName;
  final String email;
  final String password;
  final String passwordConfirmation;
  final UserRole requestedRole;
  final String schoolId;
  final String classId;
}

class AuthRegistrationResult {
  const AuthRegistrationResult({required this.userId, required this.status});

  final String userId;
  final String status;
}

class PublicSchoolOption {
  const PublicSchoolOption({required this.id, required this.name});

  final String id;
  final String name;

  factory PublicSchoolOption.fromJson(Map<String, dynamic> json) {
    return PublicSchoolOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class PublicClassOption {
  const PublicClassOption({required this.id, required this.name});

  final String id;
  final String name;

  factory PublicClassOption.fromJson(Map<String, dynamic> json) {
    return PublicClassOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

abstract class AuthRepository {
  Future<List<PublicSchoolOption>> listPublicSchools();
  Future<List<PublicClassOption>> listPublicClasses(String schoolId);
  Future<AuthRegistrationResult> register(AuthRegistrationPayload payload);
  Future<SessionUser> login({required String email, required String password});
  Future<SessionUser?> restoreSession();
  Future<SessionUser> currentUser();
  Future<SessionUser> updateProfile({required String fullName, String? phone});
  Future<SessionUser> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });
  Future<SessionUser> uploadAvatar({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  });
  Future<SessionUser> deleteAvatar();
  Future<void> deleteAccount({required String currentPassword});
  Future<void> logout();
}
