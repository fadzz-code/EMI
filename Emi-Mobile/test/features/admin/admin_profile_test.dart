import 'package:emi_mobile/features/admin/presentation/admin_profile_screen.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('admin profile uses AdminShell context and role-aware actions', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/admin/profile',
      routes: [
        GoRoute(
          path: '/admin/profile',
          builder: (_, _) => const AdminProfileScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith((_) => _FakeAuth())],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminScreen-profile')), findsOneWidget);
    expect(find.text('Profil Admin'), findsOneWidget);
    expect(find.text('Peran: Admin'), findsOneWidget);
    expect(find.byKey(const Key('adminEditProfile')), findsOneWidget);
    expect(find.byKey(const Key('adminChangePassword')), findsOneWidget);
    expect(find.byKey(const Key('adminLogout')), findsOneWidget);
  });
}

class _FakeAuth extends StateNotifier<AuthState> implements AuthController {
  _FakeAuth()
    : super(
        const AuthState(
          status: AuthStatus.authenticatedAdmin,
          user: SessionUser(
            id: 'admin',
            email: 'admin@test',
            fullName: 'Admin EMI',
            role: UserRole.admin,
            status: 'approved',
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
