import 'package:emi_mobile/app/app.dart';
import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
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
  Future<SessionUser> currentUser() async => throw UnimplementedError();

  @override
  Future<SessionUser> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<SessionUser> deleteAvatar() async => throw UnimplementedError();

  @override
  Future<void> deleteAccount({required String currentPassword}) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<SessionUser?> restoreSession() async => null;

  @override
  Future<SessionUser> uploadAvatar({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) async => throw UnimplementedError();

  @override
  Future<SessionUser> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async => throw UnimplementedError();

  @override
  Future<SessionUser> updateProfile({
    required String fullName,
    String? phone,
  }) async => throw UnimplementedError();
}

void main() {
  testWidgets('app starts at login after empty session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const EmiMobileApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Masuk EMI'), findsOneWidget);
  });
}
