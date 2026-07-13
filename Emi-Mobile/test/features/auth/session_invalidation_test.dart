import 'package:emi_mobile/core/network/session_invalidation_provider.dart';
import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
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
  Future<void> logout() async {}

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
        AuthStatus.authenticated,
      );

      container.read(sessionInvalidationProvider.notifier).state++;
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    },
  );
}
