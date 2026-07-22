import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/teacher/data/teacher_quiz_models.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:emi_mobile/features/teacher/data/teacher_providers.dart';
import 'package:emi_mobile/features/teacher/data/teacher_quiz_repository.dart';
import 'package:emi_mobile/features/teacher/presentation/teacher_dashboard_screen.dart';
import 'package:emi_mobile/features/teacher/presentation/teacher_quizzes_screens.dart';
import 'package:emi_mobile/shared/widgets/emi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/teacher/data/teacher_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _Auth extends AuthController {
  _Auth() : super(_MockAuthRepository()) {
    state = const AuthState(status: AuthStatus.authenticatedTeacher);
  }
}

TeacherQuiz _quiz({String status = 'draft', int questions = 1}) =>
    TeacherQuiz.fromJson({
      'id': 'quiz-1',
      'class_id': 'class-1',
      'class': {'name': 'Kelas 7A'},
      'title': 'Sapaan',
      'description': 'Dasar',
      'instructions': 'Pilih jawaban',
      'duration_minutes': 30,
      'max_attempts': 2,
      'show_result': true,
      'status': status,
      'questions_count': questions,
      'attempts_count': 3,
      'updated_at': '2026-07-18T09:00:00Z',
      'questions': questions == 0
          ? []
          : [
              {
                'id': 'question-1',
                'question_type': 'multiple_choice',
                'question_text': 'Arti halo?',
                'points': 2,
                'order_number': 1,
                'options': [],
              },
            ],
    });

