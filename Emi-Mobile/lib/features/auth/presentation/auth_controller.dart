import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/network/session_invalidation_provider.dart';
import '../data/auth_providers.dart';
import '../domain/auth_repository.dart';
import '../domain/session_user.dart';
import 'auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final controller = AuthController(ref.watch(authRepositoryProvider));
    ref.listen<int>(sessionInvalidationProvider, (_, _) {
      controller.invalidateSession();
    });
    return controller;
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

  Future<void> updateProfile({required String fullName, String? phone}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      state = _stateForUser(user);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _asAppError(error));
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.updatePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = _stateForUser(user);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _asAppError(error));
    }
  }

  Future<void> uploadAvatar({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.uploadAvatar(
        path: path,
        fileName: fileName,
        onSendProgress: onSendProgress,
      );
      state = _stateForUser(user);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _asAppError(error));
    }
  }

  Future<void> deleteAvatar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.deleteAvatar();
      state = _stateForUser(user);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _asAppError(error));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }

  void invalidateSession() {
    state = const AuthState.unauthenticated();
  }

  AuthState _stateForUser(SessionUser user) {
    if (user.role == UserRole.student || user.role == UserRole.admin) {
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
