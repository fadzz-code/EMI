class TeacherQuiz {
  const TeacherQuiz({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.instructions,
    required this.durationMinutes,
    required this.maxAttempts,
    required this.showResult,
    required this.status,
    required this.questionsCount,
    required this.attemptsCount,
    required this.questions,
    this.className,
    this.openAt,
    this.closeAt,
    this.updatedAt,
  });

  final String id;
  final String classId;
  final String? className;
  final String title;
  final String description;
  final String instructions;
  final int durationMinutes;
  final int maxAttempts;
  final bool showResult;
  final DateTime? openAt;
  final DateTime? closeAt;
  final DateTime? updatedAt;
  final String status;
  final int questionsCount;
  final int attemptsCount;
  final List<TeacherQuizQuestion> questions;

  factory TeacherQuiz.fromJson(Map<String, dynamic> json) => TeacherQuiz(
    id: _text(json['id']),
    classId: _text(json['class_id']),
    className: _nullableText(_map(json['class'])['name']),
    title: _text(json['title'], 'Kuis tanpa judul'),
    description: _text(json['description']),
    instructions: _text(json['instructions']),
    durationMinutes: _integer(json['duration_minutes']),
    maxAttempts: _integer(json['max_attempts']),
    showResult: json['show_result'] == true || json['show_result'] == 1,
    openAt: DateTime.tryParse(_text(json['open_at'])),
    closeAt: DateTime.tryParse(_text(json['close_at'])),
    updatedAt: DateTime.tryParse(_text(json['updated_at'])),
    status: _text(json['status'], 'draft'),
    questionsCount: _integer(json['questions_count']),
    attemptsCount: _integer(json['attempts_count']),
    questions: json['questions'] is List
        ? (json['questions'] as List)
              .whereType<Map<String, dynamic>>()
              .map(TeacherQuizQuestion.fromJson)
              .toList()
        : const [],
  );
}

class TeacherQuizPage {
  const TeacherQuizPage({
    required this.items,
    required this.page,
    required this.lastPage,
  });
  final List<TeacherQuiz> items;
  final int page;
  final int lastPage;

  factory TeacherQuizPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'];
    final meta = json?['meta'] is Map<String, dynamic>
        ? json!['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return TeacherQuizPage(
      items: rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(TeacherQuiz.fromJson)
                .toList()
          : const [],
      page: _integer(meta['current_page'], 1),
      lastPage: _integer(meta['last_page'], 1),
    );
  }
}

class TeacherQuizQuestion {
  const TeacherQuizQuestion({
    required this.id,
    required this.type,
    required this.text,
    required this.correctAnswer,
    required this.points,
    required this.order,
    required this.explanation,
    required this.options,
    required this.useFuzzyMatching,
    this.fuzzyThreshold,
    this.imageMediaId,
    this.imageUrl,
    this.imageName,
  });
  final String id;
  final String type;
  final String text;
  final String correctAnswer;
  final int points;
  final int order;
  final String explanation;
  final List<TeacherQuizOption> options;
  final bool useFuzzyMatching;
  final int? fuzzyThreshold;
  final String? imageMediaId;
  final String? imageUrl;
  final String? imageName;

  factory TeacherQuizQuestion.fromJson(Map<String, dynamic> json) {
    final image = _map(json['image_media']);
    return TeacherQuizQuestion(
      id: _text(json['id']),
      type: _text(json['question_type'], 'multiple_choice'),
      text: _text(json['question_text']),
      correctAnswer: _text(json['correct_answer_text']),
      points: _integer(json['points'], 1),
      order: _integer(json['order_number'], 1),
      explanation: _text(json['explanation']),
      useFuzzyMatching:
          json['use_fuzzy_matching'] == true || json['use_fuzzy_matching'] == 1,
      fuzzyThreshold: json['fuzzy_threshold'] == null
          ? null
          : _integer(json['fuzzy_threshold']),
      imageMediaId: _nullableText(json['image_media_id'] ?? image['id']),
      imageUrl: _nullableText(image['url']),
      imageName: _nullableText(image['original_name']),
      options: json['options'] is List
          ? (json['options'] as List)
                .whereType<Map<String, dynamic>>()
                .map(TeacherQuizOption.fromJson)
                .toList()
          : const [],
    );
  }
}

