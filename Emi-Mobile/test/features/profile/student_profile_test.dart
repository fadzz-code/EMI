import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:emi_mobile/features/profile/presentation/student_profile_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'shared profile localizes role and status and permanent deletion copy',
    (tester) async {
      await _pumpProfile(tester);

      expect(find.text('Guru'), findsOneWidget);
      expect(find.text('Menunggu persetujuan'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Hapus Akun'), 300);
      expect(find.text('Hapus Akun'), findsOneWidget);
      expect(find.text('Nonaktifkan Akun'), findsNothing);
    },
  );

  testWidgets('profile dialogs scroll safely on narrow scaled screens', (
    tester,
  ) async {
    await _pumpProfile(tester, textScale: 2);

    for (final label in ['Edit Profil', 'Ganti Password', 'Hapus Akun']) {
      await tester.scrollUntilVisible(find.text(label), 300);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('account deletion cancel makes no call', (tester) async {
    final auth = await _pumpProfile(tester);
    await tester.scrollUntilVisible(find.text('Hapus Akun'), 300);
    await tester.tap(find.text('Hapus Akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(auth.deleteCalls, 0);
  });

  testWidgets('account deletion passes password and blocks double submit', (
    tester,
  ) async {
    final auth = await _pumpProfile(tester);
    await tester.scrollUntilVisible(find.text('Hapus Akun'), 300);
    await tester.tap(find.text('Hapus Akun'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'rahasia');
    await tester.tap(find.text('Hapus Permanen'));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Hapus Akun'),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(auth.deleteCalls, 1);
    expect(auth.password, 'rahasia');
    auth.completeDelete();
    await tester.pumpAndSettle();
  });
}

Future<_FakeAuth> _pumpProfile(
  WidgetTester tester, {
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 568));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/student/profile',
    routes: [
      GoRoute(
        path: '/student/profile',
        builder: (_, _) => const StudentProfileScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  final auth = _FakeAuth();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith((_) => auth)],
      child: MaterialApp.router(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

class _FakeAuth extends StateNotifier<AuthState> implements AuthController {
  _FakeAuth()
    : super(
        const AuthState(
          status: AuthStatus.authenticatedTeacher,
          user: SessionUser(
            id: 'teacher',
            email: 'guru@test',
            fullName: 'Guru EMI',
            role: UserRole.teacher,
            status: 'pending',
          ),
        ),
      );

  int deleteCalls = 0;
  String? password;
  Completer<void>? _deleteCompleter;

  @override
  Future<void> deleteAccount({required String currentPassword}) {
    deleteCalls++;
    password = currentPassword;
    state = state.copyWith(isLoading: true);
    _deleteCompleter = Completer<void>();
    return _deleteCompleter!.future;
  }

  void completeDelete() {
    state = const AuthState.unauthenticated();
    _deleteCompleter?.complete();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
