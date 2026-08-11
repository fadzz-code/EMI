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
        status: AuthStatus.sessionExpired,
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
      final appError = _asAppError(error);
      state = AuthState(status: _statusForError(appError), error: appError);
    }
  }

  Future<AuthRegistrationResult> register(
    AuthRegistrationPayload payload,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.register(payload);
      state = const AuthState(status: AuthStatus.pendingApproval);
      return result;
    } catch (error) {
      final appError = _asAppError(error);
      state = AuthState(status: AuthStatus.unauthenticated, error: appError);
      rethrow;
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
      await _repository.updatePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = _stateForUser(await _repository.currentUser());
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

  Future<void> deleteAccount({required String currentPassword}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.deleteAccount(currentPassword: currentPassword);
      state = const AuthState.unauthenticated();
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _asAppError(error));
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      state = const AuthState.unauthenticated();
    }
  }

  void invalidateSession() {
    state = const AuthState(status: AuthStatus.sessionExpired);
  }

  AuthState _stateForUser(SessionUser user) {
    if (user.status == 'pending') {
      return AuthState(status: AuthStatus.pendingApproval, user: user);
    }
    if (user.status == 'rejected') {
      return AuthState(status: AuthStatus.registrationRejected, user: user);
    }
    if (user.status == 'inactive' || user.status == 'disabled') {
      return AuthState(status: AuthStatus.accountDisabled, user: user);
    }
    if (!user.isApproved) {
      return AuthState(status: AuthStatus.forbidden, user: user);
    }

    return switch (user.role) {
      UserRole.admin => AuthState(
        status: AuthStatus.authenticatedAdmin,
        user: user,
      ),
      UserRole.teacher => AuthState(
        status: AuthStatus.authenticatedTeacher,
        user: user,
      ),
      UserRole.student => AuthState(
        status: AuthStatus.authenticatedStudent,
        user: user,
      ),
      UserRole.unknown => AuthState(
        status: AuthStatus.unsupportedRole,
        user: user,
      ),
    };
  }

  AuthStatus _statusForError(AppError error) {
    if (error.type == AppErrorType.unauthorized) {
      return AuthStatus.sessionExpired;
    }
    if (error.type != AppErrorType.forbidden) return AuthStatus.unauthenticated;
    if (error.message.toLowerCase().contains('ditolak')) {
      return AuthStatus.registrationRejected;
    }
    if (error.message.toLowerCase().contains('dinonaktifkan')) {
      return AuthStatus.accountDisabled;
    }
    if (error.message.toLowerCase().contains('menunggu')) {
      return AuthStatus.pendingApproval;
    }
    return AuthStatus.forbidden;
  }

  AppError _asAppError(Object error) {
    if (error is AppError) return error;
    return const AppError(
      type: AppErrorType.unknown,
      message: 'Terjadi kesalahan. Silakan coba lagi.',
    );
  }
}
