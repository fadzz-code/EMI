import 'package:dio/dio.dart';

import '../../../shared/models/api_response.dart';
import '../domain/auth_repository.dart';
import '../domain/session_user.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PublicSchoolOption>> listPublicSchools() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/public/schools',
      queryParameters: {'per_page': 100},
    );
    final payload = ApiResponse<List<PublicSchoolOption>>.fromJson(
      response.data ?? {},
      (value) => _requiredList(value, PublicSchoolOption.fromJson),
    );
    return payload.data ?? const [];
  }

  Future<List<PublicClassOption>> listPublicClasses(String schoolId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/public/schools/$schoolId/classes',
      queryParameters: {'per_page': 100},
    );
    final payload = ApiResponse<List<PublicClassOption>>.fromJson(
      response.data ?? {},
      (value) => _requiredList(value, PublicClassOption.fromJson),
    );
    return payload.data ?? const [];
  }

  Future<AuthRegistrationResult> register(
    AuthRegistrationPayload payload,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'full_name': payload.fullName,
        'email': payload.email,
        'password': payload.password,
        'password_confirmation': payload.passwordConfirmation,
        'requested_role': payload.requestedRole.value,
        'school_id': payload.schoolId,
        'class_id': payload.classId,
      },
    );
    final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data ?? {},
      _requiredMap,
    );
    final data = envelope.data;
    if (data == null) throw StateError('Response registrasi tidak lengkap.');
    return AuthRegistrationResult(
      userId: data['user_id'] as String? ?? '',
      status: data['status'] as String? ?? '',
    );
  }

  Future<({String token, SessionUser user})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'device_name': 'emi-flutter-android',
      },
    );
    final payload = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data ?? {},
      _requiredMap,
    );
    final data = payload.data ?? {};
    final token = data['token'] as String? ?? '';
    final userJson = data['user'];

    if (token.isEmpty || userJson is! Map<String, dynamic>) {
      throw StateError('Response login tidak lengkap.');
    }

    return (token: token, user: SessionUser.fromJson(userJson));
  }

  Future<SessionUser> currentUser() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    final payload = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data ?? {},
      _requiredMap,
    );
    final data = payload.data;
    if (data == null) throw StateError('Response profil tidak lengkap.');
    return SessionUser.fromJson(data);
  }

  Future<SessionUser> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/me',
      data: {'full_name': fullName, 'phone': phone},
    );
    final payload = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data ?? {},
      _requiredMap,
    );
    final data = payload.data;
    if (data == null) throw StateError('Response profil tidak lengkap.');
    return SessionUser.fromJson(data);
  }

  Future<SessionUser> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/auth/password',
      data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    final payload = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data ?? {},
      _requiredMap,
    );
    final data = payload.data;
    if (data == null) throw StateError('Response profil tidak lengkap.');
    return SessionUser.fromJson(data);
  }

  Future<SessionUser> uploadAvatar({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/me/avatar',
      data: FormData.fromMap({
        'avatar': await MultipartFile.fromFile(path, filename: fileName),
      }),
      onSendProgress: onSendProgress,
    );
    final payload = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data ?? {},
      _requiredMap,
    );
    final data = payload.data;
    if (data == null) throw StateError('Response profil tidak lengkap.');
    return SessionUser.fromJson(data);
  }

  Future<SessionUser> deleteAvatar() async {
    final response = await _dio.delete<Map<String, dynamic>>('/auth/me/avatar');
    final payload = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data ?? {},
      _requiredMap,
    );
    final data = payload.data;
    if (data == null) throw StateError('Response profil tidak lengkap.');
    return SessionUser.fromJson(data);
  }

  Future<void> deleteAccount({required String currentPassword}) async {
    await _dio.delete<Map<String, dynamic>>(
      '/auth/account',
      data: {'current_password': currentPassword},
    );
  }

  Future<void> logout() async {
    await _dio.post<Map<String, dynamic>>('/auth/logout');
  }
}

Map<String, dynamic> _requiredMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw StateError('Response autentikasi tidak lengkap.');
}

List<T> _requiredList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) throw StateError('Response daftar tidak lengkap.');
  return value.whereType<Map<String, dynamic>>().map(fromJson).where((item) {
    if (item is PublicSchoolOption) return item.id.isNotEmpty;
    if (item is PublicClassOption) return item.id.isNotEmpty;
    return true;
  }).toList();
}
