import 'package:emi_mobile/app/app.dart';
import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<SessionUser> currentUser() async => _student;

  @override
  Future<SessionUser> login({
    required String email,
    required String password,
  }) async => _student;

  @override
  Future<SessionUser> deleteAvatar() async => _student;

  @override
  Future<void> logout() async {}

  @override
  Future<SessionUser?> restoreSession() async => null;

  @override
  Future<SessionUser> uploadAvatar({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) async => _student;

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
}

const _student = SessionUser(
  id: '1',
  fullName: 'Siswa Test',
  email: 'siswa@example.test',
  role: UserRole.student,
  status: 'approved',
);

void main() {
  testWidgets('login validation shows required errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const EmiMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Password wajib diisi.'), findsOneWidget);
  });
}
