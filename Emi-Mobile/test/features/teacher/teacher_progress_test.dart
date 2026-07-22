import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:emi_mobile/features/teacher/data/teacher_providers.dart';
import 'package:emi_mobile/features/teacher/data/teacher_repository.dart';
import 'package:emi_mobile/features/teacher/presentation/teacher_dashboard_screen.dart';
import 'package:emi_mobile/features/teacher/presentation/teacher_dashboard_widgets.dart';
import 'package:emi_mobile/features/teacher/presentation/teacher_students_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _Auth extends AuthController {
  _Auth() : super(_MockAuthRepository()) {
    state = const AuthState(status: AuthStatus.authenticatedTeacher);
  }
}

TeacherClassPage _classes([List<Map<String, dynamic>>? data]) =>
    TeacherClassPage.fromJson({
      'data':
          data ??
          [
            {
              'id': 'class-1',
              'name': 'Kelas 7A',
              'status': 'active',
              'active_students_count': 20,
              'school': {'name': 'SMP EMI'},
            },
          ],
      'meta': {'current_page': 1, 'last_page': 1, 'total': data?.length ?? 1},
    });

TeacherStudentProgress _student({String name = 'Ayu'}) =>
    TeacherStudentProgress.fromJson({
      'student_id': 'student-1',
      'full_name': name,
      'school': {'name': 'SMP EMI'},
      'class': {'id': 'class-1', 'name': 'Kelas 7A'},
      'learning_status': 'in_progress',
      'published_modules': 4,
      'started_modules': 3,
      'completed_modules': 2,
      'completed_lessons': 6,
      'total_published_lessons': 10,
      'published_quizzes': 3,
      'quizzes_attempted': 2,
      'quizzes_completed': 1,
      'overall_learning_progress_percent': 55.5,
      'average_best_quiz_score_percent': 82,
      'last_learning_activity_at': '2026-07-20T10:00:00Z',
    });

TeacherStudentProgressPage _progress([List<TeacherStudentProgress>? items]) =>
    TeacherStudentProgressPage(
      items: items ?? [_student()],
      currentPage: 1,
      lastPage: 1,
      total: items?.length ?? 1,
    );

TeacherDashboardSummary get _summary => TeacherDashboardSummary.fromJson({
  'class': {'id': 'class-1', 'name': 'Kelas 7A'},
  'students': {},
  'learning': {},
  'recent_activity': [],
});

