import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/features/teacher/presentation/teacher_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeAuthRepository implements AuthRepository {
  int logoutCalls = 0;

  @override
  Future<void> logout() async => logoutCalls++;

  @override
  Future<SessionUser?> restoreSession() async => _teacher;

  @override
  Future<SessionUser> currentUser() async => _teacher;

  @override
  Future<SessionUser> login({
    required String email,
    required String password,
  }) async => _teacher;

  @override
  Future<List<PublicSchoolOption>> listPublicSchools() async => const [];

  @override
  Future<List<PublicClassOption>> listPublicClasses(String schoolId) async =>
      const [];

  @override
  Future<AuthRegistrationResult> register(
    AuthRegistrationPayload payload,
  ) async => const AuthRegistrationResult(userId: '1', status: 'approved');

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
  Future<void> deleteAccount({required String currentPassword}) async {}

  @override
  Future<SessionUser> deleteAvatar() async => _teacher;

  @override
  Future<SessionUser> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async => _teacher;

  @override
  Future<SessionUser> updateProfile({
    required String fullName,
    String? phone,
  }) async => _teacher;

  @override
  Future<SessionUser> uploadAvatar({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) async => _teacher;
}

const _teacher = SessionUser(
  id: '1',
  fullName: 'Guru Test',
  email: 'guru@example.test',
  role: UserRole.teacher,
  status: 'approved',
);

void main() {
  testWidgets(
    'teacher logout footer stays visible and cancel does not logout',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = FakeAuthRepository();
      await _pump(tester, repository, textScale: 2);

      await tester.tap(find.byKey(const Key('teacherMenuButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('teacherLogoutButton')), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byKey(const Key('teacherLogoutButton'))).dy,
        lessThanOrEqualTo(568),
      );

      await tester.tap(find.byKey(const Key('teacherLogoutButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(repository.logoutCalls, 0);
    },
  );

  testWidgets('teacher logout confirmation calls repository once', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pump(tester, repository);

    await tester.tap(find.byKey(const Key('teacherMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('teacherLogoutButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('teacherLogoutConfirmButton')));
    await tester.pumpAndSettle();

    expect(repository.logoutCalls, 1);
  });
}

Future<void> _pump(
  WidgetTester tester,
  FakeAuthRepository repository, {
  double textScale = 1,
}) async {
  final router = GoRouter(
    initialLocation: '/teacher/dashboard',
    routes: [
      GoRoute(
        path: '/teacher/dashboard',
        builder: (_, _) =>
            const TeacherShell(title: 'Beranda', child: SizedBox()),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
