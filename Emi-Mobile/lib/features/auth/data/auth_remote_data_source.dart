import 'package:dio/dio.dart';

import '../../../shared/models/api_response.dart';
import '../domain/session_user.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

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
      (value) => value as Map<String, dynamic>,
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
      (value) => value as Map<String, dynamic>,
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
      (value) => value as Map<String, dynamic>,
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
      (value) => value as Map<String, dynamic>,
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
      (value) => value as Map<String, dynamic>,
    );
    final data = payload.data;
    if (data == null) throw StateError('Response profil tidak lengkap.');
    return SessionUser.fromJson(data);
  }

  Future<SessionUser> deleteAvatar() async {
    final response = await _dio.delete<Map<String, dynamic>>('/auth/me/avatar');
    final payload = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data ?? {},
      (value) => value as Map<String, dynamic>,
    );
    final data = payload.data;
    if (data == null) throw StateError('Response profil tidak lengkap.');
    return SessionUser.fromJson(data);
  }

  Future<void> logout() async {
    await _dio.post<Map<String, dynamic>>('/auth/logout');
  }
}
