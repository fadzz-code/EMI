import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/storage/token_storage.dart';
import 'package:emi_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:emi_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token;
  var cleared = false;

  @override
  Future<void> clearSession() async {
    token = null;
    cleared = true;
  }

  @override
  Future<void> deleteAccessToken() async => token = null;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;
}

void main() {
  test('login response parsing stores token for approved admin', () async {
    final storage = _MemoryTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(
        _dio((options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {
                  'token': 'safe-test-token',
                  'user': _user(role: 'admin'),
                },
              },
            ),
          );
        }),
      ),
      tokenStorage: storage,
    );

    final user = await repository.login(
      email: 'admin@test',
      password: 'secret',
    );

    expect(user.role, UserRole.admin);
    expect(storage.token, 'safe-test-token');
  });

  test('login response parsing stores token for approved student', () async {
    final storage = _MemoryTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(
        _dio((options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {'token': 'safe-test-token', 'user': _user()},
              },
            ),
          );
        }),
      ),
      tokenStorage: storage,
    );

    final user = await repository.login(
      email: 'siswa@test',
      password: 'secret',
    );

    expect(user.role, UserRole.student);
    expect(storage.token, 'safe-test-token');
  });

  test('login response parsing stores token for approved teacher', () async {
    final storage = _MemoryTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(
        _dio((options, handler) {
          expect(options.path, '/auth/login');
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {
                  'token': 'safe-test-token',
                  'user': _user(role: 'teacher'),
                },
              },
            ),
          );
        }),
      ),
      tokenStorage: storage,
    );

    final user = await repository.login(email: 'guru@test', password: 'secret');

    expect(user.role, UserRole.teacher);
    expect(storage.token, 'safe-test-token');
  });

  test('disabled account is blocked and token is not stored', () async {
    final storage = _MemoryTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(
        _dio((options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {
                  'token': 'safe-test-token',
                  'user': _user(status: 'disabled'),
                },
              },
            ),
          );
        }),
      ),
      tokenStorage: storage,
    );

    await expectLater(
      repository.login(email: 'x', password: 'x'),
      throwsA(isA<AppError>()),
    );
    expect(storage.token, isNull);
  });

  test('nullable login response is rejected', () async {
    final repository = AuthRemoteDataSource(
      _dio((options, handler) {
        handler.resolve(
          Response(requestOptions: options, data: {'data': null}),
        );
      }),
    );

    await expectLater(
      repository.login(email: 'x', password: 'x'),
      throwsA(isA<StateError>()),
    );
  });

  test('restore session clears token after expired session', () async {
    final storage = _MemoryTokenStorage()..token = 'expired-token';
    final repository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(
        _dio((options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'message': 'Unauthenticated.'},
              ),
            ),
          );
        }),
      ),
      tokenStorage: storage,
    );

    await expectLater(repository.restoreSession(), throwsA(isA<AppError>()));
    expect(storage.cleared, isTrue);
  });

  test('register returns pending result and does not store token', () async {
    final storage = _MemoryTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(
        _dio((options, handler) {
          expect(options.path, '/auth/register');
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {'user_id': 'user-1', 'status': 'pending'},
              },
            ),
          );
        }),
      ),
      tokenStorage: storage,
    );

    final result = await repository.register(
      const AuthRegistrationPayload(
        fullName: 'Siswa Test',
        email: 'siswa@test',
        password: 'Password1',
        passwordConfirmation: 'Password1',
        requestedRole: UserRole.student,
        schoolId: 'school-1',
        classId: 'class-1',
      ),
    );

    expect(result.status, 'pending');
    expect(storage.token, isNull);
  });

  test('session user parses unknown role safely', () {
    final user = SessionUser.fromJson(_user(role: 'owner'));

    expect(user.role, UserRole.unknown);
  });
}

Dio _dio(void Function(RequestOptions, RequestInterceptorHandler) onRequest) =>
    Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..interceptors.add(InterceptorsWrapper(onRequest: onRequest));

Map<String, dynamic> _user({
  String role = 'student',
  String status = 'approved',
}) => {
  'id': '1',
  'full_name': 'User Test',
  'email': 'user@test',
  'role': role,
  'status': status,
};