class TeacherQuizOption {
  const TeacherQuizOption({
    required this.text,
    required this.correct,
    required this.order,
  });
  final String text;
  final bool correct;
  final int order;
  factory TeacherQuizOption.fromJson(Map<String, dynamic> json) =>
      TeacherQuizOption(
        text: _text(json['option_text']),
        correct: json['is_correct'] == true || json['is_correct'] == 1,
        order: _integer(json['order_number'], 1),
      );
  Map<String, dynamic> toJson() => {
    'option_text': text,
    'is_correct': correct,
    'order_number': order,
  };
}

class TeacherQuizResultPage {
  const TeacherQuizResultPage({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.average,
    required this.highest,
    required this.lowest,
  });
  final List<TeacherQuizAttempt> items;
  final int page;
  final int lastPage;
  final num? average;
  final num? highest;
  final num? lowest;

  factory TeacherQuizResultPage.fromJson(Map<String, dynamic>? json) {
    final data = _map(json?['data']);
    final summary = _map(data['summary']);
    final rows = data['rows'];
    final meta = _map(json?['meta']);
    return TeacherQuizResultPage(
      items: rows is List
          ? rows.whereType<Map<String, dynamic>>().map((row) {
              final student = _map(row['student']);
              return TeacherQuizAttempt.fromJson({
                'id':
                    '${_text(student['id'])}:${_integer(row['best_attempt_number'])}',
                'student': student,
                'attempt_number': row['best_attempt_number'],
                'status': row['latest_status'],
                'score_percent': row['best_score_percent'],
              });
            }).toList()
          : const [],
      page: _integer(meta['current_page'], 1),
      lastPage: _integer(meta['last_page'], 1),
      average: summary['average_best_score_percent'] as num?,
      highest: summary['highest_best_score_percent'] as num?,
      lowest: summary['lowest_best_score_percent'] as num?,
    );
  }
}

class TeacherQuizAttemptPage {
  const TeacherQuizAttemptPage({
    required this.items,
    required this.page,
    required this.lastPage,
  });
  final List<TeacherQuizAttempt> items;
  final int page;
  final int lastPage;

  factory TeacherQuizAttemptPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'];
    final meta = _map(json?['meta']);
    return TeacherQuizAttemptPage(
      items: rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(TeacherQuizAttempt.fromJson)
                .toList()
          : const [],
      page: _integer(meta['current_page'], 1),
      lastPage: _integer(meta['last_page'], 1),
    );
  }
}

class TeacherQuizAttempt {
  const TeacherQuizAttempt({
    required this.id,
    required this.studentName,
    required this.number,
    required this.status,
    required this.answers,
    this.scorePoints,
    this.maxPoints,
    this.scorePercent,
    this.startedAt,
    this.submittedAt,
  });
  final String id;
  final String studentName;
  final int number;
  final String status;
  final num? scorePoints;
  final num? maxPoints;
  final num? scorePercent;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final List<TeacherQuizAnswer> answers;

  factory TeacherQuizAttempt.fromJson(Map<String, dynamic> json) =>
      TeacherQuizAttempt(
        id: _text(json['id']),
        studentName: _text(_map(json['student'])['full_name'], 'Siswa'),
        number: _integer(json['attempt_number'], 1),
        status: _text(json['status']),
        scorePoints: json['score_points'] is num
            ? json['score_points'] as num
            : null,
        maxPoints: json['max_points'] is num ? json['max_points'] as num : null,
        scorePercent: json['score_percent'] is num
            ? json['score_percent'] as num
            : null,
        startedAt: DateTime.tryParse(_text(json['started_at'])),
        submittedAt: DateTime.tryParse(_text(json['submitted_at'])),
        answers: json['answers'] is List
            ? (json['answers'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map(TeacherQuizAnswer.fromJson)
                  .toList()
            : const [],
      );
}

class TeacherQuizAnswer {
  const TeacherQuizAnswer({
    required this.questionId,
    required this.answerText,
    this.correct,
    this.awardedPoints,
    this.maxPoints,
  });
  final String questionId;
  final String answerText;
  final bool? correct;
  final num? awardedPoints;
  final num? maxPoints;
  factory TeacherQuizAnswer.fromJson(Map<String, dynamic> json) =>
      TeacherQuizAnswer(
        questionId: _text(json['quiz_question_id']),
        answerText: _text(
          json['answer_text'],
          _text(_map(json['selected_option'])['option_text'], '-'),
        ),
        correct: json['is_correct'] is bool ? json['is_correct'] as bool : null,
        awardedPoints: json['awarded_points'] is num
            ? json['awarded_points'] as num
            : null,
        maxPoints: json['max_points'] is num ? json['max_points'] as num : null,
      );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};
String? _nullableText(Object? value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

String _text(Object? value, [String fallback = '']) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;
int _integer(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
