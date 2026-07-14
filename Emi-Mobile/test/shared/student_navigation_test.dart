import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/shared/widgets/emi_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
  testWidgets('hamburger opens drawer and back closes it', (tester) async {
    final router = _router('/student/dashboard');
    await _pump(tester, router);

    await tester.tap(find.byKey(const Key('studentMenuButton')));
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Modul'), findsWidgets);
    expect(find.text('Kamus'), findsWidgets);
    expect(find.text('Kuis'), findsWidgets);
    expect(find.text('Progress Belajar'), findsOneWidget);
    expect(find.text('Chatbot'), findsOneWidget);
    expect(find.text('Budaya Mekongga'), findsOneWidget);
    expect(find.text('Speaking'), findsOneWidget);
    expect(find.text('Profil'), findsWidgets);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Progress Belajar'), findsNothing);
  });

  testWidgets('sidebar navigates and avoids duplicate current route', (
    tester,
  ) async {
    final router = _router('/student/chatbot');
    await _pump(tester, router);

    await tester.tap(find.byKey(const Key('studentMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budaya Mekongga'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/student/culture');

    await tester.tap(find.byKey(const Key('studentMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budaya Mekongga'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/student/culture');
  });

  testWidgets('bottom navigation remains five student items', (tester) async {
    final router = _router('/student/dashboard');
    await _pump(tester, router);

    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Modul'), findsOneWidget);
    expect(find.text('Kamus'), findsOneWidget);
    expect(find.text('Kuis'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Progress Belajar'), findsNothing);
    expect(find.text('Chatbot'), findsNothing);
    expect(find.text('Budaya Mekongga'), findsNothing);
  });
}

GoRouter _router(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/student/dashboard',
        builder: (_, _) => _page('Beranda', 0),
      ),
      GoRoute(path: '/student/modules', builder: (_, _) => _page('Modul', 1)),
      GoRoute(
        path: '/student/dictionary',
        builder: (_, _) => _page('Kamus', 2),
      ),
      GoRoute(path: '/student/quizzes', builder: (_, _) => _page('Kuis', 3)),
      GoRoute(path: '/student/profile', builder: (_, _) => _page('Profil', 4)),
      GoRoute(
        path: '/student/progress',
        builder: (_, _) => _page('Progress', null),
      ),
      GoRoute(
        path: '/student/chatbot',
        builder: (_, _) => _page('Chatbot', null),
      ),
      GoRoute(
        path: '/student/culture',
        builder: (_, _) => _page('Budaya', null),
      ),
      GoRoute(
        path: '/student/speaking',
        builder: (_, _) => _page('Speaking', null),
      ),
    ],
  );
}

Widget _page(String title, int? index) {
  return EmiScaffold(
    title: title,
    currentIndex: index,
    onNavTap: (_) {},
    child: Center(child: Text('$title page')),
  );
}

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}