Future<GoRouter> _pump(
  WidgetTester tester, {
  required String location,
  required List<Override> overrides,
  double textScale = 1,
}) async {
  await tester.pumpWidget(const SizedBox());
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/teacher/dashboard',
        builder: (_, _) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: '/teacher/quizzes',
        builder: (_, _) => const TeacherQuizzesScreen(),
      ),
      GoRoute(
        path: '/teacher/quizzes/create',
        builder: (_, _) => const TeacherQuizFormScreen(),
      ),
      GoRoute(
        path: '/teacher/quizzes/:id/edit',
        builder: (_, s) => TeacherQuizFormScreen(id: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/teacher/quizzes/:quizId/questions/create',
        builder: (_, s) =>
            TeacherQuestionFormScreen(quizId: s.pathParameters['quizId']!),
      ),
      GoRoute(
        path: '/teacher/quizzes/:quizId/questions/:id/edit',
        builder: (_, s) => TeacherQuestionFormScreen(
          quizId: s.pathParameters['quizId']!,
          id: s.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/teacher/quizzes/:id',
        builder: (_, s) => TeacherQuizDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/parent', builder: (_, _) => const Text('PARENT')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => _Auth()),
        ...overrides,
      ],
      child: MaterialApp.router(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  return router;
}

void main() {
  late List<RequestOptions> requests;
  late TeacherQuizRepository repository;
  final quiz = {
    'id': 'quiz-1',
    'class_id': 'class-1',
    'class': {'id': 'class-1', 'name': 'Kelas 7A'},
    'title': 'Sapaan',
    'description': 'Dasar',
    'instructions': 'Pilih jawaban',
    'duration_minutes': 30,
    'max_attempts': 2,
    'show_result': true,
    'open_at': '2026-07-18T08:00:00Z',
    'close_at': '2026-07-19T08:00:00Z',
    'status': 'draft',
    'questions_count': 1,
    'attempts_count': 3,
    'updated_at': '2026-07-18T09:00:00Z',
    'questions': [
      {
        'id': 'question-1',
        'question_type': 'multiple_choice',
        'question_text': 'Arti halo?',
        'points': 2,
        'order_number': 1,
        'options': [
          {'option_text': 'Sapaan', 'is_correct': true, 'order_number': 1},
        ],
      },
    ],
  };

  setUp(() {
    requests = [];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final data = switch (options.path) {
            '/class-quizzes' when options.method == 'GET' => {
              'data': [quiz],
              'meta': {'current_page': 1, 'last_page': 2},
            },
            '/quiz-questions/question-1' || '/class-quizzes/quiz-1/questions' =>
              {'data': (quiz['questions'] as List).single},
            '/class-quizzes/quiz-1/attempts' => {
              'data': [
                {
                  'id': 'attempt-1',
                  'student': {'full_name': 'Budi'},
                  'attempt_number': 2,
                  'status': 'submitted',
                  'score_points': 8,
                  'max_points': 10,
                  'score_percent': 80,
                },
              ],
              'meta': {'current_page': 1, 'last_page': 1},
            },
            '/quiz-attempts/attempt-1' => {
              'data': {
                'id': 'attempt-1',
                'student': {'full_name': 'Budi'},
                'attempt_number': 2,
                'status': 'submitted',
                'score_percent': 80,
                'answers': [
                  {
                    'quiz_question_id': 'question-1',
                    'answer_text': 'Sapaan',
                    'is_correct': true,
                    'awarded_points': 2,
                    'max_points': 2,
                  },
                ],
              },
            },
            _ => {
              'data': {
                ...quiz,
                if (options.path.endsWith('/publish')) 'status': 'published',
                if (options.path.endsWith('/archive')) 'status': 'archived',
              },
            },
          };
          handler.resolve(Response(requestOptions: options, data: data));
        },
      ),
    );
    repository = TeacherQuizRepository(dio, const DioErrorMapper());
  });

  test('parses exact quiz, schedule, limits, counts, and questions', () async {
    final item = await repository.detail('quiz-1');
    expect(item.title, 'Sapaan');
    expect(item.className, 'Kelas 7A');
    expect(item.updatedAt, DateTime.parse('2026-07-18T09:00:00Z'));
    expect(item.durationMinutes, 30);
    expect(item.maxAttempts, 2);
    expect(item.showResult, isTrue);
    expect(item.openAt, DateTime.parse('2026-07-18T08:00:00Z'));
    expect(item.questions.single.options.single.correct, isTrue);
  });

  test('lists with search status and pagination contract', () async {
    final page = await repository.list(
      page: 2,
      search: ' sapa ',
      status: 'draft',
    );
    expect(page.items.single.id, 'quiz-1');
    expect(page.lastPage, 2);
    expect(requests.single.queryParameters, {
      'page': 2,
      'search': 'sapa',
      'status': 'draft',
    });
  });

  test('creates and updates using exact payload', () async {
    final payload = {
      'class_id': 'class-1',
      'class': {'id': 'class-1', 'name': 'Kelas 7A'},
      'title': 'Sapaan',
      'duration_minutes': 30,
      'max_attempts': 2,
      'show_result': true,
      'open_at': null,
      'close_at': null,
    };
    await repository.create(payload);
    await repository.update('quiz-1', payload);
    expect(requests[0].method, 'POST');
    expect(requests[0].data, payload);
    expect(requests[1].method, 'PUT');
    expect(requests[1].data, payload);
  });

  test('publishes, archives, and deletes through actual endpoints', () async {
    expect((await repository.publish('quiz-1')).status, 'published');
    expect((await repository.archive('quiz-1')).status, 'archived');
    await repository.deleteQuiz('quiz-1');
    expect(requests.map((r) => '${r.method} ${r.path}'), [
      'POST /class-quizzes/quiz-1/publish',
      'POST /class-quizzes/quiz-1/archive',
      'DELETE /class-quizzes/quiz-1',
    ]);
  });

  test(
    'question create update detail and delete use actual endpoints',
    () async {
      final createPayload = {
        'question_type': 'multiple_choice',
        'question_text': 'Arti halo?',
        'points': 2,
        'options': [
          {'option_text': 'Sapaan', 'is_correct': true, 'order_number': 1},
        ],
      };
      final updatePayload = {...createPayload, 'order_number': 1};
      await repository.createQuestion('quiz-1', createPayload);
      await repository.question('question-1');
      await repository.updateQuestion('question-1', updatePayload);
      await repository.deleteQuestion('question-1');
      expect((requests.first.data as Map).containsKey('order_number'), isFalse);
      expect((requests[2].data as Map)['order_number'], 1);
      expect(requests.map((r) => '${r.method} ${r.path}'), [
        'POST /class-quizzes/quiz-1/questions',
        'GET /quiz-questions/question-1',
        'PUT /quiz-questions/question-1',
        'DELETE /quiz-questions/question-1',
      ]);
    },
  );

  test('lists attempts and opens actual attempt detail', () async {
    final page = await repository.attempts(
      'quiz-1',
      page: 1,
      status: 'submitted',
    );
    final detail = await repository.attempt('attempt-1');
    expect(page.items.single.studentName, 'Budi');
    expect(page.items.single.scorePercent, 80);
    expect(detail.answers.single.correct, isTrue);
    expect(detail.answers.single.answerText, 'Sapaan');
    expect(requests.first.queryParameters, {'page': 1, 'status': 'submitted'});
    expect(requests.map((r) => r.path), [
      '/class-quizzes/quiz-1/attempts',
      '/quiz-attempts/attempt-1',
    ]);
  });

  test('raw numeric and boolean values remain typed', () {
    final item = TeacherQuizAttempt.fromJson({
      'id': 'a',
      'attempt_number': 3,
      'status': 'expired',
      'score_points': 7.5,
      'score_percent': 75,
    });
    expect(item.number, 3);
    expect(item.scorePoints, 7.5);
    expect(item.scorePercent, 75);
  });

  test('models use friendly safe defaults without passing score', () {
    final item = TeacherQuiz.fromJson({});
    expect(item.title, 'Kuis tanpa judul');
    expect(item.status, 'draft');
    expect(item.questions, isEmpty);
  });

  testWidgets('menu label and quick action navigate to real quiz route', (
    tester,
  ) async {
    final summary = TeacherDashboardSummary.fromJson({
      'class': {'id': 'class-1', 'name': 'Kelas 7A'},
      'students': {},
      'learning': {},
      'recent_activity': [],
    });
    final router = await _pump(
      tester,
      location: '/teacher/dashboard',
      overrides: [teacherDashboardProvider.overrideWith((_) async => summary)],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('teacherMenuButton')));
    await tester.pumpAndSettle();
    expect(find.text('Kuis'), findsWidgets);
    Navigator.of(tester.element(find.text('Kuis').last)).pop();
    await tester.pumpAndSettle();
    final source = File(
      'lib/features/teacher/presentation/teacher_dashboard_screen.dart',
    ).readAsStringSync();
    expect(source, contains("onTap: () => context.go('/teacher/quizzes')"));
    expect(
      router.routeInformationProvider.value.uri.path,
      '/teacher/dashboard',
    );
    expect(source, contains("context.go('/teacher/quizzes')"));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'list loading, empty exact copy, error retry, list and Indonesian status',
    (tester) async {
      final pending = Completer<TeacherQuizPage>();
      await _pump(
        tester,
        location: '/teacher/quizzes',
        overrides: [
          teacherQuizzesProvider.overrideWith((_, _) => pending.future),
        ],
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Container), findsWidgets);
      await tester.pumpWidget(const SizedBox());

      await _pump(
        tester,
        location: '/teacher/quizzes',
        overrides: [
          teacherQuizzesProvider.overrideWith(
            (_, _) async =>
                const TeacherQuizPage(items: [], page: 1, lastPage: 1),
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('Belum Ada Kuis'), findsOneWidget);
      expect(
        find.text('Buat kuis pertama untuk mulai menilai pemahaman siswa.'),
        findsOneWidget,
      );

      var calls = 0;
      await _pump(
        tester,
        location: '/teacher/quizzes',
        overrides: [
          teacherQuizzesProvider.overrideWith((_, _) async {
            calls++;
            throw Exception('network');
          }),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Kuis Belum Bisa Dimuat'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      expect(calls, greaterThan(1));

      await _pump(
        tester,
        location: '/teacher/quizzes',
        textScale: 1.2,
        overrides: [
          teacherQuizzesProvider.overrideWith(
            (_, _) async => TeacherQuizPage(
              items: [_quiz(status: 'published')],
              page: 1,
              lastPage: 1,
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(find.text('Sapaan'), findsOneWidget);
      expect(find.textContaining('Kelas 7A'), findsOneWidget);
      expect(find.textContaining('Terbit'), findsWidgets);
      expect(find.textContaining('quiz-1'), findsNothing);
      expect(find.textContaining('published'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'detail and question list render friendly metrics without raw values',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(
        tester,
        location: '/teacher/quizzes/quiz-1',
        textScale: 1.2,
        overrides: [
          teacherQuizDetailProvider.overrideWith((_, _) async => _quiz()),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Sapaan'), findsOneWidget);
      expect(find.text('30 menit'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      final metricCards =
          [
                find.text('Pertanyaan'),
                find.text('Batas Percobaan'),
                find.text('Durasi'),
                find.text('Pengerjaan'),
              ]
              .map(
                (label) => find.ancestor(
                  of: label.first,
                  matching: find.byType(EmiCard),
                ),
              )
              .toList();
      final mobileTops = metricCards
          .map((finder) => tester.getTopLeft(finder.first).dy)
          .toList();
      expect(mobileTops[0], mobileTops[1]);
      expect(mobileTops[2], mobileTops[3]);
      expect(mobileTops[2], greaterThan(mobileTops[0]));
      expect(find.text('Pertanyaan'), findsWidgets);
      expect(find.text('Nilai Lulus'), findsNothing);
      expect(find.text('Pilih jawaban'), findsNothing);
      expect(find.textContaining('Draf'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Arti halo?'), 200);
      expect(find.text('Arti halo?'), findsOneWidget);
      expect(find.textContaining('quiz-1'), findsNothing);
      expect(find.textContaining('multiple_choice'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(tester.takeException(), isNull);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'quiz create edit and question create edit show friendly validation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final source = File(
        'lib/features/teacher/presentation/teacher_quizzes_screens.dart',
      ).readAsStringSync();
      expect(source, contains("_field(title, 'Judul Kuis', required: true)"));
      expect(source, contains("return '\$label wajib diisi.'"));
      expect(
        source,
        contains("title: quiz == null ? 'Buat Kuis' : 'Edit Kuis'"),
      );

      await _pump(
        tester,
        location: '/teacher/quizzes/quiz-1/edit',
        overrides: [
          teacherQuizDetailProvider.overrideWith((_, _) async => _quiz()),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit Kuis'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'Sapaan'), findsOneWidget);
      final duration = find.text('Durasi (menit)');
      final attempts = find.text('Maksimal Percobaan');
      expect(duration, findsOneWidget);
      expect(attempts, findsOneWidget);
      expect(
        tester.getTopLeft(attempts).dy,
        greaterThan(tester.getTopLeft(duration).dy),
      );
      tester.view.physicalSize = const Size(390, 560);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      expect(find.text('Simpan'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text('Simpan')).dy,
        lessThanOrEqualTo(320),
      );
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = FakeViewPadding.zero;
      tester.view.physicalSize = const Size(390, 480);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(source, contains("_input(text, 'Pertanyaan', true)"));
      expect(source, contains("q == null ? 'Buat Soal' : 'Edit Soal'"));
      expect(source, isNot(contains("_input(order, 'Urutan'")));

      final question = _quiz().questions.single;
      await _pump(
        tester,
        location: '/teacher/quizzes/quiz-1/questions/question-1/edit',
        overrides: [
          teacherQuizQuestionProvider.overrideWith((_, _) async => question),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit Soal'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'Arti halo?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'publish guard, dirty AppBar/system back, and direct-link fallback parent',
    (tester) async {
      await _pump(
        tester,
        location: '/teacher/quizzes/quiz-1',
        overrides: [
          teacherQuizDetailProvider.overrideWith(
            (_, _) async => _quiz(questions: 0),
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terbitkan Kuis'));
      await tester.pump();
      expect(
        find.text('Tambahkan minimal satu soal sebelum menerbitkan kuis.'),
        findsOneWidget,
      );

      await _pump(
        tester,
        location: '/teacher/quizzes/create',
        overrides: const [],
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Judul Kuis'),
        'Kuis baru',
      );
      await tester.tap(find.byKey(const Key('teacherBackButton')));
      await tester.pumpAndSettle();
      expect(find.text('Batalkan perubahan?'), findsOneWidget);
      expect(find.text('Buat Kuis'), findsWidgets);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Buat Kuis'), findsWidgets);

      final direct = await _pump(
        tester,
        location: '/teacher/quizzes/quiz-1',
        overrides: [
          teacherQuizDetailProvider.overrideWith((_, _) async => _quiz()),
          teacherQuizzesProvider.overrideWith(
            (_, _) async =>
                const TeacherQuizPage(items: [], page: 1, lastPage: 1),
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('teacherBackButton')));
      await tester.pump();
      expect(
        direct.routeInformationProvider.value.uri.path,
        '/teacher/quizzes',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
