import 'package:emi_mobile/core/network/session_invalidation_provider.dart';
import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.logoutError = false});

  final bool logoutError;

  @override
  Future<List<PublicSchoolOption>> listPublicSchools() async => const [];

  @override
  Future<List<PublicClassOption>> listPublicClasses(String schoolId) async =>
      const [];

  @override
  Future<AuthRegistrationResult> register(
    AuthRegistrationPayload payload,
  ) async => const AuthRegistrationResult(userId: '1', status: 'pending');

  @override
  Future<void> forgotPassword({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {}

  @override
  Future<SessionUser> currentUser() async => _student;

  @override
  Future<SessionUser> deleteAvatar() async => _student;

  @override
  Future<SessionUser> login({
    required String email,
    required String password,
  }) async => _student;

  @override
  Future<void> deleteAccount({required String currentPassword}) async {}

  @override
  Future<void> logout() async {
    if (logoutError) throw StateError('logout failed');
  }

  @override
  Future<SessionUser?> restoreSession() async => _student;

  @override
  Future<SessionUser> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async => _student;

  @override
  Future<SessionUser> updateProfile({
    required String fullName,
    String? phone,
  }) async => _student;

  @override
  Future<SessionUser> uploadAvatar({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) async => _student;
}

const _student = SessionUser(
  id: '1',
  fullName: 'Siswa Test',
  email: 'siswa@example.test',
  role: UserRole.student,
  status: 'approved',
);

void main() {
  test('logout failure still clears controller session', () async {
    final controller = AuthController(_FakeAuthRepository(logoutError: true));
    await controller.restoreSession();

    await expectLater(controller.logout(), throwsStateError);

    expect(controller.state.status, AuthStatus.unauthenticated);
  });

  test(
    'session invalidation changes authenticated state to unauthenticated',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).restoreSession();
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticatedStudent,
      );

      container.read(sessionInvalidationProvider.notifier).state++;
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(authControllerProvider).status,
        AuthStatus.sessionExpired,
      );
    },
  );
}
