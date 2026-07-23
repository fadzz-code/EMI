import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_app_helper.dart';
import 'e2e_config.dart';

class E2eAuthHelper {
  E2eAuthHelper(this.app);

  final E2eAppHelper app;

  Future<void> ensureLoggedOut() async {
    await app.pumpUntilAny([
      find.byKey(const Key('emailField')).hitTestable(),
      find.byKey(const Key('adminMenuButton')).hitTestable(),
      find.byKey(const Key('teacherMenuButton')).hitTestable(),
      find.byKey(const Key('studentMenuButton')).hitTestable(),
    ]);
    if (find
        .byKey(const Key('emailField'))
        .hitTestable()
        .evaluate()
        .isNotEmpty) {
      return;
    }
    if (find
        .byKey(const Key('adminMenuButton'))
        .hitTestable()
        .evaluate()
        .isNotEmpty) {
      await _openAndLogout(
        const Key('adminMenuButton'),
        const Key('adminLogoutButton'),
      );
      return;
    }
    if (find
        .byKey(const Key('teacherMenuButton'))
        .hitTestable()
        .evaluate()
        .isNotEmpty) {
      await _openAndLogout(
        const Key('teacherMenuButton'),
        const Key('teacherLogoutButton'),
      );
      return;
    }
    if (find
        .byKey(const Key('studentMenuButton'))
        .hitTestable()
        .evaluate()
        .isNotEmpty) {
      app.router().go('/student/profile');
      await app.tester.pump();
      await app.waitForLoadingToFinish();
      if (find.text('Logout').evaluate().isNotEmpty) {
        await app.tapAndWait(
          find.text('Logout'),
          expected: find.byKey(const Key('emailField')),
        );
      } else {
        await app.clearSessionSafely();
      }
      return;
    }
    app.router().go('/login');
    await app.tester.pump();
    await app.pumpUntilFound(find.byKey(const Key('emailField')));
  }

  Future<void> loginAsAdmin() =>
      _login(E2eConfig.adminEmail, E2eConfig.adminPassword, expectAdminHome);

  Future<void> loginAsTeacher() => _login(
    E2eConfig.teacherEmail,
    E2eConfig.teacherPassword,
    expectTeacherHome,
  );

  Future<void> loginAsStudent() => _login(
    E2eConfig.studentEmail,
    E2eConfig.studentPassword,
    expectStudentHome,
  );

  Future<void> logout() => ensureLoggedOut();

  Future<void> expectAdminHome() async {
    await app.pumpUntilFound(find.byKey(const Key('adminMenuButton')));
    expect(find.byKey(const Key('teacherMenuButton')), findsNothing);
    expect(find.byKey(const Key('studentMenuButton')), findsNothing);
  }

  Future<void> expectTeacherHome() async {
    await app.pumpUntilFound(find.byKey(const Key('teacherMenuButton')));
    expect(find.byKey(const Key('adminMenuButton')), findsNothing);
    expect(find.byKey(const Key('studentMenuButton')), findsNothing);
  }

  Future<void> expectStudentHome() async {
    await app.pumpUntilFound(find.byKey(const Key('studentMenuButton')));
    expect(find.byKey(const Key('adminMenuButton')), findsNothing);
    expect(find.byKey(const Key('teacherMenuButton')), findsNothing);
  }

  Future<void> _login(
    String email,
    String password,
    Future<void> Function() expectHome,
  ) async {
    await ensureLoggedOut();
    await app.enterTextSafely(find.byKey(const Key('emailField')), email);
    await app.enterTextSafely(find.byKey(const Key('passwordField')), password);
    await app.closeKeyboard();
    await app.tapAndWait(find.byKey(const Key('loginButton')));
    await expectHome();
  }

  Future<void> _openAndLogout(Key menuKey, Key logoutKey) async {
    await app.tapAndWait(find.byKey(menuKey));
    await app.tapAndWait(
      find.byKey(logoutKey),
      expected: find.byKey(const Key('emailField')),
    );
  }
}
