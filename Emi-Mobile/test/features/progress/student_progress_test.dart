import 'package:emi_mobile/features/progress/data/student_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps student progress report json', () {
    final report = StudentProgressReport.fromJson({
      'data': {
        'summary': {
          'student_id': 'student-1',
          'full_name': 'Siswa EMI',
          'class': {'id': 'class-1', 'name': 'Kelas 1'},
          'published_modules': 4,
          'started_modules': 2,
          'completed_modules': 1,
          'in_progress_modules': 1,
          'not_started_modules': 2,
          'overall_learning_progress_percent': 45.5,
          'completed_lessons': 3,
          'total_published_lessons': 8,
          'published_quizzes': 2,
          'quizzes_attempted': 1,
          'quizzes_completed': 1,
          'submitted_quiz_count': 1,
          'average_best_quiz_score_percent': 90,
        },
        'modules': {
          'data': [
            {
              'id': 'module-1',
              'title': 'Sapaan',
              'status': 'in_progress',
              'progress_percent': 50,
              'completed_lessons': 2,
              'total_lessons': 4,
              'sort_order': 1,
            },
          ],
          'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
        },
      },
    });

    expect(report.summary?.overallLearningProgressPercent, 45.5);
    expect(report.summary?.averageBestQuizScorePercent, 90);
    expect(report.modules.items.single.title, 'Sapaan');
    expect(report.modules.items.single.progressPercent, 50);
  });
}
