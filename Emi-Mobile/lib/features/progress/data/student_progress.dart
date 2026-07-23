class StudentProgressReport {
  const StudentProgressReport({required this.summary, required this.modules});

  final StudentProgressSummary? summary;
  final StudentProgressModulePage modules;

  bool get isEmpty => summary == null && modules.items.isEmpty;

  factory StudentProgressReport.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final source = data is Map<String, dynamic> ? data : json;
    final summary = source['summary'];
    return StudentProgressReport(
      summary: summary is Map<String, dynamic>
          ? StudentProgressSummary.fromJson(summary)
          : null,
      modules: StudentProgressModulePage.fromJson(
        source['modules'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class StudentProgressSummary {
  const StudentProgressSummary({
    required this.studentId,
    required this.fullName,
    required this.publishedModules,
    required this.startedModules,
    required this.completedModules,
    required this.inProgressModules,
    required this.notStartedModules,
    required this.overallLearningProgressPercent,
    required this.completedLessons,
    required this.totalPublishedLessons,
    required this.publishedQuizzes,
    required this.quizzesAttempted,
    required this.quizzesCompleted,
    required this.submittedQuizCount,
    this.averageBestQuizScorePercent,
    this.lastLearningActivityAt,
    this.lastQuizActivityAt,
    this.schoolName,
    this.className,
  });

  final String studentId;
  final String fullName;
  final String? schoolName;
  final String? className;
  final int publishedModules;
  final int startedModules;
  final int completedModules;
  final int inProgressModules;
  final int notStartedModules;
  final double overallLearningProgressPercent;
  final int completedLessons;
  final int totalPublishedLessons;
  final int publishedQuizzes;
  final int quizzesAttempted;
  final int quizzesCompleted;
  final int submittedQuizCount;
  final double? averageBestQuizScorePercent;
  final String? lastLearningActivityAt;
  final String? lastQuizActivityAt;

  factory StudentProgressSummary.fromJson(Map<String, dynamic> json) {
    final school = json['school'];
    final schoolClass = json['class'];
    return StudentProgressSummary(
      studentId: json['student_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '-',
      schoolName: school is Map<String, dynamic>
          ? school['name'] as String?
          : null,
      className: schoolClass is Map<String, dynamic>
          ? schoolClass['name'] as String?
          : null,
      publishedModules: _int(json['published_modules']),
      startedModules: _int(json['started_modules']),
      completedModules: _int(json['completed_modules']),
      inProgressModules: _int(json['in_progress_modules']),
      notStartedModules: _int(json['not_started_modules']),
      overallLearningProgressPercent: _double(
        json['overall_learning_progress_percent'],
      ),
      completedLessons: _int(json['completed_lessons']),
      totalPublishedLessons: _int(json['total_published_lessons']),
      publishedQuizzes: _int(json['published_quizzes']),
      quizzesAttempted: _int(json['quizzes_attempted']),
      quizzesCompleted: _int(json['quizzes_completed']),
      submittedQuizCount: _int(json['submitted_quiz_count']),
      averageBestQuizScorePercent: _nullableDouble(
        json['average_best_quiz_score_percent'] ??
            json['average_quiz_score_out_of_100'],
      ),
      lastLearningActivityAt: json['last_learning_activity_at']?.toString(),
      lastQuizActivityAt: json['last_quiz_activity_at']?.toString(),
    );
  }
}

String studentProgressStatus(String? value) => switch (value) {
  'not_started' => 'Belum mulai',
  'in_progress' => 'Sedang berjalan',
  'completed' => 'Selesai',
  null || '' => '-',
  _ => 'Status belum dikenal',
};

class StudentProgressModule {
  const StudentProgressModule({
    required this.id,
    required this.title,
    required this.status,
    required this.progressPercent,
    required this.completedLessons,
    required this.totalLessons,
    required this.sortOrder,
    this.lastCalculatedAt,
  });

  final String id;
  final String title;
  final String status;
  final double progressPercent;
  final int completedLessons;
  final int totalLessons;
  final int sortOrder;
  final String? lastCalculatedAt;

  factory StudentProgressModule.fromJson(Map<String, dynamic> json) {
    return StudentProgressModule(
      id: json['id'] as String? ?? json['class_module_id'] as String? ?? '',
      title: json['title'] as String? ?? '-',
      status: json['status'] as String? ?? 'not_started',
      progressPercent: _double(json['progress_percent']),
      completedLessons: _int(json['completed_lessons']),
      totalLessons: _int(json['total_lessons']),
      sortOrder: _int(json['sort_order']),
      lastCalculatedAt: json['last_calculated_at']?.toString(),
    );
  }
}

class StudentProgressModulePage {
  const StudentProgressModulePage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<StudentProgressModule> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;

  factory StudentProgressModulePage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];
    return StudentProgressModulePage(
      items: data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map(StudentProgressModule.fromJson)
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

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(Object? value) => _nullableDouble(value) ?? 0;

double? _nullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
