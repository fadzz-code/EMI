import '../../../core/errors/app_error.dart';
import '../domain/session_user.dart';

enum AuthStatus { unknown, unauthenticated, authenticated, unsupportedRole }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.isLoading = false,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown, isLoading: true);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final SessionUser? user;
  final AppError? error;
  final bool isLoading;

  AuthState copyWith({
    AuthStatus? status,
    SessionUser? user,
    AppError? error,
    bool? isLoading,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
