import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emi_mobile/features/admin/presentation/admin_screens.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/data/admin_crud_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_crud_repository.dart';
import 'package:emi_mobile/features/admin/data/admin_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin summary maps web dashboard metrics without fake numbers', () {
    final summary = AdminSummary.fromJson({
      'overview': {
        'active_students': 10,
        'active_teachers': 2,
        'active_schools': 1,
        'active_classes': 3,
        'pending_registration_requests': 4,
      },
      'quizzes': {'submitted_attempts': 5},
    });

    expect(
      summary.items.map((item) => item.label),
      contains('Pendaftaran yang Perlu Diperiksa'),
    );
    expect(summary.items.map((item) => item.value), contains('12'));
    expect(
      summary.items.map((item) => item.helper),
      contains('Guru dan Siswa.'),
    );
  });

  test('admin query keeps stable provider identity', () {
    const a = AdminFeatureQuery(
      feature: AdminFeature.users,
      query: AdminListQuery(search: 'emi'),
    );
    const b = AdminFeatureQuery(
      feature: AdminFeature.users,
      query: AdminListQuery(search: 'emi'),
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('admin user query supports search role status pagination', () {
    const query = AdminListQuery(
      search: 'budi',
      role: 'teacher',
      status: 'approved',
      page: 2,
    );

    expect(query.toQuery(), {
      'search': 'budi',
      'role': 'teacher',
      'status': 'approved',
      'page': 2,
      'per_page': 15,
    });
  });

  test('admin school parser and query support status pagination', () {
    const query = AdminListQuery(search: 'kolaka', status: 'active', page: 2);
    final page = AdminSchoolPage.fromJson({
      'data': [
        {
          'id': 's1',
          'name': 'SMP Negeri 1 Kolaka',
          'address': null,
          'phone': null,
          'status': 'active',
          'classes_count': 6,
        },
      ],
      'meta': {'current_page': 2, 'last_page': 3, 'total': 16},
    });

    expect(query.toQuery(), {
      'search': 'kolaka',
      'status': 'active',
      'page': 2,
      'per_page': 15,
    });
    expect(page.hasMore, isTrue);
    expect(page.items.single.address, isNull);
    expect(page.items.single.phone, isNull);
    expect(page.items.single.classesCount, 6);
  });

  test('admin school create update activate deactivate contracts', () async {
    final requests = <String>[];
    final bodies = <Object?>[];
    final repository = AdminRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              bodies.add(options.data);
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'data': {
                      'id': 's1',
                      'name': 'SMP Negeri 1 Kolaka',
                      'address': 'Kolaka',
                      'phone': '0405',
                      'status': 'active',
                      'classes_count': 0,
                    },
                  },
                ),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );

    await repository.saveSchool(
      name: 'SMP Negeri 1 Kolaka',
      address: 'Kolaka',
      phone: '0405',
      status: 'active',
    );
    await repository.saveSchool(
      id: 's1',
      name: 'SMP Negeri 1 Kolaka',
      status: 'active',
    );
    await repository.deactivateSchool('s1');

    expect(requests, [
      'POST /schools',
      'PUT /schools/s1',
      'DELETE /schools/s1',
    ]);
    expect(bodies.first, {
      'name': 'SMP Negeri 1 Kolaka',
      'address': 'Kolaka',
      'phone': '0405',
      'status': 'active',
    });
  });

  test('admin user parser handles nullable school class avatar', () {
    final page = AdminUserPage.fromJson({
      'data': [
        {
          'id': 'u1',
          'full_name': 'Guru Panjang',
          'email': 'guru@example.test',
          'role': 'teacher',
          'status': 'approved',
          'avatar': null,
          'active_school': null,
          'active_class': null,
        },
      ],
      'meta': {'current_page': 1, 'last_page': 2, 'total': 16},
    });

    expect(page.hasMore, isTrue);
    expect(page.items.single.schoolName, isNull);
    expect(page.items.single.className, isNull);
    expect(page.items.single.avatarUrl, isNull);
  });

  test('repository uses real admin and shared endpoints', () async {
    final requests = <String>[];
    final repository = AdminRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              if (options.path == '/admin/dashboard/summary') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': {
                        'overview': {
                          'active_students': 1,
                          'active_teachers': 0,
                          'active_schools': 0,
                          'active_classes': 0,
                          'pending_registration_requests': 0,
                        },
                        'quizzes': {'submitted_attempts': 0},
                      },
                    },
                  ),
                );
                return;
              }
              if (options.path == '/users') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': [
                        {'id': 'u1', 'full_name': 'Admin', 'email': 'a@test'},
                      ],
                      'meta': {'current_page': 1, 'last_page': 1},
                    },
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        ),
      const DioErrorMapper(),
    );

    expect((await repository.dashboard()).items.last.value, '1');
    expect(
      (await repository.list(
        '/users',
        const AdminListQuery(),
      )).items.single.title,
      'Admin',
    );
    expect(requests, contains('GET /admin/dashboard/summary'));
    expect(requests, contains('GET /users'));
  });

  test('admin user update and status calls use allowed fields', () async {
    final requests = <String>[];
    final bodies = <Object?>[];
    final repository = AdminRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              bodies.add(options.data);
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'data': {
                      'id': 'u1',
                      'full_name': 'Budi',
                      'email': 'budi@example.test',
                      'role': 'student',
                      'status': 'inactive',
                    },
                  },
                ),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );

    await repository.updateUser(
      'u1',
      name: 'Budi',
      email: 'budi@example.test',
      phone: '0812',
    );
    await repository.updateUserStatus(
      'u1',
      status: 'inactive',
      reason: 'Nonaktif',
    );

    expect(requests, ['PUT /users/u1', 'PATCH /users/u1/status']);
    expect(bodies.first, {
      'full_name': 'Budi',
      'email': 'budi@example.test',
      'phone': '0812',
    });
    expect(bodies.last, {'status': 'inactive', 'reason': 'Nonaktif'});
  });

  test('crud query keeps stable provider identity', () {
    const a = AdminSearchQuery(search: 'kata');
    const b = AdminSearchQuery(search: 'kata');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    const approvalA = AdminApprovalQuery(search: 'guru');
    const approvalB = AdminApprovalQuery(search: 'guru');

    expect(approvalA, approvalB);
  });

  test('dictionary quiz question and report repository contracts', () async {
    final requests = <String>[];
    final repository = AdminCrudRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              if (options.method == 'POST' &&
                  options.path == '/admin/dictionary/entries') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': {
                        'id': 'word-new',
                        'category_id': 'cat-1',
                        'indonesia': 'A',
                        'english': 'B',
                        'mekongga': 'C',
                      },
                    },
                  ),
                );
                return;
              }
              if (options.method == 'POST' &&
                  options.path ==
                      '/admin/registration-requests/req-1/approve') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': {
                        'id': 'req-1',
                        'requested_role': 'teacher',
                        'status': 'approved',
                        'user': {'full_name': 'Guru', 'email': 'g@test'},
                      },
                    },
                  ),
                );
                return;
              }
              if (options.method == 'POST' &&
                  options.path == '/admin/quiz-templates/quiz-1/questions') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': {
                        'id': 'q-new',
                        'question_type': 'short_answer',
                        'question_text': 'Apa?',
                        'points': 1,
                        'order_number': 1,
                        'options': [],
                      },
                    },
                  ),
                );
                return;
              }
              final data = switch (options.path) {
                '/admin/dictionary/categories' => {
                  'data': [
                    {'id': 'cat-1', 'name': 'Umum'},
                  ],
                },
                '/admin/dictionary/entries' => {
                  'data': [
                    {
                      'id': 'word-1',
                      'category_id': 'cat-1',
                      'indonesia': 'Makan',
                      'english': 'Eat',
                      'mekongga': 'Mekaa',
                    },
                  ],
                  'meta': {'current_page': 1, 'last_page': 1},
                },
                '/admin/dictionary/entries/word-1' => {
                  'data': {
                    'id': 'word-1',
                    'category_id': 'cat-1',
                    'indonesia': 'Makan',
                    'english': 'Eat',
                    'mekongga': 'Mekaa',
                  },
                },
                '/admin/quiz-templates' => {
                  'data': [
                    {
                      'id': 'quiz-1',
                      'title': 'Kuis 1',
                      'duration_minutes': 30,
                      'max_attempts': 1,
                      'show_result': true,
                    },
                  ],
                  'meta': {'current_page': 1, 'last_page': 1},
                },
                '/admin/quiz-templates/quiz-1/questions' => {
                  'data': [
                    {
                      'id': 'q-1',
                      'question_type': 'multiple_choice',
                      'question_text': 'Apa?',
                      'points': 1,
                      'order_number': 1,
                      'options': [
                        {
                          'option_text': 'A',
                          'is_correct': true,
                          'order_number': 1,
                        },
                      ],
                    },
                  ],
                },
                '/admin/quiz-template-questions/q-1' => {
                  'data': {
                    'id': 'q-1',
                    'question_type': 'multiple_choice',
                    'question_text': 'Apa?',
                    'points': 1,
                    'order_number': 1,
                    'options': [],
                  },
                },
                '/admin/registration-requests' => {
                  'data': [
                    {
                      'id': 'req-1',
                      'requested_role': 'teacher',
                      'status': 'pending',
                      'user': {'full_name': 'Guru', 'email': 'g@test'},
                      'school': {'name': 'Sekolah'},
                      'school_class': {'name': 'Kelas 1'},
                    },
                  ],
                  'meta': {'current_page': 1, 'last_page': 1},
                },
                '/admin/registration-requests/req-1' => {
                  'data': {
                    'id': 'req-1',
                    'requested_role': 'teacher',
                    'status': 'pending',
                    'user': {'full_name': 'Guru', 'email': 'g@test'},
                  },
                },
                '/admin/reports/quiz-results' => {
                  'data': {
                    'summary': {'eligible_students': 1},
                    'rows': [
                      {
                        'student': {'full_name': 'Siswa'},
                        'quiz': {'title': 'Kuis'},
                      },
                    ],
                  },
                  'meta': {'current_page': 1, 'last_page': 1},
                },
                _ => {
                  'data': {
                    'id': 'created',
                    'title': 'Created',
                    'duration_minutes': 30,
                    'max_attempts': 1,
                    'show_result': true,
                  },
                },
              };
              handler.resolve(Response(requestOptions: options, data: data));
            },
          ),
        ),
      const DioErrorMapper(),
    );

    expect((await repository.categories()).items.single.name, 'Umum');
    expect((await repository.dictionary()).items.single.indonesia, 'Makan');
    expect((await repository.dictionaryDetail('word-1')).mekongga, 'Mekaa');
    await repository.saveDictionary(
      data: {
        'category_id': 'cat-1',
        'indonesia': 'A',
        'english': 'B',
        'mekongga': 'C',
      },
    );
    expect((await repository.quizzes()).items.single.title, 'Kuis 1');
    expect(
      (await repository.questions('quiz-1')).single.options.single.isCorrect,
      isTrue,
    );
    await repository.saveQuestion(
      quizId: 'quiz-1',
      data: {
        'question_type': 'short_answer',
        'question_text': 'Apa?',
        'points': 1,
        'order_number': 1,
      },
    );
    expect((await repository.approvals()).items.single.userName, 'Guru');
    expect((await repository.approvalDetail('req-1')).requestedRole, 'teacher');
    expect(
      (await repository.reviewApproval('req-1', 'approve', null)).status,
      'approved',
    );
    expect(requests, contains('POST /admin/dictionary/entries'));
    expect(requests, contains('POST /admin/quiz-templates/quiz-1/questions'));
    expect(requests, contains('GET /admin/registration-requests'));
    expect(requests, contains('GET /admin/registration-requests/req-1'));
    expect(
      requests,
      contains('POST /admin/registration-requests/req-1/approve'),
    );
  });

  testWidgets('admin user edit success without exception', (tester) async {
    var isUpdated = false;
    final repository = AdminRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/users/u1') {
                if (options.method == 'PUT') {
                  isUpdated = true;
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      data: {
                        'data': {
                          'id': 'u1',
                          'full_name': 'Budi Baru',
                          'email': 'budi@example.test',
                          'role': 'teacher',
                          'status': 'approved',
                        },
                      },
                    ),
                  );
                  return;
                }
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': {
                        'id': 'u1',
                        'full_name': isUpdated ? 'Budi Baru' : 'Budi',
                        'email': 'budi@example.test',
                        'role': 'teacher',
                        'status': 'approved',
                      },
                    },
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        ),
      const DioErrorMapper(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/admin/users/u1',
            routes: [
              GoRoute(
                path: '/admin/users/:id',
                builder: (_, state) =>
                    AdminUserDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Budi'), findsOneWidget);

    await tester.tap(find.text('Edit Data'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Data').last, findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Budi Baru');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Budi Baru'), findsOneWidget);
  });

  test('admin class parser query and repository contracts', () async {
    const query = AdminListQuery(
      search: 'VII',
      status: 'active',
      schoolId: 's1',
      page: 2,
    );
    final page = AdminClassPage.fromJson({
      'data': [
        {
          'id': 'c1',
          'school_id': 's1',
          'name': 'Kelas VII A',
          'grade_level': '7',
          'academic_year': '2026/2027',
          'status': 'active',
          'school': {'id': 's1', 'name': 'SMP Negeri 1 Kolaka'},
          'active_teacher_assignment': {
            'teacher': {'full_name': 'Ahmad', 'email': 'ahmad@example.test'},
          },
          'active_students_count': 28,
        },
      ],
      'meta': {'current_page': 2, 'last_page': 3, 'total': 16},
    });

    expect(query.toQuery(), {
      'search': 'VII',
      'status': 'active',
      'school_id': 's1',
      'page': 2,
      'per_page': 15,
    });
    expect(page.hasMore, isTrue);
    expect(page.items.single.schoolName, 'SMP Negeri 1 Kolaka');
    expect(page.items.single.teacherName, 'Ahmad');
    expect(page.items.single.studentsCount, 28);

    final requests = <String>[];
    final bodies = <Object?>[];
    final repository = AdminRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              bodies.add(options.data);
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'data': {
                      'id': 'c1',
                      'school_id': 's1',
                      'name': 'Kelas VII A',
                      'academic_year': '2026/2027',
                      'status': 'active',
                    },
                  },
                ),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );

    await repository.saveClass(
      schoolId: 's1',
      name: 'Kelas VII A',
      gradeLevel: '7',
      academicYear: '2026/2027',
      status: 'active',
    );
    await repository.saveClass(
      id: 'c1',
      schoolId: 's1',
      name: 'Kelas VII B',
      academicYear: '2026/2027',
      status: 'inactive',
    );
    await repository.deactivateClass('c1');
    await repository.assignTeacher('c1', 't1');
    await repository.assignStudent('c1', 'u1');

    expect(requests, [
      'POST /classes',
      'PUT /classes/c1',
      'DELETE /classes/c1',
      'POST /classes/c1/assign-teacher',
      'POST /classes/c1/assign-student',
    ]);
    expect(bodies[0], containsPair('school_id', 's1'));
    expect(bodies[1], isNot(contains('school_id')));
    expect(bodies[3], {'teacher_id': 't1'});
    expect(bodies[4], {'student_id': 'u1'});
  });

  test('admin class students parser hides raw membership terms', () {
    final page = AdminClassStudentPage.fromJson({
      'data': [
        {
          'membership_id': 'm1',
          'student': {
            'id': 'u1',
            'full_name': 'Budi',
            'email': 'budi@example.test',
            'status': 'approved',
          },
        },
      ],
    });

    expect(page.items.single.name, 'Budi');
    expect(page.items.single.status, 'approved');
  });

  testWidgets('admin user edit validation and close safety', (tester) async {
    final repository = AdminRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/users/u1') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': {
                        'id': 'u1',
                        'full_name': 'Budi',
                        'email': 'budi@example.test',
                        'role': 'teacher',
                        'status': 'approved',
                      },
                    },
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        ),
      const DioErrorMapper(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/admin/users/u1',
            routes: [
              GoRoute(
                path: '/admin/users/:id',
                builder: (_, state) =>
                    AdminUserDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Data'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama wajib diisi.'), findsOneWidget);

    // Tap outside to close
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Open again
    await tester.tap(find.text('Edit Data'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
