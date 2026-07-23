class AdminProgressFilters {
  const AdminProgressFilters({
    this.search,
    this.schoolId,
    this.classId,
    this.learningStatus,
    this.quizStatus,
    this.analysisStatus,
    this.reviewStatus,
    this.dateFrom,
    this.dateTo,
  });

  final String? search;
  final String? schoolId;
  final String? classId;
  final String? learningStatus;
  final String? quizStatus;
  final String? analysisStatus;
  final String? reviewStatus;
  final String? dateFrom;
  final String? dateTo;

  Map<String, dynamic> query({
    required int studentPage,
    required int classPage,
  }) => {
    'student_page': studentPage,
    'class_page': classPage,
    if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
    if (schoolId?.isNotEmpty == true) 'school_id': schoolId,
    if (classId?.isNotEmpty == true) 'class_id': classId,
    if (learningStatus?.isNotEmpty == true) 'learning_status': learningStatus,
    if (quizStatus?.isNotEmpty == true) 'quiz_status': quizStatus,
    if (analysisStatus?.isNotEmpty == true) 'analysis_status': analysisStatus,
    if (reviewStatus?.isNotEmpty == true) 'review_status': reviewStatus,
    if (dateFrom?.isNotEmpty == true) 'date_from': dateFrom,
    if (dateTo?.isNotEmpty == true) 'date_to': dateTo,
  };
}

class AdminProgressMeta {
  const AdminProgressMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  factory AdminProgressMeta.fromJson(Map<String, dynamic>? json) =>
      AdminProgressMeta(
        currentPage: _int(json?['current_page'], 1),
        lastPage: _int(json?['last_page'], 1),
        perPage: _int(json?['per_page'], 0),
        total: _int(json?['total'], 0),
      );
}

class AdminProgressPage<T> {
  const AdminProgressPage({required this.items, required this.meta});
  final List<T> items;
  final AdminProgressMeta meta;
}

class AdminProgressSummary {
  const AdminProgressSummary({
    required this.activeStudents,
    required this.averageModuleProgressPercent,
    required this.averageBestFinalQuizScorePercent,
  });
  final int activeStudents;
  final double averageModuleProgressPercent;
  final double? averageBestFinalQuizScorePercent;
  factory AdminProgressSummary.fromJson(Map<String, dynamic> json) =>
      AdminProgressSummary(
        activeStudents: _int(json['active_students'], 0),
        averageModuleProgressPercent:
            _double(json['average_module_progress_percent']) ?? 0,
        averageBestFinalQuizScorePercent: _double(
          json['average_best_final_quiz_score_percent'],
        ),
      );
}

class AdminProgressStudent {
  const AdminProgressStudent({
    required this.id,
    required this.fullName,
    required this.email,
    required this.studentStatus,
    required this.learningStatus,
    required this.schoolId,
    required this.schoolName,
    required this.classId,
    required this.className,
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
    required this.averageBestQuizScorePercent,
    required this.lastLearningActivityAt,
    required this.lastQuizActivityAt,
  });
  final String id;
  final String fullName;
  final String email;
  final String studentStatus;
  final String learningStatus;
  final String schoolId;
  final String schoolName;
  final String classId;
  final String className;
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
  String? get lastActivityAt {
    final values = [
      lastLearningActivityAt,
      lastQuizActivityAt,
    ].whereType<String>().where((value) => value.isNotEmpty).toList()..sort();
    return values.isEmpty ? null : values.last;
  }

