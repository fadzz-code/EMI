import 'package:emi_mobile/features/dashboard/data/student_dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
