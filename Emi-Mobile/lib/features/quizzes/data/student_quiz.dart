class StudentQuiz {
  const StudentQuiz({
    required this.id,
    required this.title,
    required this.canStart,
    required this.hasActiveAttempt,
    required this.attemptLimitReached,
    required this.submittedAttemptsCount,
    required this.expiredAttemptsCount,
    required this.finishedAttemptsCount,
    required this.questionsCount,
    this.description,
    this.instructions,
    this.durationMinutes,
    this.maxAttempts,
    this.showResult,
    this.openAt,
    this.closeAt,
    this.attemptsCount,
    this.usedAttempts,
    this.remainingAttempts,
    this.latestScorePercent,
    this.bestScorePercent,
    this.latestSubmittedAt,
    this.activeAttempt,
    this.bestResult,
    this.latestResult,
    this.questions = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? instructions;
  final int? durationMinutes;
  final int? maxAttempts;
  final bool? showResult;
  final DateTime? openAt;
  final DateTime? closeAt;
  final int questionsCount;
  final int? attemptsCount;
  final int? usedAttempts;
  final int submittedAttemptsCount;
  final int expiredAttemptsCount;
  final int finishedAttemptsCount;
  final int? remainingAttempts;
  final bool attemptLimitReached;
  final bool canStart;
  final bool hasActiveAttempt;
  final double? latestScorePercent;
  final double? bestScorePercent;
  final String? latestSubmittedAt;
  final QuizAttemptSummary? activeAttempt;
  final QuizResultSummary? bestResult;
  final QuizResultSummary? latestResult;
  final List<QuizQuestion> questions;

  QuizAvailability get availability {
    final now = DateTime.now();
    if (openAt != null && openAt!.isAfter(now)) return QuizAvailability.locked;
    if (closeAt != null && closeAt!.isBefore(now)) {
      return QuizAvailability.closed;
    }
    if (submittedAttemptsCount > 0 || latestSubmittedAt != null) {
      return QuizAvailability.finished;
    }
    return QuizAvailability.open;
  }

  String get statusLabel {
    switch (availability) {
      case QuizAvailability.open:
        return canStart ? 'Tersedia' : 'Terkunci';
      case QuizAvailability.locked:
        return 'Terkunci';
      case QuizAvailability.closed:
        return 'Ditutup';
      case QuizAvailability.finished:
        return 'Selesai';
    }
  }

  factory StudentQuiz.fromJson(Map<String, dynamic> json) {
    return StudentQuiz(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '-',
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      durationMinutes: _nullableInt(json['duration_minutes']),
      maxAttempts: _nullableInt(json['max_attempts']),
      showResult: json['show_result'] as bool?,
      openAt: _date(json['open_at']),
      closeAt: _date(json['close_at']),
      questionsCount: _int(json['questions_count']),
      attemptsCount: _nullableInt(json['attempts_count']),
      usedAttempts: _nullableInt(json['used_attempts']),
      submittedAttemptsCount: _int(json['submitted_attempts_count']),
      expiredAttemptsCount: _int(json['expired_attempts_count']),
      finishedAttemptsCount: _int(json['finished_attempts_count']),
      remainingAttempts: _nullableInt(json['remaining_attempts']),
      attemptLimitReached: json['attempt_limit_reached'] as bool? ?? false,
      canStart: json['can_start'] as bool? ?? false,
      hasActiveAttempt: json['has_active_attempt'] as bool? ?? false,
      latestScorePercent: _double(json['latest_score_percent']),
      bestScorePercent: _double(json['best_score_percent']),
      latestSubmittedAt: json['latest_submitted_at']?.toString(),
      activeAttempt: json['active_attempt'] is Map<String, dynamic>
          ? QuizAttemptSummary.fromJson(json['active_attempt'])
          : null,
      bestResult: json['best_result'] is Map<String, dynamic>
          ? QuizResultSummary.fromJson(json['best_result'])
          : null,
      latestResult: json['latest_result'] is Map<String, dynamic>
          ? QuizResultSummary.fromJson(json['latest_result'])
          : null,
      questions: _list(json['questions']).map(QuizQuestion.fromJson).toList(),
    );
  }
}

class QuizAttemptSummary {
  const QuizAttemptSummary({
    required this.id,
    required this.status,
    this.attemptNumber,
    this.startedAt,
    this.expiresAt,
  });

  final String id;
  final String status;
  final int? attemptNumber;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  factory QuizAttemptSummary.fromJson(Map<String, dynamic> json) =>
      QuizAttemptSummary(
        id: json['id'] as String? ?? '',
        status: json['status'] as String? ?? '',
        attemptNumber: _nullableInt(json['attempt_number']),
        startedAt: _date(json['started_at']),
        expiresAt: _date(json['expires_at']),
      );
}

class QuizResultSummary {
  const QuizResultSummary({
    required this.scorePercent,
    this.scorePoints,
    this.maxPoints,
    this.submittedAt,
  });

  final double scorePercent;
  final double? scorePoints;
  final double? maxPoints;
  final DateTime? submittedAt;

  factory QuizResultSummary.fromJson(Map<String, dynamic> json) =>
      QuizResultSummary(
        scorePercent: _double(json['score_percent']) ?? 0,
        scorePoints: _double(json['score_points']),
        maxPoints: _double(json['max_points']),
        submittedAt: _date(json['submitted_at']),
      );
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.questionType,
    required this.questionText,
    required this.points,
    required this.orderNumber,
    required this.options,
    this.explanation,
  });

  final String id;
  final String questionType;
  final String questionText;
  final double points;
  final int orderNumber;
  final List<QuizOption> options;
  final String? explanation;

  bool get isMultipleChoice => questionType == 'multiple_choice';
  bool get isShortAnswer => questionType == 'short_answer';

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String? ?? '',
      questionType: json['question_type'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '-',
      points: _double(json['points']) ?? 0,
      orderNumber: _int(json['order_number']),
      options: _list(json['options']).map(QuizOption.fromJson).toList(),
      explanation: json['explanation'] as String?,
    );
  }
}

