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
  Future<List<PublicSchoolOption>> listPublicSchools() async {
    try {
      return await _remoteDataSource.listPublicSchools();
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<List<PublicClassOption>> listPublicClasses(String schoolId) async {
    try {
      return await _remoteDataSource.listPublicClasses(schoolId);
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<AuthRegistrationResult> register(
    AuthRegistrationPayload payload,
  ) async {
    try {
      return await _remoteDataSource.register(payload);
    } catch (error) {
      throw _map(error);
    }
  }

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
      await _tokenStorage.saveSessionUser(result.user);
      return result.user;
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _remoteDataSource.forgotPassword(email: email);
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        email: email,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
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
      await _tokenStorage.saveSessionUser(user);
      return user;
    } catch (error) {
      final mapped = _map(error);
      if (mapped is AppError && mapped.type == AppErrorType.unauthorized) {
        await _tokenStorage.clearSession();
        throw mapped;
      }
      if (mapped is AppError &&
          (mapped.type == AppErrorType.networkUnavailable ||
              mapped.type == AppErrorType.timeout ||
              mapped.type == AppErrorType.server)) {
        final cached = await _tokenStorage.readSessionUser();
        if (cached != null) return cached;
      }
      throw mapped;
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
  Future<void> deleteAccount({required String currentPassword}) async {
    try {
      await _remoteDataSource.deleteAccount(currentPassword: currentPassword);
      await _tokenStorage.clearSession();
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
    if (user.isApproved) return;

    final message = switch (user.status) {
      'pending' => 'Akun sedang menunggu persetujuan Admin.',
      'rejected' => 'Registrasi akun ditolak. Hubungi Admin EMI.',
      'inactive' || 'disabled' => 'Akun dinonaktifkan. Hubungi Admin EMI.',
      _ => 'Akun belum aktif. Silakan tunggu persetujuan Admin.',
    };
    throw AppError(type: AppErrorType.forbidden, message: message);
  }

  Object _map(Object error) {
    if (error is AppError) return error;
    return _errorMapper.map(error);
  }
}
