import 'package:dio/dio.dart';
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

    expect(summary.items.map((item) => item.label), contains('Siswa'));
    expect(summary.items.map((item) => item.value), contains('10'));
    expect(summary.items.map((item) => item.helper), contains('Butuh review'));
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

    expect((await repository.dashboard()).items.first.value, '1');
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

  test('crud query keeps stable provider identity', () {
    const a = AdminSearchQuery(search: 'kata');
    const b = AdminSearchQuery(search: 'kata');
    const reportA = AdminReportQuery(kind: 'quiz');
    const reportB = AdminReportQuery(kind: 'quiz');

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    const approvalA = AdminApprovalQuery(search: 'guru');
    const approvalB = AdminApprovalQuery(search: 'guru');

    expect(reportA, reportB);
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
    expect((await repository.report('quiz')).summary['eligible_students'], 1);
    expect(requests, contains('POST /admin/dictionary/entries'));
    expect(requests, contains('POST /admin/quiz-templates/quiz-1/questions'));
    expect(requests, contains('GET /admin/registration-requests'));
    expect(requests, contains('GET /admin/registration-requests/req-1'));
    expect(
      requests,
      contains('POST /admin/registration-requests/req-1/approve'),
    );
    expect(requests, contains('GET /admin/reports/quiz-results'));
  });
}