  factory AdminProgressStudent.fromJson(Map<String, dynamic> json) {
    final school = _map(json['school']);
    final schoolClass = _map(json['class']);
    return AdminProgressStudent(
      id: _string(json['student_id']),
      fullName: _string(json['full_name']),
      email: _string(json['email']),
      studentStatus: _string(json['student_status']),
      learningStatus: _string(json['learning_status']),
      schoolId: _string(school['id']),
      schoolName: _string(school['name']),
      classId: _string(schoolClass['id']),
      className: _string(schoolClass['name']),
      publishedModules: _int(json['published_modules'], 0),
      startedModules: _int(json['started_modules'], 0),
      completedModules: _int(json['completed_modules'], 0),
      inProgressModules: _int(json['in_progress_modules'], 0),
      notStartedModules: _int(json['not_started_modules'], 0),
      overallLearningProgressPercent:
          _double(json['overall_learning_progress_percent']) ?? 0,
      completedLessons: _int(json['completed_lessons'], 0),
      totalPublishedLessons: _int(json['total_published_lessons'], 0),
      publishedQuizzes: _int(json['published_quizzes'], 0),
      quizzesAttempted: _int(json['quizzes_attempted'], 0),
      quizzesCompleted: _int(json['quizzes_completed'], 0),
      submittedQuizCount: _int(json['submitted_quiz_count'], 0),
      averageBestQuizScorePercent: _double(
        json['average_best_quiz_score_percent'],
      ),
      lastLearningActivityAt: _nullableString(
        json['last_learning_activity_at'],
      ),
      lastQuizActivityAt: _nullableString(json['last_quiz_activity_at']),
    );
  }
}

class AdminProgressClass {
  const AdminProgressClass({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.schoolName,
    required this.activeStudents,
    required this.publishedModules,
    required this.averageLearningProgressPercent,
    required this.completedModuleCount,
    required this.publishedQuizzes,
    required this.studentsParticipatedInQuiz,
    required this.averageQuizScorePercent,
  });
  final String id;
  final String name;
  final String schoolId;
  final String schoolName;
  final int activeStudents;
  final int publishedModules;
  final double averageLearningProgressPercent;
  final int completedModuleCount;
  final int publishedQuizzes;
  final int studentsParticipatedInQuiz;
  final double? averageQuizScorePercent;
  factory AdminProgressClass.fromJson(Map<String, dynamic> json) =>
      AdminProgressClass(
        id: _string(json['class_id']),
        name: _string(json['class_name']),
        schoolId: _string(json['school_id']),
        schoolName: _string(json['school_name']),
        activeStudents: _int(json['active_students'], 0),
        publishedModules: _int(json['published_modules'], 0),
        averageLearningProgressPercent:
            _double(json['average_learning_progress_percent']) ?? 0,
        completedModuleCount: _int(json['completed_module_count'], 0),
        publishedQuizzes: _int(json['published_quizzes'], 0),
        studentsParticipatedInQuiz: _int(
          json['students_participated_in_quiz'],
          0,
        ),
        averageQuizScorePercent: _double(json['average_quiz_score_percent']),
      );
}

class AdminProgressSchool {
  const AdminProgressSchool({
    required this.id,
    required this.name,
    required this.activeClasses,
    required this.activeStudents,
    required this.averageLearningProgressPercent,
    required this.averageQuizScorePercent,
  });
  final String id;
  final String name;
  final int activeClasses;
  final int activeStudents;
  final double averageLearningProgressPercent;
  final double? averageQuizScorePercent;
  factory AdminProgressSchool.fromJson(Map<String, dynamic> json) =>
      AdminProgressSchool(
        id: _string(json['school_id']),
        name: _string(json['school_name']),
        activeClasses: _int(json['active_classes'], 0),
        activeStudents: _int(json['active_students'], 0),
        averageLearningProgressPercent:
            _double(json['average_learning_progress_percent']) ?? 0,
        averageQuizScorePercent: _double(json['average_quiz_score_percent']),
      );
}

class AdminQuizResultRow {
  const AdminQuizResultRow({
    required this.studentName,
    required this.quizTitle,
    required this.className,
    required this.attemptCount,
    required this.bestScorePercent,
    required this.latestStatus,
  });
  final String studentName;
  final String quizTitle;
  final String className;
  final int attemptCount;
  final double? bestScorePercent;
  final String? latestStatus;
  factory AdminQuizResultRow.fromJson(Map<String, dynamic> json) =>
      AdminQuizResultRow(
        studentName: _string(_map(json['student'])['full_name']),
        quizTitle: _string(_map(json['quiz'])['title']),
        className: _string(_map(json['class'])['name']),
        attemptCount: _int(json['attempt_count'], 0),
        bestScorePercent: _double(json['best_score_percent']),
        latestStatus: _nullableString(json['latest_status']),
      );
}

