import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../data/auth_providers.dart';
import '../domain/auth_repository.dart';
import '../domain/session_user.dart';
import 'auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.unknown());

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.restoreSession();
      if (user == null) {
        state = const AuthState.unauthenticated();
        return;
      }
      state = _stateForUser(user);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _asAppError(error),
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(email: email, password: password);
      state = _stateForUser(user);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _asAppError(error),
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }

  AuthState _stateForUser(SessionUser user) {
    if (user.role == UserRole.student) {
      return AuthState(status: AuthStatus.authenticated, user: user);
    }
    return AuthState(status: AuthStatus.unsupportedRole, user: user);
  }

  AppError _asAppError(Object error) {
    if (error is AppError) return error;
    return const AppError(
      type: AppErrorType.unknown,
      message: 'Terjadi kesalahan. Silakan coba lagi.',
    );
  }
}
