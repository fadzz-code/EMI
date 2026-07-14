import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknown role can be represented safely', () {
    final user = SessionUser.fromJson({
      'id': '1',
      'full_name': 'User',
      'email': 'user@example.test',
      'role': 'operator',
      'status': 'approved',
    });

    expect(user.role, UserRole.unknown);
  });

  test('admin role is supported by mobile auth state', () {
    const user = SessionUser(
      id: '1',
      fullName: 'Admin',
      email: 'admin@example.test',
      role: UserRole.admin,
      status: 'approved',
    );

    const state = AuthState(status: AuthStatus.authenticatedAdmin, user: user);
    expect(state.user?.role, UserRole.admin);
  });

  test('teacher role is supported by mobile auth state', () {
    const user = SessionUser(
      id: '1',
      fullName: 'Guru',
      email: 'guru@example.test',
      role: UserRole.teacher,
      status: 'approved',
    );

    const state = AuthState(
      status: AuthStatus.authenticatedTeacher,
      user: user,
    );
    expect(state.user?.role, UserRole.teacher);
  });
}
