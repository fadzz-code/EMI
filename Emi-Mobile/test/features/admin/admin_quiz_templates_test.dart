import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/app/theme/emi_theme.dart';
import 'package:emi_mobile/features/admin/data/admin_crud_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_crud_repository.dart';
import 'package:emi_mobile/features/admin/data/admin_repository.dart';
import 'package:emi_mobile/features/admin/presentation/admin_quiz_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('admin quiz create actions use explicit create routes', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/admin/quizzes',
      routes: [
        GoRoute(
          path: '/admin/quizzes',
          builder: (_, _) => const AdminQuizScreen(),
        ),
        GoRoute(
          path: '/admin/quizzes/create',
          builder: (_, _) => const Text('FORM TEMPLATE BARU'),
        ),
        GoRoute(
          path: '/admin/quizzes/:quizId/questions',
          builder: (_, state) =>
              AdminQuestionListScreen(quizId: state.pathParameters['quizId']!),
        ),
        GoRoute(
          path: '/admin/quizzes/:quizId/questions/create',
          builder: (_, _) => const Text('FORM PERTANYAAN BARU'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminQuizProvider(
            const AdminSearchQuery(),
          ).overrideWith((_) => const AdminCrudPage(items: [])),
          adminQuizQuestionsProvider(
            'q1',
          ).overrideWith((_) => const <QuizQuestionAdmin>[]),
        ],
        child: MaterialApp.router(
          theme: EmiTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah Template Kuis'));
    await tester.pumpAndSettle();
    expect(find.text('FORM TEMPLATE BARU'), findsOneWidget);

    router.go('/admin/quizzes/q1/questions');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Pertanyaan'));
    await tester.pumpAndSettle();
    expect(find.text('FORM PERTANYAAN BARU'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      isNot(contains('/new')),
    );
  });

  test('correct option source and removal index semantics', () {
    final question = QuizQuestionAdmin.fromJson({
      ..._question('qq1'),
      'image_media_id': 'stale',
      'image_media': {
        'id': 'authoritative',
        'url': 'https://example.test/image.png',
        'original_name': 'image.png',
        'size_bytes': 2048,
        'mime_type': 'image/png',
      },
    });

    expect(question.options.indexWhere((option) => option.isCorrect), 0);
    expect(question.imageMediaId, 'authoritative');
    expect(question.imageName, 'image.png');
    expect(question.imageSize, 2048);
    final quiz = QuizTemplateAdmin.fromJson(
      _quiz('q1', questions: [_question('qq1')]),
    );
    expect(quiz.questions.single.options.first.isCorrect, true);
    expect(quiz.totalPoints, 10);
    expect(correctOptionAfterRemoval(2, 0), 1);
    expect(correctOptionAfterRemoval(1, 1), isNull);
    expect(correctOptionAfterRemoval(null, 0), isNull);
  });

  test('loads every active class page and dedupes for Select All', () async {
    final requestedPages = <int>[];
    final repository = AdminRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final page = options.queryParameters['page'] as int;
              requestedPages.add(page);
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'data': [
                      {
                        'id': page == 1 ? 'class-1' : 'class-2',
                        'name': 'Kelas $page',
                        'status': 'active',
                      },
                      if (page == 2)
                        {
                          'id': 'class-1',
                          'name': 'Duplikat',
                          'status': 'active',
                        },
                    ],
                    'meta': {'current_page': page, 'last_page': 2, 'total': 3},
                  },
                ),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );

    final classes = await repository.allActiveClasses();

    expect(requestedPages, [1, 2]);
    expect(classes.map((item) => item.id), ['class-1', 'class-2']);
  });

  testWidgets('publish dialog defaults distribution off and explains draft', (
    tester,
  ) async {
    Object? publishBody;
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = AdminCrudRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path.endsWith('/publish')) publishBody = options.data;
              handler.resolve(
                Response(requestOptions: options, data: {'data': _quiz('q1')}),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );

    final router = GoRouter(
      initialLocation: '/admin/quizzes/q1',
      routes: [
        GoRoute(
          path: '/admin/quizzes/:id',
          builder: (_, state) =>
              AdminQuizFormScreen(id: state.pathParameters['id']),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminCrudRepositoryProvider.overrideWithValue(repository),
          adminQuizDetailProvider(
            'q1',
          ).overrideWith((_) async => QuizTemplateAdmin.fromJson(_quiz('q1'))),
        ],
        child: MaterialApp.router(
          theme: EmiTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminPublish-quizzes')));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<CheckboxListTile>(
      find.byKey(const Key('adminPublishAllActiveClasses-quizzes')),
    );
    expect(checkbox.value, false);
    expect(find.text('Kirim ke semua kelas aktif'), findsOneWidget);
    expect(find.textContaining('Siswa belum dapat melihatnya'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Terbitkan'));
    await tester.pumpAndSettle();
    expect(publishBody, {'apply_to_all_active_classes': false});
  });

  test('admin quiz templates duplicate order handled', () async {
    final repository = AdminCrudRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 422,
                    data: {
                      'code': 'QUIZ_QUESTION_ORDER_ALREADY_USED',
                      'message': 'Urutan pertanyaan tersebut sudah digunakan.',
                    },
                  ),
                ),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );

    try {
      await repository.saveQuestion(quizId: 'q1', data: _questionPayload());
      fail('Should throw');
    } on AppError catch (e) {
      expect(e.message, contains('Urutan pertanyaan tersebut sudah digunakan'));
      expect(e.message, isNot(contains('SQLSTATE')));
      expect(e.message, isNot(contains('constraint')));
    }
  });

  test(
    'admin quiz templates list detail actions questions reorder apply media',
    () async {
      final requests = <String>[];
      final bodies = <Object?>[];
      final repository = AdminCrudRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests.add('${options.method} ${options.path}');
                bodies.add(options.data);
                Object data = _quiz('q1', questions: [_question('qq1')]);
                if (options.path.endsWith('/questions') &&
                    options.method == 'GET') {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      data: {
                        'data': [_question('qq1'), _question('qq2')],
                      },
                    ),
                  );
                  return;
                }
                if (options.path == '/media') {
                  data = {'id': 'media1'};
                }
                if (options.path == '/admin/quiz-templates' &&
                    options.method == 'GET') {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      data: {
                        'data': [data],
                        'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
                      },
                    ),
                  );
                  return;
                }

                handler.resolve(
                  Response(requestOptions: options, data: {'data': data}),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      final page = await repository.quizzes(search: ' kuis ', status: 'draft');
      expect(page.items.single.questionsCount, 1);
      expect(
        await repository.quizDetail('q1').then((value) => value.title),
        'Kuis Dasar',
      );
      await repository.saveQuiz(
        data: const {
          'title': 'Baru',
          'duration_minutes': 30,
          'max_attempts': 1,
          'status': 'draft',
        },
      );
      await repository.saveQuiz(
        id: 'q1',
        data: const {
          'title': 'Edit',
          'duration_minutes': 30,
          'max_attempts': 1,
          'status': 'published',
        },
      );
      await repository.quizStatus(
        'q1',
        'publish',
        applyToAllActiveClasses: true,
      );
      await repository.quizStatus('q1', 'archive');
      final questions = await repository.questions('q1');
      expect(questions.length, 2);
      await repository.saveQuestion(quizId: 'q1', data: _questionPayload());
      await repository.saveQuestion(
        quizId: 'q1',
        id: 'qq1',
        data: _questionPayload(),
      );
      await repository.reorderQuestions('q1', const ['qq2', 'qq1']);
      final summary = await repository.applyQuiz('q1', const [
        'class1',
      ], syncExisting: true);
      expect(summary.applied, isEmpty);
      expect(
        await repository
            .uploadQuestionImage('pubspec.yaml', 'soal.png')
            .then((media) => media.id),
        'media1',
      );
      await repository.deleteMedia('media1');
      await repository.deleteQuestion('qq1');
      await repository.deleteQuiz('q1');

      expect(requests, contains('GET /admin/quiz-templates'));
      expect(
        requests,
        contains('PATCH /admin/quiz-templates/q1/questions/reorder'),
      );
      expect(requests, contains('POST /admin/quiz-templates/q1/apply'));
      expect(
        bodies.whereType<Map>().any(
          (body) => body['apply_to_all_active_classes'] == true,
        ),
        isTrue,
      );
      expect(
        (bodies.firstWhere((body) => body is Map && body['class_ids'] != null)
            as Map)['sync_existing'],
        true,
      );
      expect(requests, contains('POST /media'));
      expect(requests, contains('DELETE /media/media1'));
      expect(
        (bodies.firstWhere(
              (body) => body is Map && body['question_ids'] != null,
            )
            as Map)['question_ids'],
        ['qq2', 'qq1'],
      );
    },
  );
}

Map<String, dynamic> _quiz(
  String id, {
  List<Map<String, dynamic>> questions = const [],
}) => {
  'id': id,
  'title': 'Kuis Dasar',
  'description': 'Latihan',
  'instructions': 'Jawab',
  'duration_minutes': 30,
  'max_attempts': 1,
  'show_result': true,
  'status': 'draft',
  'questions_count': questions.length,
  'questions': questions,
  'updated_at': '2026-07-15T00:00:00Z',
};

Map<String, dynamic> _question(String id) => {
  'id': id,
  'question_type': 'multiple_choice',
  'question_text': 'Apa arti mokole?',
  'points': 10,
  'order_number': id == 'qq1' ? 1 : 2,
  'options': [
    {'option_text': 'Raja', 'is_correct': true, 'order_number': 1},
    {'option_text': 'Rumah', 'is_correct': false, 'order_number': 2},
  ],
};

Map<String, dynamic> _questionPayload() => {
  'question_type': 'multiple_choice',
  'question_text': 'Apa arti mokole?',
  'points': 10,
  'options': [
    {'option_text': 'Raja', 'is_correct': true, 'order_number': 1},
    {'option_text': 'Rumah', 'is_correct': false, 'order_number': 2},
  ],
};