class QuizOption {
  const QuizOption({
    required this.id,
    required this.optionText,
    required this.orderNumber,
    this.isCorrect,
  });

  final String id;
  final String optionText;
  final int orderNumber;
  final bool? isCorrect;

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] as String? ?? '',
      optionText: json['option_text'] as String? ?? '-',
      orderNumber: _int(json['order_number']),
      isCorrect: json['is_correct'] as bool?,
    );
  }
}

class QuizAnswer {
  const QuizAnswer({
    required this.id,
    required this.questionId,
    this.selectedOptionId,
    this.answerText,
    this.isCorrect,
    this.awardedPoints,
    this.maxPoints,
  });

  final String id;
  final String questionId;
  final String? selectedOptionId;
  final String? answerText;
  final bool? isCorrect;
  final double? awardedPoints;
  final double? maxPoints;

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'] as String? ?? '',
      questionId: json['quiz_question_id'] as String? ?? '',
      selectedOptionId: json['selected_option_id'] as String?,
      answerText: json['answer_text'] as String?,
      isCorrect: json['is_correct'] as bool?,
      awardedPoints: _double(json['awarded_points']),
      maxPoints: _double(json['max_points']),
    );
  }
}

class QuizAttempt {
  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.attemptNumber,
    required this.status,
    required this.answers,
    this.startedAt,
    this.expiresAt,
    this.submittedAt,
    this.scorePoints,
    this.maxPoints,
    this.scorePercent,
    this.correctCount,
    this.incorrectCount,
    this.unansweredCount,
    this.quiz,
  });

  final String id;
  final String quizId;
  final int attemptNumber;
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? submittedAt;
  final double? scorePoints;
  final double? maxPoints;
  final double? scorePercent;
  final int? correctCount;
  final int? incorrectCount;
  final int? unansweredCount;
  final StudentQuiz? quiz;
  final List<QuizAnswer> answers;

  bool get isInProgress => status == 'in_progress';
  bool get isFinished => status == 'submitted' || status == 'expired';

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    final quizJson = json['class_quiz'];
    return QuizAttempt(
      id: json['id'] as String? ?? '',
      quizId: json['class_quiz_id'] as String? ?? '',
      attemptNumber: _int(json['attempt_number']),
      status: json['status'] as String? ?? '',
      startedAt: _date(json['started_at']),
      expiresAt: _date(json['expires_at']),
      submittedAt: _date(json['submitted_at']),
      scorePoints: _double(json['score_points']),
      maxPoints: _double(json['max_points']),
      scorePercent: _double(json['score_percent']),
      correctCount: _nullableInt(json['correct_count']),
      incorrectCount: _nullableInt(json['incorrect_count']),
      unansweredCount: _nullableInt(json['unanswered_count']),
      quiz: quizJson is Map<String, dynamic>
          ? StudentQuiz.fromJson(quizJson)
          : null,
      answers: _list(json['answers']).map(QuizAnswer.fromJson).toList(),
    );
  }
}

class QuizAttemptPage {
  const QuizAttemptPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<QuizAttempt> items;
  final int currentPage;
  final int lastPage;
  final int total;

  factory QuizAttemptPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];
    return QuizAttemptPage(
      items: data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map(QuizAttempt.fromJson)
                .toList()
          : const [],
      currentPage: meta is Map<String, dynamic>
          ? _int(meta['current_page'])
          : 1,
      lastPage: meta is Map<String, dynamic> ? _int(meta['last_page']) : 1,
      total: meta is Map<String, dynamic> ? _int(meta['total']) : 0,
    );
  }
}

class StudentQuizPage {
  const StudentQuizPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<StudentQuiz> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;

  factory StudentQuizPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];
    return StudentQuizPage(
      items: data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map(StudentQuiz.fromJson)
                .toList()
          : const [],
      currentPage: meta is Map<String, dynamic>
          ? _int(meta['current_page'])
          : 1,
      lastPage: meta is Map<String, dynamic> ? _int(meta['last_page']) : 1,
      total: meta is Map<String, dynamic> ? _int(meta['total']) : 0,
    );
  }
}

enum QuizAvailability { open, locked, closed, finished }

List<Map<String, dynamic>> _list(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList() : const [];

DateTime? _date(Object? value) => DateTime.tryParse(value?.toString() ?? '');

int _int(Object? value) => _nullableInt(value) ?? 0;

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}

double? _double(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