class AdminProgressOverview {
  const AdminProgressOverview({
    required this.summary,
    required this.students,
    required this.classes,
    required this.speakingReports,
  });
  final AdminProgressSummary summary;
  final AdminProgressPage<AdminProgressStudent> students;
  final AdminProgressPage<AdminProgressClass> classes;
  final bool speakingReports;
  factory AdminProgressOverview.fromJson(Map<String, dynamic> json) {
    final students = _map(json['students']);
    final classes = _map(json['classes']);
    return AdminProgressOverview(
      summary: AdminProgressSummary.fromJson(_map(json['summary'])),
      students: AdminProgressPage(
        items: _list(
          students['data'],
        ).map(AdminProgressStudent.fromJson).toList(),
        meta: AdminProgressMeta.fromJson(_map(students['meta'])),
      ),
      classes: AdminProgressPage(
        items: _list(classes['data']).map(AdminProgressClass.fromJson).toList(),
        meta: AdminProgressMeta.fromJson(_map(classes['meta'])),
      ),
      speakingReports: _map(json['capabilities'])['speaking_reports'] == true,
    );
  }
}

class AdminQuizProgress {
  const AdminQuizProgress({
    required this.quizId,
    required this.title,
    required this.showResult,
    required this.bestAttemptNumber,
    required this.attemptCount,
    required this.finalAttemptCount,
    required this.bestScorePercent,
    required this.latestStatus,
    required this.latestSubmittedAt,
  });
  final String quizId;
  final String title;
  final bool showResult;
  final int? bestAttemptNumber;
  final int attemptCount;
  final int finalAttemptCount;
  final double? bestScorePercent;
  final String? latestStatus;
  final String? latestSubmittedAt;
  factory AdminQuizProgress.fromJson(Map<String, dynamic> json) {
    final quiz = _map(json['quiz']);
    return AdminQuizProgress(
      quizId: _string(quiz['id']),
      title: _string(quiz['title']),
      showResult: quiz['show_result'] == true,
      bestAttemptNumber: _nullableInt(json['best_attempt_number']),
      attemptCount: _int(json['attempt_count'], 0),
      finalAttemptCount: _int(json['final_attempt_count'], 0),
      bestScorePercent: _double(json['best_score_percent']),
      latestStatus: _nullableString(json['latest_status']),
      latestSubmittedAt: _nullableString(json['latest_submitted_at']),
    );
  }
}

class AdminQuizSummary {
  const AdminQuizSummary({
    required this.eligibleStudents,
    required this.participatingStudents,
    required this.finalizedStudents,
    required this.notAttemptedStudents,
    required this.participationRatePercent,
    required this.completionRatePercent,
    required this.averageBestScorePercent,
    required this.highestBestScorePercent,
    required this.lowestBestScorePercent,
    required this.submittedAttempts,
    required this.expiredAttempts,
    required this.inProgressAttempts,
  });
  final int eligibleStudents;
  final int participatingStudents;
  final int finalizedStudents;
  final int notAttemptedStudents;
  final double participationRatePercent;
  final double completionRatePercent;
  final double? averageBestScorePercent;
  final double? highestBestScorePercent;
  final double? lowestBestScorePercent;
  final int submittedAttempts;
  final int expiredAttempts;
  final int inProgressAttempts;
  factory AdminQuizSummary.fromJson(Map<String, dynamic> json) =>
      AdminQuizSummary(
        eligibleStudents: _int(json['eligible_students'], 0),
        participatingStudents: _int(json['participating_students'], 0),
        finalizedStudents: _int(json['finalized_students'], 0),
        notAttemptedStudents: _int(json['not_attempted_students'], 0),
        participationRatePercent:
            _double(json['participation_rate_percent']) ?? 0,
        completionRatePercent: _double(json['completion_rate_percent']) ?? 0,
        averageBestScorePercent: _double(json['average_best_score_percent']),
        highestBestScorePercent: _double(json['highest_best_score_percent']),
        lowestBestScorePercent: _double(json['lowest_best_score_percent']),
        submittedAttempts: _int(json['submitted_attempts'], 0),
        expiredAttempts: _int(json['expired_attempts'], 0),
        inProgressAttempts: _int(json['in_progress_attempts'], 0),
      );
}

