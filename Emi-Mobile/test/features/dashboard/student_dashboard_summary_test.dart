import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/dashboard/data/student_dashboard_providers.dart';
import 'package:emi_mobile/features/dashboard/data/student_dashboard_summary.dart';
import 'package:emi_mobile/features/dashboard/presentation/student_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _AuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('dictionary quizzes and profile quick keys navigate', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/student/dashboard',
      routes: [
        GoRoute(
          path: '/student/dashboard',
          builder: (_, _) => const StudentDashboardScreen(),
        ),
        for (final route in ['dictionary', 'quizzes', 'profile'])
          GoRoute(path: '/student/$route', builder: (_, _) => Text(route)),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthRepository()),
          studentDashboardSummaryProvider.overrideWith((_) async => _summary),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    for (final entry in {
      'studentQuickMenuDictionary': '/student/dictionary',
      'studentQuickMenuQuizzes': '/student/quizzes',
      'studentQuickMenuProfile': '/student/profile',
    }.entries) {
      await tester.ensureVisible(find.byKey(Key(entry.key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(entry.key)));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, entry.value);
      router.go('/student/dashboard');
      await tester.pumpAndSettle();
    }
  });

  test('maps dashboard summary json', () {
    final summary = StudentDashboardSummary.fromJson({
      'empty_state': false,
      'class': {
        'id': 'class-1',
        'name': 'Kelas 1',
        'school': {'name': 'SD EMI'},
      },
      'learning': {
        'published_modules': 3,
        'not_started_modules': 1,
        'in_progress_modules': 1,
        'completed_modules': 1,
        'overall_progress_percent': 40,
        'completed_lessons': 4,
        'total_lessons': 10,
      },
      'quizzes': {
        'available': 2,
        'upcoming': 1,
        'in_progress_attempts': 1,
        'completed': 1,
        'visible_average_score': 80,
      },
    });

    expect(summary.classInfo?.name, 'Kelas 1');
    expect(summary.classInfo?.schoolName, 'SD EMI');
    expect(summary.learning.publishedModules, 3);
    expect(summary.quizzes.visibleAverageScore, 80);
  });
}

final _summary = StudentDashboardSummary.fromJson({
  'empty_state': false,
  'learning': {
    'published_modules': 1,
    'completed_modules': 0,
    'overall_progress_percent': 0,
    'completed_lessons': 0,
    'total_lessons': 1,
  },
  'quizzes': {'available': 1},
});