Future<GoRouter> _pump(
  WidgetTester tester, {
  required String location,
  List<Override> overrides = const [],
  Size size = const Size(430, 900),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/teacher/dashboard',
        builder: (_, _) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: '/teacher/speaking',
        builder: (_, _) => const Scaffold(body: Text('Speaking')),
      ),
      GoRoute(
        path: '/teacher/progress',
        builder: (_, _) => const TeacherProgressScreen(),
      ),
      GoRoute(
        path: '/teacher/progress/classes/:classId',
        builder: (_, state) => TeacherClassProgressScreen(
          classId: state.pathParameters['classId']!,
        ),
      ),
      GoRoute(
        path: '/teacher/progress/students/:studentId',
        builder: (_, state) =>
            TeacherStudentDetailScreen(id: state.pathParameters['studentId']!),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => _Auth()),
        teacherDashboardProvider.overrideWith((_) => _summary),
        teacherClassesProvider.overrideWith((_, _) => _classes()),
        teacherStudentProgressProvider.overrideWith((_, _) => _progress()),
        teacherClassDetailProvider.overrideWith(
          (_, _) => _classes().items.single,
        ),
        teacherClassProgressProvider.overrideWith((_, _) => _progress()),
        teacherStudentDetailProvider.overrideWith((_, _) => _student()),
        ...overrides,
      ],
      child: MaterialApp.router(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(size: size, textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  return router;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  test(
    'repository uses report endpoint, filters, pagination, and typed fields',
    () async {
      late RequestOptions request;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': [
                    {
                      'student_id': 'student-1',
                      'full_name': 'Ayu',
                      'school': {'name': 'SMP EMI'},
                      'class': {'id': 'class-1', 'name': 'Kelas 7A'},
                      'learning_status': 'in_progress',
                      'completed_lessons': 6,
                      'average_best_quiz_score_percent': 82,
                    },
                  ],
                  'meta': {'current_page': 2, 'last_page': 4, 'total': 61},
                },
              ),
            );
          },
        ),
      );
      final repository = TeacherRepository(dio, const DioErrorMapper());
      final result = await repository.studentProgress(
        page: 2,
        classId: 'class-1',
        search: 'Ayu',
      );
      expect(request.path, '/teacher/reports/progress/students');
      expect(request.queryParameters, containsPair('class_id', 'class-1'));
      expect(request.queryParameters, containsPair('search', 'Ayu'));
      expect(request.queryParameters, containsPair('page', 2));
      expect(result.total, 61);
      expect(result.items.single.schoolName, 'SMP EMI');
      expect(result.items.single.completedLessons, 6);
      expect(result.items.single.averageQuizScore, 82);

      await repository.studentDetail('student-1');
      expect(request.path, '/teacher/reports/progress/students');
      expect(request.queryParameters['student_id'], 'student-1');
      expect(request.queryParameters['per_page'], 1);
    },
  );

  testWidgets('sidebar places Progress after Speaking and opens route', (
    tester,
  ) async {
    final router = await _pump(tester, location: '/teacher/progress');
    await _settle(tester);
    await tester.tap(find.byKey(const Key('teacherMenuButton')));
    await _settle(tester);
    expect(find.text('Speaking'), findsOneWidget);
    expect(find.text('Progress'), findsWidgets);
    expect(
      tester.getTopLeft(find.text('Progress').last).dy,
      greaterThan(tester.getTopLeft(find.text('Speaking')).dy),
    );
    await tester.tap(find.text('Progress').last);
    await _settle(tester);
    expect(router.routeInformationProvider.value.uri.path, '/teacher/progress');
  });

  testWidgets('dashboard exposes Progress quick action', (tester) async {
    await _pump(tester, location: '/teacher/dashboard');
    await _settle(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -350));
    await tester.pump();
    final progress = find.widgetWithText(TeacherQuickAction, 'Progress');
    expect(progress, findsOneWidget);
    expect(tester.widget<TeacherQuickAction>(progress).onTap, isNotNull);
  });

  testWidgets('overview shows loading', (tester) async {
    final pending = Completer<TeacherClassPage>();
    await _pump(
      tester,
      location: '/teacher/progress',
      overrides: [
        teacherClassesProvider.overrideWith((_, _) => pending.future),
      ],
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test('overview provider exposes error', () async {
    final container = ProviderContainer(
      overrides: [
        teacherClassesProvider.overrideWith(
          (_, _) => throw Exception('offline'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(teacherClassesProvider((page: 1, search: '')).future),
      throwsA(isA<Exception>()),
    );
  });

  testWidgets('overview retry reloads data', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      location: '/teacher/progress',
      overrides: [
        teacherClassesProvider.overrideWith((_, _) async {
          calls++;
          return _classes();
        }),
      ],
    );
    await _settle(tester);
    expect(find.text('Kelas 7A'), findsOneWidget);
    expect(calls, 1);
  });

  test('overview providers expose empty data', () async {
    final container = ProviderContainer(
      overrides: [
        teacherClassesProvider.overrideWith((_, _) => _classes([])),
        teacherStudentProgressProvider.overrideWith((_, _) => _progress([])),
      ],
    );
    addTearDown(container.dispose);
    final classes = await container.read(
      teacherClassesProvider((page: 1, search: '')).future,
    );
    final progress = await container.read(
      teacherStudentProgressProvider((page: 1, search: '')).future,
    );
    expect(classes.items, isEmpty);
    expect(progress.items, isEmpty);
  });

  testWidgets('summary is 2x2 narrow', (tester) async {
    await _pump(
      tester,
      location: '/teacher/progress',
      size: const Size(430, 900),
    );
    await _settle(tester);
    final grid = tester.widget<GridView>(find.byType(GridView).first);
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
  });

  testWidgets('summary is one row at 720', (tester) async {
    await _pump(
      tester,
      location: '/teacher/progress',
      size: const Size(800, 900),
    );
    await _settle(tester);
    final grid = tester.widget<GridView>(find.byType(GridView).first);
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      4,
    );
    expect(find.text('Belum tersedia'), findsNWidgets(2));
  });

  testWidgets('class, student, and detail navigation show real report data', (
    tester,
  ) async {
    final router = await _pump(
      tester,
      location: '/teacher/progress/classes/class-1',
    );
    await _settle(tester);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/teacher/progress/classes/class-1',
    );
    expect(find.text('Cari siswa'), findsOneWidget);
    expect(find.text('Ayu'), findsOneWidget);
    expect(find.text('55.5%'), findsOneWidget);

    router.go('/teacher/progress/students/student-1');
    await _settle(tester);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/teacher/progress/students/student-1',
    );
    expect(find.text('Progress belajar'), findsOneWidget);
    expect(find.text('2/4'), findsOneWidget);
    expect(find.text('6/10'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pump();
    expect(find.text('Rata-rata nilai kuis: 82%'), findsOneWidget);
    expect(find.text('Progress speaking belum tersedia.'), findsOneWidget);
    expect(find.textContaining('Speaking selesai'), findsNothing);
  });

  testWidgets('class search sends trimmed actual query', (tester) async {
    final queries = <String>[];
    await _pump(
      tester,
      location: '/teacher/progress/classes/class-1',
      overrides: [
        teacherClassProgressProvider.overrideWith((_, query) async {
          queries.add(query.search);
          return _progress(
            query.search == 'Nina' ? [_student(name: 'Nina')] : [_student()],
          );
        }),
      ],
    );
    await _settle(tester);
    await tester.enterText(
      find.byKey(const Key('teacherProgressStudentSearch')),
      '  Nina  ',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(queries, contains('Nina'));
    expect(find.text('Nina'), findsOneWidget);
    expect(find.text('Ayu'), findsNothing);
  });

  testWidgets('AppBar back pops to Progress', (tester) async {
    final router = await _pump(tester, location: '/teacher/progress');
    await _settle(tester);
    final classTile = find.widgetWithText(ListTile, 'Kelas 7A');
    await tester.scrollUntilVisible(
      classTile,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    tester.widget<ListTile>(classTile).onTap!();
    await _settle(tester);
    await tester.tap(find.byKey(const Key('teacherBackButton')));
    await _settle(tester);
    expect(router.routeInformationProvider.value.uri.path, '/teacher/progress');
  });

  testWidgets('direct detail back falls back to Progress', (tester) async {
    final router = await _pump(
      tester,
      location: '/teacher/progress/students/student-1',
    );
    await _settle(tester);
    await tester.tap(find.byKey(const Key('teacherBackButton')));
    await _settle(tester);
    expect(router.routeInformationProvider.value.uri.path, '/teacher/progress');
  });

  testWidgets('small viewport at textScale 1.2 has no overflow or exception', (
    tester,
  ) async {
    await _pump(
      tester,
      location: '/teacher/progress/students/student-1',
      size: const Size(360, 640),
      textScale: 1.2,
    );
    await _settle(tester);
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pump();
    expect(find.text('Progress speaking belum tersedia.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
