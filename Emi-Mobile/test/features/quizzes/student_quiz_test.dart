import 'package:emi_mobile/features/quizzes/data/student_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps quiz page json', () {
    final page = StudentQuizPage.fromJson({
      'data': [
        {
          'id': 'quiz-1',
          'title': 'Kuis Sapaan',
          'description': 'Dasar sapaan',
          'instructions': 'Pilih jawaban benar',
          'duration_minutes': 20,
          'max_attempts': 2,
          'show_result': true,
          'questions_count': 5,
          'attempts_count': 1,
          'used_attempts': 1,
          'submitted_attempts_count': 1,
          'remaining_attempts': 1,
          'attempt_limit_reached': false,
          'can_start': true,
          'latest_score_percent': 80,
          'best_score_percent': 90,
          'latest_submitted_at': '2026-07-13T10:00:00Z',
        },
      ],
      'meta': {'current_page': 1, 'last_page': 2, 'total': 1},
    });

    expect(page.items.single.title, 'Kuis Sapaan');
    expect(page.items.single.durationMinutes, 20);
    expect(page.items.single.bestScorePercent, 90);
    expect(page.hasNextPage, true);
  });

  test('detects quiz status', () {
    final finished = StudentQuiz.fromJson({
      'id': 'quiz-1',
      'title': 'Kuis',
      'questions_count': 1,
      'submitted_attempts_count': 1,
      'attempt_limit_reached': false,
      'can_start': true,
    });
    final locked = StudentQuiz.fromJson({
      'id': 'quiz-2',
      'title': 'Kuis',
      'questions_count': 1,
      'submitted_attempts_count': 0,
      'attempt_limit_reached': false,
      'can_start': false,
      'open_at': '2999-01-01T00:00:00Z',
    });

    expect(finished.availability, QuizAvailability.finished);
    expect(finished.statusLabel, 'Selesai');
    expect(locked.availability, QuizAvailability.locked);
    expect(locked.statusLabel, 'Terkunci');
  });
}