class AdminStudentIdentity {
  const AdminStudentIdentity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.status,
  });
  final String id;
  final String fullName;
  final String email;
  final String status;
  factory AdminStudentIdentity.fromJson(Map<String, dynamic> json) =>
      AdminStudentIdentity(
        id: _string(json['id']),
        fullName: _string(json['full_name']),
        email: _string(json['email']),
        status: _string(json['status']),
      );
}

class AdminStudentProgressDetail {
  const AdminStudentProgressDetail({
    required this.student,
    required this.progress,
    required this.quizzes,
    required this.quizSummary,
    required this.speakingReports,
  });
  final AdminStudentIdentity student;
  final AdminProgressStudent progress;
  final AdminProgressPage<AdminQuizProgress> quizzes;
  final AdminQuizSummary quizSummary;
  final bool speakingReports;
  factory AdminStudentProgressDetail.fromJson(Map<String, dynamic> json) {
    final quizzes = _map(json['quizzes']);
    return AdminStudentProgressDetail(
      student: AdminStudentIdentity.fromJson(_map(json['student'])),
      progress: AdminProgressStudent.fromJson(_map(json['progress'])),
      quizzes: AdminProgressPage(
        items: _list(quizzes['data']).map(AdminQuizProgress.fromJson).toList(),
        meta: AdminProgressMeta.fromJson(_map(quizzes['meta'])),
      ),
      quizSummary: AdminQuizSummary.fromJson(_map(json['quiz_summary'])),
      speakingReports: _map(json['capabilities'])['speaking_reports'] == true,
    );
  }
}

class AdminClassIdentity {
  const AdminClassIdentity({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.status,
    required this.schoolId,
    required this.schoolName,
    required this.teacherId,
    required this.teacherName,
    required this.teacherEmail,
  });
  final String id;
  final String name;
  final String academicYear;
  final String status;
  final String schoolId;
  final String schoolName;
  final String? teacherId;
  final String? teacherName;
  final String? teacherEmail;
  factory AdminClassIdentity.fromJson(Map<String, dynamic> json) {
    final school = _map(json['school']);
    final teacher = _map(json['teacher']);
    return AdminClassIdentity(
      id: _string(json['id']),
      name: _string(json['name']),
      academicYear: _string(json['academic_year']),
      status: _string(json['status']),
      schoolId: _string(school['id']),
      schoolName: _string(school['name']),
      teacherId: _nullableString(teacher['id']),
      teacherName: _nullableString(teacher['full_name']),
      teacherEmail: _nullableString(teacher['email']),
    );
  }
}

class AdminClassProgressSummary {
  const AdminClassProgressSummary({
    required this.activeStudents,
    required this.averageModuleProgressPercent,
    required this.averageBestFinalQuizScorePercent,
    required this.lastActivityAt,
    required this.completedStudents,
    required this.notStartedStudents,
  });
  final int activeStudents;
  final double averageModuleProgressPercent;
  final double? averageBestFinalQuizScorePercent;
  final String? lastActivityAt;
  final int completedStudents;
  final int notStartedStudents;
  factory AdminClassProgressSummary.fromJson(Map<String, dynamic> json) =>
      AdminClassProgressSummary(
        activeStudents: _int(json['active_students'], 0),
        averageModuleProgressPercent:
            _double(json['average_module_progress_percent']) ?? 0,
        averageBestFinalQuizScorePercent: _double(
          json['average_best_final_quiz_score_percent'],
        ),
        lastActivityAt: _nullableString(json['last_activity_at']),
        completedStudents: _int(json['completed_students'], 0),
        notStartedStudents: _int(json['not_started_students'], 0),
      );
}

