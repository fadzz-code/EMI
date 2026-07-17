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
