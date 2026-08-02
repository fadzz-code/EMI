import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/teacher/data/teacher_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'teacher dashboard uses real summary endpoint and parses nullable values',
    () async {
      final requests = <String>[];
      final repository = TeacherRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests.add('${options.method} ${options.path}');
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': {
                        'class': {
                          'id': 'class-1',
                          'name': 'Kelas 1',
                          'school': {'name': 'Sekolah'},
                        },
                        'empty_state': false,
                        'students': {
                          'active': 2,
                          'with_learning_activity': 1,
                          'completed_all_modules': 0,
                        },
                        'learning': {
                          'published_modules': 3,
                          'published_lessons': 4,
                          'average_progress_percent': 50,
                        },
                        'quizzes': {
                          'published_quizzes': 1,
                          'average_score_percent': 90,
                        },
                        'recent_activity': [
                          {'title': 'Selesai kuis', 'student_name': 'Siswa'},
                        ],
                      },
                    },
                  ),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      final summary = await repository.dashboard();

      expect(summary.className, 'Kelas 1');
      expect(summary.schoolName, 'Sekolah');
      expect(
        summary.metrics.map((item) => item.label),
        containsAll(['Kelas', 'Siswa Aktif', 'Modul Terbit', 'Progress']),
      );
      expect(
        summary.metrics.map((item) => item.value),
        isNot(contains('with_learning_activity')),
      );
      expect(requests, ['GET /teacher/dashboard/summary']);
    },
  );

  test(
    'request lists use backend pagination, search, and status contract',
    () async {
      final requests = <RequestOptions>[];
      final repository = TeacherRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests.add(options);
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': [
                        {
                          'id': 'request-1',
                          'status': 'approved',
                          'user': {
                            'full_name': 'Sari',
                            'email': 'sari@example.test',
                          },
                        },
                      ],
                      'meta': {'current_page': 2, 'last_page': 3, 'total': 31},
                    },
                  ),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      final registrations = await repository.registrationRequests(
        page: 2,
        search: ' Sari ',
        status: 'approved',
      );
      final resets = await repository.passwordResetRequests(
        page: 2,
        search: ' Sari ',
        status: 'rejected',
      );

      expect(registrations.items.single.name, 'Sari');
      expect(registrations.lastPage, 3);
      expect(resets.total, 31);
      expect(requests[0].queryParameters, {
        'page': 2,
        'per_page': 15,
        'status': 'approved',
        'sort_by': 'created_at',
        'sort_order': 'desc',
        'search': 'Sari',
      });
      expect(requests[1].queryParameters, {
        'page': 2,
        'per_page': 15,
        'status': 'rejected',
        'sort_by': 'created_at',
        'sort_direction': 'desc',
        'search': 'Sari',
      });
    },
  );

  test(
    'registration approval sends optional review note only when present',
    () async {
      final requests = <RequestOptions>[];
      final repository = TeacherRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests.add(options);
                handler.resolve(
                  Response(requestOptions: options, data: {'data': {}}),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      await repository.approveRegistrationRequest('one');
      await repository.approveRegistrationRequest('two', reviewNote: ' Baik ');

      expect(requests[0].data, isEmpty);
      expect(requests[1].data, {'review_note': 'Baik'});
    },
  );

  test('teacher dashboard unauthorized maps backend error', () async {
    final repository = TeacherRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'Unauthenticated.'},
                ),
              ),
            ),
          ),
        ),
      const DioErrorMapper(),
    );

    expect(repository.dashboard(), throwsA(isA<AppError>()));
  });
}
