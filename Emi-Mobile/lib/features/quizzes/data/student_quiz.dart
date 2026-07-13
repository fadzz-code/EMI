class StudentQuiz {
  const StudentQuiz({
    required this.id,
    required this.title,
    required this.canStart,
    required this.attemptLimitReached,
    required this.submittedAttemptsCount,
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
  final int? remainingAttempts;
  final bool attemptLimitReached;
  final bool canStart;
  final double? latestScorePercent;
  final double? bestScorePercent;
  final String? latestSubmittedAt;

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
      remainingAttempts: _nullableInt(json['remaining_attempts']),
      attemptLimitReached: json['attempt_limit_reached'] as bool? ?? false,
      canStart: json['can_start'] as bool? ?? false,
      latestScorePercent: _double(json['latest_score_percent']),
      bestScorePercent: _double(json['best_score_percent']),
      latestSubmittedAt: json['latest_submitted_at']?.toString(),
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
