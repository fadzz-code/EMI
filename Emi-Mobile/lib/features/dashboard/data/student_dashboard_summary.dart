class StudentDashboardSummary {
  const StudentDashboardSummary({
    required this.emptyState,
    required this.learning,
    required this.quizzes,
    this.classInfo,
  });

  final bool emptyState;
  final StudentClassInfo? classInfo;
  final DashboardLearning learning;
  final DashboardQuizzes quizzes;

  factory StudentDashboardSummary.fromJson(Map<String, dynamic> json) {
    return StudentDashboardSummary(
      emptyState: json['empty_state'] == true,
      classInfo: json['class'] is Map<String, dynamic>
          ? StudentClassInfo.fromJson(json['class'] as Map<String, dynamic>)
          : null,
      learning: DashboardLearning.fromJson(
        json['learning'] as Map<String, dynamic>? ?? const {},
      ),
      quizzes: DashboardQuizzes.fromJson(
        json['quizzes'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class StudentClassInfo {
  const StudentClassInfo({
    required this.id,
    required this.name,
    this.schoolName,
  });

  final String id;
  final String name;
  final String? schoolName;

  factory StudentClassInfo.fromJson(Map<String, dynamic> json) {
    final school = json['school'];
    return StudentClassInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '-',
      schoolName: school is Map<String, dynamic>
          ? school['name'] as String?
          : null,
    );
  }
}

class DashboardLearning {
  const DashboardLearning({
    required this.publishedModules,
    required this.notStartedModules,
    required this.inProgressModules,
    required this.completedModules,
    required this.overallProgressPercent,
    required this.completedLessons,
    required this.totalLessons,
  });

  final int publishedModules;
  final int notStartedModules;
  final int inProgressModules;
  final int completedModules;
  final int overallProgressPercent;
  final int completedLessons;
  final int totalLessons;

  factory DashboardLearning.fromJson(Map<String, dynamic> json) {
    return DashboardLearning(
      publishedModules: _int(json['published_modules']),
      notStartedModules: _int(json['not_started_modules']),
      inProgressModules: _int(json['in_progress_modules']),
      completedModules: _int(json['completed_modules']),
      overallProgressPercent: _int(json['overall_progress_percent']),
      completedLessons: _int(json['completed_lessons']),
      totalLessons: _int(json['total_lessons']),
    );
  }
}

class DashboardQuizzes {
  const DashboardQuizzes({
    required this.available,
    required this.upcoming,
    required this.inProgressAttempts,
    required this.completed,
    this.visibleAverageScore,
  });

  final int available;
  final int upcoming;
  final int inProgressAttempts;
  final int completed;
  final int? visibleAverageScore;

  factory DashboardQuizzes.fromJson(Map<String, dynamic> json) {
    return DashboardQuizzes(
      available: _int(json['available']),
      upcoming: _int(json['upcoming']),
      inProgressAttempts: _int(json['in_progress_attempts']),
      completed: _int(json['completed']),
      visibleAverageScore: json['visible_average_score'] == null
          ? null
          : _int(json['visible_average_score']),
    );
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
