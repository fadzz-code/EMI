import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_api_helper.dart';
import 'helpers/e2e_app_helper.dart';
import 'helpers/e2e_auth_helper.dart';
import 'helpers/e2e_config.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Autentikasi role EMI', () {
    late E2eAppHelper app;
    late E2eAuthHelper auth;

    setUpAll(() async {
      E2eConfig.validate();
      const api = E2eApiHelper();
      await api.waitUntilReady();
      await api.verifyDemoAccounts();
    });

    testWidgets('guest diarahkan ke login dari route terlindungi', (
      tester,
    ) async {
      app = E2eAppHelper(tester, binding);
      auth = E2eAuthHelper(app);
      await app.launchApp();
      await auth.ensureLoggedOut();
      expect(find.text('Masuk EMI'), findsOneWidget);
      app.router().go('/admin/dashboard');
      await tester.pump();
      await app.pumpUntilFound(find.byKey(const Key('emailField')));
      expect(find.byKey(const Key('adminMenuButton')), findsNothing);
    });

    testWidgets('Admin login, guard, dan logout', (tester) async {
      app = E2eAppHelper(tester, binding);
      auth = E2eAuthHelper(app);
      await app.launchApp();
      await auth.loginAsAdmin();
      for (final route in ['/teacher/dashboard', '/student/dashboard']) {
        app.router().go(route);
        await tester.pump();
        await auth.expectAdminHome();
      }
      await auth.logout();
      expect(find.text('Masuk EMI'), findsOneWidget);
    });

    testWidgets('Guru login, guard, dan logout', (tester) async {
      app = E2eAppHelper(tester, binding);
      auth = E2eAuthHelper(app);
      await app.launchApp();
      await auth.loginAsTeacher();
      for (final route in ['/admin/dashboard', '/student/dashboard']) {
        app.router().go(route);
        await tester.pump();
        await auth.expectTeacherHome();
      }
      await auth.logout();
      expect(find.text('Masuk EMI'), findsOneWidget);
    });

    testWidgets('Siswa login, guard, dan logout', (tester) async {
      app = E2eAppHelper(tester, binding);
      auth = E2eAuthHelper(app);
      await app.launchApp();
      await auth.loginAsStudent();
      for (final route in ['/admin/dashboard', '/teacher/dashboard']) {
        app.router().go(route);
        await tester.pump();
        await auth.expectStudentHome();
      }
      await auth.logout();
      expect(find.text('Masuk EMI'), findsOneWidget);
    });
  });
}
