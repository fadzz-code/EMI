import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/session_user.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
    DioErrorMapper errorMapper = const DioErrorMapper(),
  }) : _remoteDataSource = remoteDataSource,
       _tokenStorage = tokenStorage,
       _errorMapper = errorMapper;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;
  final DioErrorMapper _errorMapper;

  @override
  Future<SessionUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      _validateUser(result.user);
      await _tokenStorage.saveAccessToken(result.token);
      return result.user;
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<SessionUser?> restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final user = await _remoteDataSource.currentUser();
      _validateUser(user);
      return user;
    } catch (error) {
      await _tokenStorage.clearSession();
      throw _map(error);
    }
  }

  @override
  Future<SessionUser> currentUser() async {
    try {
      final user = await _remoteDataSource.currentUser();
      _validateUser(user);
      return user;
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<SessionUser> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    try {
      final user = await _remoteDataSource.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      _validateUser(user);
      return user;
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<SessionUser> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final user = await _remoteDataSource.updatePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _validateUser(user);
      return user;
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<SessionUser> uploadAvatar({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final user = await _remoteDataSource.uploadAvatar(
        path: path,
        fileName: fileName,
        onSendProgress: onSendProgress,
      );
      _validateUser(user);
      return user;
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<SessionUser> deleteAvatar() async {
    try {
      final user = await _remoteDataSource.deleteAvatar();
      _validateUser(user);
      return user;
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
    } finally {
      await _tokenStorage.clearSession();
    }
  }

  void _validateUser(SessionUser user) {
    if (!user.isApproved) {
      throw const AppError(
        type: AppErrorType.forbidden,
        message: 'Akun belum aktif. Silakan tunggu persetujuan Admin.',
      );
    }
  }

  Object _map(Object error) {
    if (error is AppError) return error;
    return _errorMapper.map(error);
  }
}
