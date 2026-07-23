import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/modules/data/student_module.dart';
import 'package:emi_mobile/features/modules/data/student_module_providers.dart';
import 'package:emi_mobile/features/modules/presentation/student_lesson_detail_screen.dart';
import 'package:emi_mobile/features/modules/presentation/student_module_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _AuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('module detail bottom Quiz navigates quizzes', (tester) async {
    await _navigationTest(tester, lesson: false);
  });

  testWidgets('lesson detail bottom Quiz navigates quizzes', (tester) async {
    await _navigationTest(tester, lesson: true);
  });

  test('maps module page json', () {
    final page = StudentModulePage.fromJson({
      'data': [
        {
          'id': 'module-1',
          'title': 'Aksara Mekongga',
          'description': 'Belajar dasar',
          'status': 'published',
          'sort_order': 1,
          'progress': {
            'status': 'in_progress',
            'progress_percent': 50,
            'completed_lessons': 2,
            'total_lessons': 4,
          },
        },
      ],
      'meta': {'current_page': 1, 'last_page': 2, 'total': 1},
    });

    expect(page.items.single.title, 'Aksara Mekongga');
    expect(page.items.single.progress.status, 'in_progress');
    expect(page.items.single.progress.progressPercent, 50);
    expect(page.hasNextPage, true);
  });

  test('maps module detail lessons json', () {
    final module = StudentModule.fromJson({
      'id': 'module-1',
      'title': 'Sapaan',
      'status': 'published',
      'sort_order': 1,
      'progress': {'status': 'not_started', 'progress_percent': 0},
      'lessons': [
        {
          'id': 'lesson-1',
          'class_module_id': 'module-1',
          'title': 'Pengenalan Sapaan',
          'description': 'Sapaan dasar',
          'content_type': 'text',
          'content_body': 'Mombesara',
          'sort_order': 1,
          'status': 'published',
          'media': {
            'id': 'media-1',
            'mime_type': 'image/png',
            'visibility': 'public',
          },
        },
      ],
    });

    expect(module.lessons.single.title, 'Pengenalan Sapaan');
    expect(module.lessons.single.hasTextContent, true);
    expect(module.lessons.single.media?.isImage, true);
  });

  test('maps lesson progress json', () {
    final progress = LessonProgress.fromJson({
      'id': 'progress-1',
      'class_lesson_id': 'lesson-1',
      'status': 'completed',
      'progress_percent': 100,
    });

    expect(progress.status, 'completed');
    expect(progress.progressPercent, 100);
  });
}

Future<void> _navigationTest(
  WidgetTester tester, {
  required bool lesson,
}) async {
  final router = GoRouter(
    initialLocation: lesson
        ? '/student/lessons/lesson-1'
        : '/student/modules/module-1',
    routes: [
      GoRoute(
        path: '/student/modules/:id',
        builder: (_, _) =>
            const StudentModuleDetailScreen(moduleId: 'module-1'),
      ),
      GoRoute(
        path: '/student/lessons/:id',
        builder: (_, _) => const StudentLessonDetailScreen(
          lessonId: 'lesson-1',
          moduleId: 'module-1',
        ),
      ),
      GoRoute(
        path: '/student/quizzes',
        builder: (_, _) => const Text('QUIZZES'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthRepository()),
        studentModuleDetailProvider.overrideWith((_, _) async => _module),
        studentLessonDetailProvider.overrideWith((_, _) async => _lesson),
        studentLessonContentProvider.overrideWith((_, _) async => null),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Kuis'));
  await tester.pumpAndSettle();
  expect(router.routeInformationProvider.value.uri.path, '/student/quizzes');
}

final _module = StudentModule.fromJson({
  'id': 'module-1',
  'title': 'Modul',
  'status': 'published',
  'progress': {'progress_percent': 0},
  'lessons': const [],
});

final _lesson = StudentLesson.fromJson({
  'id': 'lesson-1',
  'class_module_id': 'module-1',
  'title': 'Lesson',
  'content_type': 'text',
  'content_body': 'Isi',
  'status': 'published',
});