class AdminClassProgressDetail {
  const AdminClassProgressDetail({
    required this.schoolClass,
    required this.summary,
    required this.students,
    required this.speakingReports,
  });
  final AdminClassIdentity schoolClass;
  final AdminClassProgressSummary summary;
  final AdminProgressPage<AdminProgressStudent> students;
  final bool speakingReports;
  factory AdminClassProgressDetail.fromJson(Map<String, dynamic> json) {
    final students = _map(json['students']);
    return AdminClassProgressDetail(
      schoolClass: AdminClassIdentity.fromJson(_map(json['class'])),
      summary: AdminClassProgressSummary.fromJson(_map(json['summary'])),
      students: AdminProgressPage(
        items: _list(
          students['data'],
        ).map(AdminProgressStudent.fromJson).toList(),
        meta: AdminProgressMeta.fromJson(_map(students['meta'])),
      ),
      speakingReports: _map(json['capabilities'])['speaking_reports'] == true,
    );
  }
}

class AdminSpeakingStudentSummary {
  const AdminSpeakingStudentSummary({
    required this.id,
    required this.name,
    required this.attemptCount,
    required this.analyzedAttempts,
    required this.reviewedAttempts,
    required this.averageAiScore,
    required this.averageTeacherScore,
  });
  final String id;
  final String name;
  final int attemptCount;
  final int analyzedAttempts;
  final int reviewedAttempts;
  final double? averageAiScore;
  final double? averageTeacherScore;
  factory AdminSpeakingStudentSummary.fromJson(Map<String, dynamic> json) =>
      AdminSpeakingStudentSummary(
        id: _string(json['student_id']),
        name: _string(json['full_name']),
        attemptCount: _int(json['attempt_count'], 0),
        analyzedAttempts: _int(json['analyzed_attempts'], 0),
        reviewedAttempts: _int(json['reviewed_attempts'], 0),
        averageAiScore: _double(json['average_ai_score']),
        averageTeacherScore: _double(json['average_teacher_score']),
      );
}

class AdminSpeakingClassSummary {
  const AdminSpeakingClassSummary({
    required this.id,
    required this.name,
    required this.schoolName,
    required this.attemptCount,
    required this.participatingStudents,
    required this.averageAiScore,
    required this.averageTeacherScore,
  });
  final String id;
  final String name;
  final String schoolName;
  final int attemptCount;
  final int participatingStudents;
  final double? averageAiScore;
  final double? averageTeacherScore;
  factory AdminSpeakingClassSummary.fromJson(Map<String, dynamic> json) =>
      AdminSpeakingClassSummary(
        id: _string(json['class_id']),
        name: _string(json['class_name']),
        schoolName: _string(json['school_name']),
        attemptCount: _int(json['attempt_count'], 0),
        participatingStudents: _int(json['participating_students'], 0),
        averageAiScore: _double(json['average_ai_score']),
        averageTeacherScore: _double(json['average_teacher_score']),
      );
}

String adminProgressStatus(String? value) => switch (value) {
  'not_started' => 'Belum mulai',
  'in_progress' => 'Sedang berjalan',
  'completed' => 'Selesai',
  'submitted' => 'Dikirim',
  'expired' => 'Kedaluwarsa',
  'pending' => 'Menunggu',
  'processing' => 'Diproses',
  'failed' => 'Gagal',
  'reviewed' => 'Sudah diulas',
  'approved' => 'Aktif',
  'active' => 'Aktif',
  'inactive' => 'Tidak aktif',
  null || '' => 'Belum tersedia',
  _ => 'Status belum dikenal',
};
String adminProgressPercent(num? value) => value == null
    ? 'Belum tersedia'
    : '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}%';
String adminProgressDate(String? value) {
  if (value == null || value.isEmpty) return 'Belum tersedia';
  final date = DateTime.tryParse(value);
  if (date == null) return 'Belum tersedia';
  final local = date.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

double adminProgressValue(num value) => (value / 100).clamp(0, 1).toDouble();

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> _list(Object? value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((e) => Map<String, dynamic>.from(e))
    .toList();
String _string(Object? value) => value?.toString().trim() ?? '';
String? _nullableString(Object? value) {
  final result = _string(value);
  return result.isEmpty ? null : result;
}

int _int(Object? value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
int? _nullableInt(Object? value) => value == null ? null : _int(value, 0);
double? _double(Object? value) => value == null
    ? null
    : value is num
    ? value.toDouble()
    : double.tryParse('$value');
