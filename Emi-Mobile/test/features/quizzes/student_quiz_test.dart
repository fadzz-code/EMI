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
          'has_active_attempt': true,
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
    expect(page.items.single.hasActiveAttempt, true);
    expect(page.hasNextPage, true);
  });

  test('maps attempt questions options and result json', () {
    final attempt = QuizAttempt.fromJson({
      'id': 'attempt-1',
      'class_quiz_id': 'quiz-1',
      'attempt_number': 1,
      'status': 'submitted',
      'score_percent': 100,
      'correct_count': 1,
      'class_quiz': {
        'id': 'quiz-1',
        'title': 'Kuis Sapaan',
        'questions_count': 1,
        'submitted_attempts_count': 0,
        'attempt_limit_reached': false,
        'can_start': true,
        'questions': [
          {
            'id': 'question-1',
            'question_type': 'multiple_choice',
            'question_text': 'Apa arti mombesara?',
            'points': 10,
            'order_number': 1,
            'options': [
              {'id': 'option-1', 'option_text': 'Menyapa', 'order_number': 1},
            ],
          },
        ],
      },
      'answers': [
        {
          'id': 'answer-1',
          'quiz_question_id': 'question-1',
          'selected_option_id': 'option-1',
          'is_correct': true,
          'awarded_points': 10,
        },
      ],
    });

    expect(attempt.isFinished, true);
    expect(attempt.scorePercent, 100);
    expect(attempt.quiz?.questions.single.isMultipleChoice, true);
    expect(attempt.quiz?.questions.single.options.single.optionText, 'Menyapa');
    expect(attempt.answers.single.isCorrect, true);
  });

  test('maps active attempt answers and original expiry', () {
    final attempt = QuizAttempt.fromJson({
      'id': 'attempt-old',
      'class_quiz_id': 'quiz-1',
      'attempt_number': 1,
      'status': 'in_progress',
      'started_at': '2026-07-22T10:00:00Z',
      'expires_at': '2026-07-22T10:30:00Z',
      'class_quiz': {
        'id': 'quiz-1',
        'title': 'Kuis',
        'questions_count': 2,
        'submitted_attempts_count': 0,
        'attempt_limit_reached': false,
        'can_start': true,
        'has_active_attempt': true,
        'questions': const [],
      },
      'answers': [
        {
          'id': 'answer-1',
          'quiz_question_id': 'question-1',
          'selected_option_id': 'option-1',
        },
        {
          'id': 'answer-2',
          'quiz_question_id': 'question-2',
          'answer_text': 'Mekongga',
        },
      ],
    });

    expect(attempt.id, 'attempt-old');
    expect(attempt.isInProgress, true);
    expect(attempt.expiresAt, DateTime.parse('2026-07-22T10:30:00Z'));
    expect(attempt.answers.first.selectedOptionId, 'option-1');
    expect(attempt.answers.last.answerText, 'Mekongga');
    expect(attempt.quiz?.hasActiveAttempt, true);
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
