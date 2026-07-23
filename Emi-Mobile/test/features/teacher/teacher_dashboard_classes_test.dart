import 'dart:io';

import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/teacher/data/teacher_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<RequestOptions> requests;
  late TeacherRepository repository;

  setUp(() {
    requests = [];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final path = options.path;
          final data = switch (path) {
            '/teacher/dashboard/summary' => {
              'data': {
                'class': {
                  'id': 'class-1',
                  'name': 'Kelas 7A',
                  'school': {'name': 'SMP EMI'},
                },
                'empty_state': false,
                'students': {'active': 12},
                'learning': {
                  'published_modules': 3,
                  'average_progress_percent': 22,
                },
                'quizzes': {'published_quizzes': 2},
                'recent_activity': [
                  {
                    'type': 'quiz_submitted',
                    'student_name': 'Dian Lestari',
                    'title': 'Kuis Sapaan Dasar',
                  },
                ],
              },
            },
            '/classes' => {
              'data': [
                {
                  'id': 'class-1',
                  'name': 'Kelas 7A',
                  'status': 'active',
                  'active_students_count': 12,
                  'school': {'name': 'SMP EMI'},
                },
              ],
              'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
            },
            '/classes/class-1' => {
              'data': {
                'id': 'class-1',
                'name': 'Kelas 7A',
                'status': 'active',
                'grade_level': '7',
                'academic_year': '2026/2027',
              },
            },
            '/classes/class-1/students' => {
              'data': [
                {
                  'student': {
                    'id': 'student-1',
                    'full_name': 'Ayu',
                    'email': 'ayu@example.test',
                    'status': 'approved',
                  },
                },
              ],
            },
            '/teacher/reports/progress/students' => {
              'data': [
                {
                  'student_id': 'student-1',
                  'full_name': 'Ayu',
                  'class': {'name': 'Kelas 7A'},
                  'published_modules': 4,
                  'started_modules': 3,
                  'completed_modules': 2,
                  'overall_learning_progress_percent': 50,
                  'published_quizzes': 3,
                  'quizzes_attempted': 2,
                  'quizzes_completed': 1,
                },
              ],
              'meta': {'current_page': 2, 'last_page': 3, 'total': 21},
            },
            _ => <String, dynamic>{},
          };
          handler.resolve(Response(requestOptions: options, data: data));
        },
      ),
    );
    repository = TeacherRepository(dio, const DioErrorMapper());
  });

  test('dashboard uses teacher summary endpoint', () async {
    await repository.dashboard();
    expect(requests.single.path, '/teacher/dashboard/summary');
  });

  test('dashboard parses assigned class', () async {
    final result = await repository.dashboard();
    expect(
      (result.classId, result.className, result.schoolName),
      ('class-1', 'Kelas 7A', 'SMP EMI'),
    );
  });

  test('dashboard derives one active class from existing class', () async {
    final result = await repository.dashboard();
    expect(result.metrics.first.value, '1');
  });

  test('dashboard parses active students', () async {
    final result = await repository.dashboard();
    expect(result.metrics[1].value, '12');
  });

  test('dashboard parses published modules', () async {
    final result = await repository.dashboard();
    expect(result.metrics[2].value, '3');
  });

  test('dashboard parses average progress and recent activity', () async {
    final result = await repository.dashboard();
    expect(result.metrics[3].value, '2');
    expect(result.metrics[4].value, '22%');
    expect(
      (result.activities.single.studentName, result.activities.single.type),
      ('Dian Lestari', 'quiz_submitted'),
    );
  });

  test('dashboard safely handles missing class', () {
    final result = TeacherDashboardSummary.fromJson({
      'class': null,
      'empty_state': true,
    });
    expect((result.metrics.first.value, result.classId), ('0', null));
  });

  test('dashboard safely defaults missing metrics to zero', () {
    final result = TeacherDashboardSummary.fromJson(const {});
    expect(result.metrics.map((item) => item.value), [
      '0',
      '0',
      '0',
      '0',
      '0%',
    ]);
  });

  test('classes uses classes endpoint', () async {
    await repository.classes();
    expect(requests.single.path, '/classes');
  });

  test('classes sends supported page and search', () async {
    await repository.classes(page: 2, search: ' 7A ');
    expect(requests.single.queryParameters, {
      'page': 2,
      'per_page': 10,
      'sort_by': 'name',
      'sort_direction': 'asc',
      'search': '7A',
    });
  });

  test('classes parses pagination', () async {
    final result = await repository.classes();
    expect((result.currentPage, result.lastPage, result.total), (1, 1, 1));
  });

  test('classes parses typed class', () async {
    final result = await repository.classes();
    expect(
      (result.items.single.name, result.items.single.studentsCount),
      ('Kelas 7A', 12),
    );
  });

  test('class detail uses id endpoint', () async {
    await repository.classDetail('class-1');
    expect(requests.single.path, '/classes/class-1');
  });

  test('class detail parses friendly optional fields', () async {
    final result = await repository.classDetail('class-1');
    expect((result.gradeLevel, result.academicYear), ('7', '2026/2027'));
  });

  test('class students uses nested endpoint', () async {
    await repository.classStudents('class-1');
    expect(requests.single.path, '/classes/class-1/students');
  });

  test('class students sends audited fixed query', () async {
    await repository.classStudents('class-1');
    expect(requests.single.queryParameters, {
      'page': 1,
      'per_page': 100,
      'sort_by': 'full_name',
      'sort_direction': 'asc',
    });
  });

  test('class students parses name email and status', () async {
    final result = await repository.classStudents('class-1');
    final student = result.items.single;
    expect(
      (student.name, student.email, student.status),
      ('Ayu', 'ayu@example.test', 'approved'),
    );
  });

  test('student progress sends backend-supported query', () async {
    await repository.studentProgress(page: 2, search: ' Ayu ');
    expect(requests.single.queryParameters, {
      'page': 2,
      'per_page': 20,
      'sort_by': 'full_name',
      'sort_direction': 'asc',
      'search': 'Ayu',
    });
  });

  test('student progress sends verified class scope', () async {
    await repository.studentProgress(classId: 'class-1');
    expect(requests.single.queryParameters['class_id'], 'class-1');
    expect(requests.single.queryParameters['per_page'], 20);
  });

  test('student progress parses typed row and pagination meta', () async {
    final result = await repository.studentProgress(page: 2);
    final student = result.items.single;
    expect((result.currentPage, result.lastPage, result.total), (2, 3, 21));
    expect(
      (
        student.name,
        student.startedModules,
        student.publishedQuizzes,
        student.percent,
      ),
      ('Ayu', 3, 3, 50),
    );
  });

  test('student detail sends scoped student id and parses first row', () async {
    final result = await repository.studentDetail('student-1');
    expect(requests.single.queryParameters['student_id'], 'student-1');
    expect(requests.single.queryParameters['per_page'], 1);
    expect(result.studentId, 'student-1');
  });

  test('stage one routes and navigation wiring exist', () {
    final router = File('lib/app/router/app_router.dart').readAsStringSync();
    final shell = File(
      'lib/features/teacher/presentation/teacher_shell.dart',
    ).readAsStringSync();
    final dashboard = File(
      'lib/features/teacher/presentation/teacher_dashboard_screen.dart',
    ).readAsStringSync();
    final classes = File(
      'lib/features/teacher/presentation/teacher_classes_screens.dart',
    ).readAsStringSync();
    expect(router, contains("path: '/teacher/classes'"));
    expect(router, contains("path: '/teacher/students/:id'"));
    expect(router, contains("path: '/teacher/progress'"));
    expect(shell, contains("route: '/teacher/classes'"));
    expect(shell, contains("route: '/teacher/progress'"));
    expect(dashboard, contains("context.go('/teacher/progress')"));
    expect(
      classes,
      contains("context.push('/teacher/students/\${student.id}')"),
    );
  });
}
