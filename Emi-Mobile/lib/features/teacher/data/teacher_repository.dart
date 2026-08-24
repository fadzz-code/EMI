import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import '../../culture/data/culture_models.dart';
import '../../speaking/data/speaking_models.dart';

class TeacherRequestItem {
  const TeacherRequestItem({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.className,
    this.schoolName,
    this.reviewNote,
  });
  final String id;
  final String name;
  final String email;
  final String status;
  final String? className;
  final String? schoolName;
  final String? reviewNote;

  factory TeacherRequestItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final schoolClass = json['school_class'] is Map<String, dynamic>
        ? json['school_class'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final school = json['school'] is Map<String, dynamic>
        ? json['school'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return TeacherRequestItem(
      id: json['id'] as String? ?? '',
      name: user['full_name'] as String? ?? 'Siswa',
      email: user['email'] as String? ?? '-',
      status: json['status'] as String? ?? 'pending',
      className: schoolClass['name'] as String?,
      schoolName: school['name'] as String?,
      reviewNote: json['review_note'] as String?,
    );
  }
}

class TeacherRequestPage {
  const TeacherRequestPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<TeacherRequestItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  factory TeacherRequestPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'];
    final meta = _map(json?['meta']);
    final items = rows is List
        ? rows
              .whereType<Map<String, dynamic>>()
              .map(TeacherRequestItem.fromJson)
              .toList()
        : <TeacherRequestItem>[];
    return TeacherRequestPage(
      items: items,
      currentPage: _int(meta['current_page'], fallback: 1),
      lastPage: _int(meta['last_page'], fallback: 1),
      total: _int(meta['total'], fallback: items.length),
    );
  }
}

class TeacherLessonContent {
  const TeacherLessonContent({required this.type, this.contentBody, this.url});
  final String type;
  final String? contentBody;
  final String? url;
  factory TeacherLessonContent.fromJson(Map<String, dynamic> json) =>
      TeacherLessonContent(
        type: json['type'] as String? ?? 'text',
        contentBody: json['content_body'] as String?,
        url: json['url'] as String?,
      );
}

class TeacherMetric {
  const TeacherMetric({
    required this.label,
    required this.value,
    required this.iconName,
  });

  final String label;
  final String value;
  final String iconName;
}

class TeacherActivity {
  const TeacherActivity({
    required this.type,
    required this.studentName,
    required this.title,
    this.occurredAt,
  });

  final String type;
  final String studentName;
  final String title;
  final DateTime? occurredAt;
}

class TeacherDashboardSummary {
  const TeacherDashboardSummary({
    required this.emptyState,
    required this.metrics,
    required this.activities,
    this.classId,
    this.className,
    this.schoolName,
  });

  final bool emptyState;
  final String? classId;
  final String? className;
  final String? schoolName;
  final List<TeacherMetric> metrics;
  final List<TeacherActivity> activities;

  factory TeacherDashboardSummary.fromJson(Map<String, dynamic> json) {
    final klass = _map(json['class']);
    final school = _map(klass['school']);
    final students = _map(json['students']);
    final learning = _map(json['learning']);
    final quizzes = _map(json['quizzes']);
    final activities = json['recent_activity'] is List
        ? (json['recent_activity'] as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => TeacherActivity(
                  type: _string(item['type']),
                  studentName: _string(item['student_name'], fallback: 'Siswa'),
                  title: _string(item['title'], fallback: 'Aktivitas belajar'),
                  occurredAt: DateTime.tryParse(_string(item['occurred_at'])),
                ),
              )
              .toList()
        : const <TeacherActivity>[];
    final progress = _number(learning['average_progress_percent']);
    return TeacherDashboardSummary(
      emptyState: _bool(json['empty_state']),
      classId: _nullableString(klass['id']),
      className: _nullableString(klass['name']),
      schoolName: _nullableString(school['name']),
      metrics: [
        TeacherMetric(
          label: 'Kelas',
          value: klass.isEmpty ? '0' : '1',
          iconName: 'class',
        ),
        TeacherMetric(
          label: 'Siswa Aktif',
          value: '${_int(students['active'])}',
          iconName: 'students',
        ),
        TeacherMetric(
          label: 'Modul Terbit',
          value: '${_int(learning['published_modules'])}',
          iconName: 'learning',
        ),
        TeacherMetric(
          label: 'Kuis Terbit',
          value: '${_int(quizzes['published_quizzes'])}',
          iconName: 'quiz',
        ),
        TeacherMetric(
          label: 'Progress',
          value: '${progress.toStringAsFixed(0)}%',
          iconName: 'progress',
        ),
      ],
      activities: activities,
    );
  }
}

class TeacherClass {
  const TeacherClass({
    required this.id,
    required this.name,
    required this.status,
    required this.studentsCount,
    this.schoolName,
    this.gradeLevel,
    this.academicYear,
    this.teacherName,
  });

  final String id;
  final String name;
  final String status;
  final int studentsCount;
  final String? schoolName;
  final String? gradeLevel;
  final String? academicYear;
  final String? teacherName;

  factory TeacherClass.fromJson(Map<String, dynamic> json) {
    final school = _map(json['school']);
    final assignment = _map(json['active_teacher_assignment']);
    final teacher = _map(assignment['teacher']);
    return TeacherClass(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Kelas tanpa nama'),
      status: _string(json['status']),
      studentsCount: _int(json['active_students_count']),
      schoolName: _nullableString(school['name'] ?? json['school_name']),
      gradeLevel: _nullableString(json['grade_level']),
      academicYear: _nullableString(json['academic_year']),
      teacherName: _nullableString(teacher['full_name']),
    );
  }
}

class TeacherClassPage {
  const TeacherClassPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<TeacherClass> items;
  final int currentPage;
  final int lastPage;
  final int total;

  factory TeacherClassPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'];
    final meta = _map(json?['meta']);
    final items = rows is List
        ? rows
              .whereType<Map<String, dynamic>>()
              .map(TeacherClass.fromJson)
              .toList()
        : <TeacherClass>[];
    return TeacherClassPage(
      items: items,
      currentPage: _int(meta['current_page'], fallback: 1),
      lastPage: _int(meta['last_page'], fallback: 1),
      total: _int(meta['total'], fallback: items.length),
    );
  }
}

class TeacherClassStudent {
  const TeacherClassStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String email;
  final String status;
  final DateTime? joinedAt;

  factory TeacherClassStudent.fromJson(Map<String, dynamic> json) {
    final student = _map(json['student']);
    return TeacherClassStudent(
      id: _string(student['id']),
      name: _string(student['full_name'], fallback: 'Nama belum tersedia'),
      email: _string(student['email'], fallback: 'Email belum tersedia'),
      status: _string(student['status']),
      joinedAt: DateTime.tryParse(_string(json['joined_at'])),
    );
  }
}

class TeacherClassStudentPage {
  const TeacherClassStudentPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<TeacherClassStudent> items;
  final int currentPage;
  final int lastPage;
  final int total;

  factory TeacherClassStudentPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'];
    final meta = _map(json?['meta']);
    final items = rows is List
        ? rows
              .whereType<Map<String, dynamic>>()
              .map(TeacherClassStudent.fromJson)
              .toList()
        : <TeacherClassStudent>[];
    return TeacherClassStudentPage(
      items: items,
      currentPage: _int(meta['current_page'], fallback: 1),
      lastPage: _int(meta['last_page'], fallback: 1),
      total: _int(meta['total'], fallback: items.length),
    );
  }
}

class TeacherModule {
  const TeacherModule({
    required this.id,
    this.classId,
    required this.title,
    required this.description,
    required this.status,
    required this.sortOrder,
    required this.lessons,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final int sortOrder;
  final List<TeacherLesson> lessons;

  final String? classId;

  factory TeacherModule.fromJson(Map<String, dynamic> json) => TeacherModule(
    id: _string(json['id']),
    classId: _nullableString(json['class_id']),
    title: _string(json['title'], fallback: 'Modul tanpa judul'),
    description: _string(json['description']),
    status: _string(json['status'], fallback: 'draft'),
    sortOrder: _int(json['sort_order'], fallback: 1),
    lessons: json['lessons'] is List
        ? (json['lessons'] as List)
              .whereType<Map<String, dynamic>>()
              .map(TeacherLesson.fromJson)
              .toList()
        : const [],
  );
}

class TeacherLesson {
  const TeacherLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    required this.contentBody,
    required this.externalUrl,
    required this.mediaId,
    required this.mediaName,
    required this.mediaType,
    required this.sortOrder,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final String contentType;
  final String contentBody;
  final String? externalUrl;
  final String? mediaId;
  final String? mediaName;
  final String? mediaType;
  final int sortOrder;
  final String status;

  factory TeacherLesson.fromJson(Map<String, dynamic> json) {
    final media = _map(json['media']);
    return TeacherLesson(
      id: _string(json['id']),
      title: _string(json['title'], fallback: 'Materi tanpa judul'),
      description: _string(json['description']),
      contentType: _string(json['content_type'], fallback: 'text'),
      contentBody: _string(json['content_body']),
      externalUrl: _nullableString(json['external_url']),
      mediaId: _nullableString(media['id'] ?? json['media_id']),
      mediaName: _nullableString(media['original_name']),
      mediaType: _nullableString(media['mime_type']),
      sortOrder: _int(json['sort_order'], fallback: 1),
      status: _string(json['status'], fallback: 'draft'),
    );
  }
}

class TeacherStudentProgress {
  const TeacherStudentProgress({
    required this.studentId,
    required this.name,
    required this.classId,
    required this.className,
    required this.schoolName,
    required this.learningStatus,
    required this.percent,
    required this.completedModules,
    required this.startedModules,
    required this.publishedModules,
    required this.completedLessons,
    required this.publishedLessons,
    required this.completedQuizzes,
    required this.attemptedQuizzes,
    required this.publishedQuizzes,
    required this.averageQuizScore,
    required this.lastLearningActivityAt,
    required this.lastQuizActivityAt,
  });

  final String studentId;
  final String name;
  final String classId;
  final String className;
  final String schoolName;
  final String learningStatus;
  final double percent;
  final int completedModules;
  final int startedModules;
  final int publishedModules;
  final int completedLessons;
  final int publishedLessons;
  final int completedQuizzes;
  final int attemptedQuizzes;
  final int publishedQuizzes;
  final double? averageQuizScore;
  final DateTime? lastLearningActivityAt;
  final DateTime? lastQuizActivityAt;

  factory TeacherStudentProgress.fromJson(Map<String, dynamic> json) {
    final klass = _map(json['class']);
    final school = _map(json['school']);
    return TeacherStudentProgress(
      studentId: _string(json['student_id']),
      name: _string(json['full_name'], fallback: 'Nama belum tersedia'),
      classId: _string(klass['id']),
      className: _string(klass['name'], fallback: 'Kelas belum tersedia'),
      schoolName: _string(school['name'], fallback: 'Sekolah belum tersedia'),
      learningStatus: _string(json['learning_status']),
      percent: _number(json['overall_learning_progress_percent']),
      completedModules: _int(json['completed_modules']),
      startedModules: _int(json['started_modules']),
      publishedModules: _int(json['published_modules']),
      completedLessons: _int(json['completed_lessons']),
      publishedLessons: _int(json['total_published_lessons']),
      completedQuizzes: _int(json['quizzes_completed']),
      attemptedQuizzes: _int(json['quizzes_attempted']),
      publishedQuizzes: _int(json['published_quizzes']),
      averageQuizScore: _nullableNumber(
        json['average_best_quiz_score_percent'],
      ),
      lastLearningActivityAt: DateTime.tryParse(
        _string(json['last_learning_activity_at']),
      ),
      lastQuizActivityAt: DateTime.tryParse(
        _string(json['last_quiz_activity_at']),
      ),
    );
  }
}

class TeacherStudentProgressPage {
  const TeacherStudentProgressPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<TeacherStudentProgress> items;
  final int currentPage;
  final int lastPage;
  final int total;

  factory TeacherStudentProgressPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'];
    final meta = _map(json?['meta']);
    final items = rows is List
        ? rows
              .whereType<Map<String, dynamic>>()
              .map(TeacherStudentProgress.fromJson)
              .toList()
        : <TeacherStudentProgress>[];
    return TeacherStudentProgressPage(
      items: items,
      currentPage: _int(meta['current_page'], fallback: 1),
      lastPage: _int(meta['last_page'], fallback: 1),
      total: _int(meta['total'], fallback: items.length),
    );
  }
}

class TeacherMediaUpload {
  const TeacherMediaUpload({required this.id, required this.name});

  final String id;
  final String name;
}

class TeacherSpeakingTemplate {
  const TeacherSpeakingTemplate({
    required this.id,
    required this.title,
    required this.targetText,
    this.targetTranslation,
    this.promptText,
    this.difficulty,
    this.referenceAudioMediaId,
    this.referenceAudio,
  });
  final String id, title, targetText;
  final String? targetTranslation,
      promptText,
      difficulty,
      referenceAudioMediaId;
  final SpeakingReferenceAudio? referenceAudio;
  factory TeacherSpeakingTemplate.fromJson(Map<String, dynamic> json) =>
      TeacherSpeakingTemplate(
        id: _string(json['id']),
        title: _string(json['title'], fallback: 'Latihan tanpa judul'),
        targetText: _string(json['target_text']),
        targetTranslation: _nullableString(json['target_translation']),
        promptText: _nullableString(json['prompt_text']),
        difficulty: _nullableString(json['difficulty']),
        referenceAudioMediaId: _nullableString(
          json['reference_audio_media_id'],
        ),
        referenceAudio: json['reference_audio'] is Map<String, dynamic>
            ? SpeakingReferenceAudio.fromJson(
                json['reference_audio'] as Map<String, dynamic>,
              )
            : null,
      );
}

class TeacherSpeakingExercise {
  const TeacherSpeakingExercise({
    required this.id,
    required this.classroomId,
    required this.title,
    required this.targetText,
    required this.status,
    this.classroomName,
    this.targetTranslation,
    this.promptText,
    this.difficulty,
    this.referenceAudioMediaId,
    this.referenceAudio,
    this.updatedAt,
    this.attemptsCount,
  });
  final String id, classroomId, title, targetText, status;
  final String? classroomName,
      targetTranslation,
      promptText,
      difficulty,
      referenceAudioMediaId;
  final SpeakingReferenceAudio? referenceAudio;
  final DateTime? updatedAt;
  final int? attemptsCount;
  factory TeacherSpeakingExercise.fromJson(Map<String, dynamic> json) {
    final classroom = _map(json['classroom'] ?? json['class']);
    return TeacherSpeakingExercise(
      id: _string(json['id']),
      classroomId: _string(json['classroom_id'] ?? classroom['id']),
      title: _string(json['title'], fallback: 'Latihan tanpa judul'),
      targetText: _string(json['target_text']),
      status: _string(json['status'], fallback: 'draft'),
      classroomName: _nullableString(
        classroom['name'] ?? json['classroom_name'],
      ),
      targetTranslation: _nullableString(json['target_translation']),
      promptText: _nullableString(json['prompt_text']),
      difficulty: _nullableString(json['difficulty']),
      referenceAudioMediaId: _nullableString(json['reference_audio_media_id']),
      referenceAudio: json['reference_audio'] is Map<String, dynamic>
          ? SpeakingReferenceAudio.fromJson(
              json['reference_audio'] as Map<String, dynamic>,
            )
          : null,
      updatedAt: DateTime.tryParse(_string(json['updated_at'])),
      attemptsCount: json['attempts_count'] is num
          ? (json['attempts_count'] as num).toInt()
          : null,
    );
  }
}

class TeacherSpeakingAttemptPage {
  const TeacherSpeakingAttemptPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.pendingCount,
    required this.reviewedCount,
    required this.failedCount,
  });

  final List<TeacherSpeakingAttempt> items;
  final int currentPage,
      lastPage,
      total,
      pendingCount,
      reviewedCount,
      failedCount;

  factory TeacherSpeakingAttemptPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'];
    final meta = _map(json?['meta']);
    final counts = _map(meta['counts']);
    final items = rows is List
        ? rows
              .whereType<Map<String, dynamic>>()
              .map(TeacherSpeakingAttempt.fromJson)
              .toList()
        : <TeacherSpeakingAttempt>[];
    final currentPage = _int(meta['current_page'], fallback: 1);
    final lastPage = _int(meta['last_page'], fallback: 1);
    return TeacherSpeakingAttemptPage(
      items: items,
      currentPage: currentPage < 1 ? 1 : currentPage,
      lastPage: lastPage < 1 ? 1 : lastPage,
      total: _int(
        counts['total'],
        fallback: _int(meta['total'], fallback: items.length),
      ),
      pendingCount: _int(counts['pending']),
      reviewedCount: _int(counts['reviewed']),
      failedCount: _int(counts['failed']),
    );
  }
}

class TeacherSpeakingAttempt {
  const TeacherSpeakingAttempt({
    required this.id,
    required this.studentName,
    required this.exerciseTitle,
    this.classroomName,
    this.audioMediaId,
    this.targetText,
    this.referenceAudio,
    this.transcription,
    this.aiAlignment,
    this.aiError,
    this.aiScore,
    this.teacherScore,
    this.teacherFeedback,
    this.status,
    this.captureSource,
    this.reviewStatus,
    this.submittedAt,
    this.createdAt,
  });
  final String id, studentName, exerciseTitle;
  final String? classroomName,
      audioMediaId,
      targetText,
      transcription,
      aiError,
      teacherFeedback,
      status,
      captureSource,
      reviewStatus;
  final SpeakingReferenceAudio? referenceAudio;
  final Object? aiAlignment;
  final double? aiScore, teacherScore;
  final DateTime? submittedAt, createdAt;
  bool get isReviewed => reviewStatus == 'reviewed' || teacherScore != null;
  bool get isSubmitted => submittedAt != null;
  bool get canDelete => isSubmitted && !isReviewed;
  factory TeacherSpeakingAttempt.fromJson(Map<String, dynamic> json) {
    final student = _map(json['student']);
    final exercise = _map(json['exercise']);
    final classroom = _map(json['classroom'] ?? exercise['classroom']);
    double? number(Object? value) => value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value)
        : null;
    return TeacherSpeakingAttempt(
      id: _string(json['id']),
      studentName: _string(
        student['full_name'] ?? json['student_name'],
        fallback: 'Siswa',
      ),
      exerciseTitle: _string(
        exercise['title'] ?? json['exercise_title'],
        fallback: 'Latihan speaking',
      ),
      classroomName: _nullableString(
        classroom['name'] ?? json['classroom_name'],
      ),
      audioMediaId: _nullableString(
        json['audio_media_id'] ??
            _map(json['audio_media'])['id'] ??
            _map(json['media'])['id'],
      ),
      targetText: _nullableString(
        json['target_text'] ?? json['target_text_snapshot'],
      ),
      referenceAudio: exercise['reference_audio'] is Map<String, dynamic>
          ? SpeakingReferenceAudio.fromJson(
              exercise['reference_audio'] as Map<String, dynamic>,
            )
          : null,
      transcription: _nullableString(
        json['ai_transcription'] ?? json['transcription'],
      ),
      aiAlignment: json['ai_alignment'] ?? _map(json['analysis'])['alignment'],
      aiError: _nullableString(
        json['ai_error'] ?? _map(json['analysis'])['error'],
      ),
      aiScore: number(json['ai_score']),
      teacherScore: number(json['teacher_score']),
      teacherFeedback: _nullableString(json['teacher_feedback']),
      status: _nullableString(json['status']),
      captureSource: _nullableString(json['capture_source']),
      reviewStatus: _nullableString(
        json['review_status'] ?? _map(json['review'])['status'],
      ),
      submittedAt: DateTime.tryParse(_string(json['submitted_at'])),
      createdAt: DateTime.tryParse(
        _string(json['created_at'] ?? json['submitted_at']),
      ),
    );
  }
}

class TeacherRepository {
  const TeacherRepository(this._dio, this._mapper);

  final Dio _dio;
  final DioErrorMapper _mapper;

  Future<TeacherRequestPage> registrationRequests({
    int page = 1,
    String? search,
    String? status,
  }) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/teacher/registration-requests',
      queryParameters: {
        'page': page,
        'per_page': 15,
        'status': status?.isNotEmpty == true ? status : 'pending',
        'sort_by': 'created_at',
        'sort_order': 'desc',
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
      },
    ),
    TeacherRequestPage.fromJson,
  );

  Future<TeacherRequestItem> registrationRequest(String id) => _request(
    () => _dio.get<Map<String, dynamic>>('/teacher/registration-requests/$id'),
    _requestItem,
  );

  Future<void> approveRegistrationRequest(String id, {String? reviewNote}) =>
      _request(
        () => _dio.post<Map<String, dynamic>>(
          '/teacher/registration-requests/$id/approve',
          data: {
            if (reviewNote?.trim().isNotEmpty == true)
              'review_note': reviewNote!.trim(),
          },
        ),
        (_) {},
      );

  Future<TeacherRequestPage> passwordResetRequests({
    int page = 1,
    String? search,
    String? status,
  }) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/teacher/password-reset-requests',
      queryParameters: {
        'page': page,
        'per_page': 15,
        'status': status?.isNotEmpty == true ? status : 'pending',
        'sort_by': 'created_at',
        'sort_direction': 'desc',
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
      },
    ),
    TeacherRequestPage.fromJson,
  );

  Future<TeacherRequestItem> passwordResetRequest(String id) => _request(
    () =>
        _dio.get<Map<String, dynamic>>('/teacher/password-reset-requests/$id'),
    _requestItem,
  );

  Future<void> approvePasswordResetRequest(
    String id,
    String password,
    String confirmation,
  ) => _request(
    () => _dio.post<Map<String, dynamic>>(
      '/teacher/password-reset-requests/$id/approve',
      data: {'password': password, 'password_confirmation': confirmation},
    ),
    (_) {},
  );

  Future<void> rejectPasswordResetRequest(String id, String note) => _request(
    () => _dio.post<Map<String, dynamic>>(
      '/teacher/password-reset-requests/$id/reject',
      data: {'review_note': note},
    ),
    (_) {},
  );

  Future<List<TeacherSpeakingTemplate>> speakingTemplates() => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/teacher/speaking/templates',
      queryParameters: const {'per_page': 100},
    ),
    (json) => (json?['data'] is List ? json!['data'] as List : const [])
        .whereType<Map<String, dynamic>>()
        .map(TeacherSpeakingTemplate.fromJson)
        .toList(),
  );

  Future<List<TeacherSpeakingExercise>> speakingExercises({
    String? classroomId,
    String? status,
  }) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/teacher/speaking/exercises',
      queryParameters: {
        'per_page': 100,
        if (classroomId != null && classroomId.isNotEmpty)
          'classroom_id': classroomId,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    ),
    (json) => (json?['data'] is List ? json!['data'] as List : const [])
        .whereType<Map<String, dynamic>>()
        .map(TeacherSpeakingExercise.fromJson)
        .toList(),
  );

  Future<TeacherSpeakingExercise> speakingExercise(String id) => _request(
    () => _dio.get<Map<String, dynamic>>('/teacher/speaking/exercises/$id'),
    (json) => TeacherSpeakingExercise.fromJson(_data(json, 'Detail latihan')),
  );

  Future<TeacherSpeakingExercise> saveSpeakingExercise({
    String? id,
    required Map<String, dynamic> data,
  }) => _request(
    () => id == null
        ? _dio.post<Map<String, dynamic>>(
            '/teacher/speaking/exercises',
            data: data,
          )
        : _dio.patch<Map<String, dynamic>>(
            '/teacher/speaking/exercises/$id',
            data: data,
          ),
    (json) => TeacherSpeakingExercise.fromJson(_data(json, 'Latihan')),
  );

  Future<void> archiveSpeakingExercise(String id) async {
    try {
      await _dio.patch<void>('/teacher/speaking/exercises/$id/archive');
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<void> deleteSpeakingExercise(String id) async {
    try {
      await _dio.delete<void>('/teacher/speaking/exercises/$id');
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<TeacherSpeakingAttemptPage> speakingAttempts({
    int page = 1,
    String? search,
    String? reviewStatus,
  }) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/teacher/speaking/attempts',
      queryParameters: {
        'page': page,
        'per_page': 15,
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (reviewStatus?.isNotEmpty == true) 'review_status': reviewStatus,
      },
    ),
    TeacherSpeakingAttemptPage.fromJson,
  );

  Future<TeacherSpeakingAttempt> speakingAttempt(String id) => _request(
    () => _dio.get<Map<String, dynamic>>('/teacher/speaking/attempts/$id'),
    (json) =>
        TeacherSpeakingAttempt.fromJson(_data(json, 'Detail hasil speaking')),
  );

  Future<void> deleteSpeakingAttempt(String id) async {
    try {
      await _dio.delete<void>('/teacher/speaking/attempts/$id');
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<TeacherSpeakingAttempt> saveSpeakingFeedback(
    String id, {
    required num teacherScore,
    String? teacherFeedback,
  }) => _request(
    () => _dio.patch<Map<String, dynamic>>(
      '/teacher/speaking/attempts/$id/feedback',
      data: {
        'teacher_score': teacherScore,
        'teacher_feedback': teacherFeedback,
      },
    ),
    (json) => TeacherSpeakingAttempt.fromJson(_data(json, 'Penilaian')),
  );

  Future<String> speakingTemporaryUrl(String mediaId) => _request(
    () => _dio.post<Map<String, dynamic>>(
      '/media/$mediaId/temporary-url',
      data: const {'expires_in_minutes': 15, 'disposition': 'inline'},
    ),
    (json) => _string(_data(json, 'Audio')['url']),
  );

  Future<TeacherDashboardSummary> dashboard() => _request(
    () => _dio.get<Map<String, dynamic>>('/teacher/dashboard/summary'),
    (json) => TeacherDashboardSummary.fromJson(_data(json, 'Dashboard guru')),
  );

  Future<List<TeacherModule>> modules(String classId) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/classes/$classId/modules',
      queryParameters: const {
        'per_page': 100,
        'sort_by': 'sort_order',
        'sort_direction': 'asc',
      },
    ),
    (json) => (json?['data'] is List ? json!['data'] as List : const [])
        .whereType<Map<String, dynamic>>()
        .map(TeacherModule.fromJson)
        .toList(),
  );

  Future<TeacherModule> moduleDetail(String id) => _request(
    () => _dio.get<Map<String, dynamic>>('/class-modules/$id'),
    (json) => TeacherModule.fromJson(_data(json, 'Detail modul')),
  );

  Future<TeacherModule> createModule(
    String classId,
    Map<String, dynamic> data,
  ) => _request(
    () => _dio.post<Map<String, dynamic>>(
      '/classes/$classId/modules',
      data: data,
    ),
    (json) => TeacherModule.fromJson(_data(json, 'Modul')),
  );

  Future<TeacherModule> updateModule(String id, Map<String, dynamic> data) =>
      _request(
        () => _dio.put<Map<String, dynamic>>('/class-modules/$id', data: data),
        (json) => TeacherModule.fromJson(_data(json, 'Modul')),
      );

  Future<TeacherModule> publishModule(String id) =>
      _action('/class-modules/$id/publish', 'Modul');

  Future<TeacherModule> archiveModule(String id) =>
      _action('/class-modules/$id/archive', 'Modul');

  Future<void> deleteModule(String id) async {
    try {
      await _dio.delete<void>('/class-modules/$id');
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<void> reorderModules(String classId, List<String> moduleIds) async {
    try {
      await _dio.patch<void>(
        '/classes/$classId/modules/reorder',
        data: {'module_ids': moduleIds},
      );
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<TeacherLesson> lessonDetail(String id) => _request(
    () => _dio.get<Map<String, dynamic>>('/class-lessons/$id'),
    (json) => TeacherLesson.fromJson(_data(json, 'Detail materi')),
  );

  Future<TeacherLessonContent> lessonContent(String id) => _request(
    () => _dio.get<Map<String, dynamic>>('/class-lessons/$id/content-url'),
    (json) => TeacherLessonContent.fromJson(_data(json, 'Konten materi')),
  );

  Future<TeacherLesson> createLesson(
    String moduleId,
    Map<String, dynamic> data,
  ) => _request(
    () => _dio.post<Map<String, dynamic>>(
      '/class-modules/$moduleId/lessons',
      data: data,
    ),
    (json) => TeacherLesson.fromJson(_data(json, 'Materi')),
  );

  Future<TeacherLesson> updateLesson(String id, Map<String, dynamic> data) =>
      _request(
        () => _dio.put<Map<String, dynamic>>('/class-lessons/$id', data: data),
        (json) => TeacherLesson.fromJson(_data(json, 'Materi')),
      );

  Future<TeacherLesson> publishLesson(String id) =>
      _actionLesson('/class-lessons/$id/publish');

  Future<void> reorderLessons(String moduleId, List<String> lessonIds) async {
    try {
      await _dio.patch<void>(
        '/class-modules/$moduleId/lessons/reorder',
        data: {'lesson_ids': lessonIds},
      );
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<CulturePage> culture(String classId) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/classes/$classId/culture',
      queryParameters: const {
        'per_page': 100,
        'sort_by': 'display_order',
        'sort_direction': 'asc',
      },
    ),
    (json) => CulturePage.fromJson(json ?? const {}),
  );

  Future<CultureItem> cultureDetail(String id) => _request(
    () => _dio.get<Map<String, dynamic>>('/class-culture-items/$id'),
    (json) => CultureItem.fromJson(_data(json, 'Konten budaya')),
  );

  Future<CultureItem> saveCulture({
    required String classId,
    String? id,
    required Map<String, dynamic> data,
  }) => _request(
    () => id == null
        ? _dio.post<Map<String, dynamic>>(
            '/classes/$classId/culture',
            data: data,
          )
        : _dio.put<Map<String, dynamic>>(
            '/class-culture-items/$id',
            data: data,
          ),
    (json) => CultureItem.fromJson(_data(json, 'Konten budaya')),
  );

  Future<void> publishCulture(String id) =>
      _cultureAction('/class-culture-items/$id/publish');
  Future<void> archiveCulture(String id) =>
      _cultureAction('/class-culture-items/$id/archive');
  Future<void> deleteCulture(String id) =>
      _cultureAction('/class-culture-items/$id', delete: true);

  Future<String> uploadCulture(String path, String name) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/media',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(path, filename: name),
          'purpose': 'culture_media',
          'visibility': 'private',
        }),
      );
      return _string(_data(response.data, 'Media')['id']);
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<void> _cultureAction(String path, {bool delete = false}) async {
    try {
      if (delete) {
        await _dio.delete<void>(path);
      } else {
        await _dio.post<void>(path);
      }
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<TeacherMediaUpload> uploadMedia(
    String path,
    String name, {
    required String purpose,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/media',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(path, filename: name),
          'purpose': purpose,
          'visibility': purpose == 'speaking_reference_audio'
              ? 'public'
              : 'private',
        }),
      );
      final data = _data(response.data, 'Media');
      return TeacherMediaUpload(
        id: _string(data['id']),
        name: _string(data['original_name'], fallback: name),
      );
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<TeacherClassPage> classes({int page = 1, String? search}) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/classes',
      queryParameters: {
        'page': page,
        'per_page': 10,
        'sort_by': 'name',
        'sort_direction': 'asc',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    ),
    TeacherClassPage.fromJson,
  );

  Future<TeacherClass> classDetail(String id) => _request(
    () => _dio.get<Map<String, dynamic>>('/classes/$id'),
    (json) => TeacherClass.fromJson(_data(json, 'Data kelas')),
  );

  Future<TeacherClassStudentPage> classStudents(
    String id, {
    int page = 1,
    String? search,
  }) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/classes/$id/students',
      queryParameters: {
        'page': page,
        'per_page': 20,
        'sort_by': 'full_name',
        'sort_direction': 'asc',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    ),
    TeacherClassStudentPage.fromJson,
  );

  Future<TeacherStudentProgressPage> studentProgress({
    int page = 1,
    String? search,
    String? studentId,
    String? classId,
  }) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/teacher/reports/progress/students',
      queryParameters: {
        'page': page,
        'per_page': studentId == null ? 20 : 1,
        'sort_by': 'full_name',
        'sort_direction': 'asc',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'student_id': ?studentId,
        'class_id': ?classId,
      },
    ),
    TeacherStudentProgressPage.fromJson,
  );

  Future<List<int>> studentProgressCsv({
    String? classId,
    String? search,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        '/teacher/reports/progress/students/export',
        queryParameters: {
          if (classId != null && classId.isNotEmpty) 'class_id': classId,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<TeacherStudentProgress> studentDetail(String id) async {
    final page = await studentProgress(studentId: id);
    if (page.items.isEmpty) {
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Detail siswa tidak tersedia atau bukan berada di kelas Anda.',
      );
    }
    return page.items.first;
  }

  Future<TeacherModule> _action(String path, String label) => _request(
    () => _dio.post<Map<String, dynamic>>(path),
    (json) => TeacherModule.fromJson(_data(json, label)),
  );

  Future<TeacherLesson> _actionLesson(String path) => _request(
    () => _dio.post<Map<String, dynamic>>(path),
    (json) => TeacherLesson.fromJson(_data(json, 'Materi')),
  );

  TeacherRequestItem _requestItem(Map<String, dynamic>? json) {
    final data = json?['data'];
    if (data is Map<String, dynamic>) return TeacherRequestItem.fromJson(data);
    throw const AppError(
      type: AppErrorType.unknown,
      message: 'Data permintaan tidak valid.',
    );
  }

  Future<T> _request<T>(
    Future<Response<Map<String, dynamic>>> Function() request,
    T Function(Map<String, dynamic>?) parse,
  ) async {
    try {
      return parse((await request()).data);
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }
}

Map<String, dynamic> _data(Map<String, dynamic>? json, String label) {
  final data = json?['data'];
  if (data is Map<String, dynamic>) return data;
  throw AppError(type: AppErrorType.unknown, message: '$label tidak valid.');
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

String _string(Object? value, {String fallback = ''}) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;

String? _nullableString(Object? value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}

double _number(Object? value) => value is num
    ? value.toDouble()
    : value is String
    ? double.tryParse(value) ?? 0
    : 0;

double? _nullableNumber(Object? value) => value == null
    ? null
    : value is num
    ? value.toDouble()
    : double.tryParse('$value');

int _int(Object? value, {int fallback = 0}) => value is int
    ? value
    : value is num
    ? value.toInt()
    : value is String
    ? int.tryParse(value) ?? fallback
    : fallback;

bool _bool(Object? value) => value is bool
    ? value
    : value is num
    ? value != 0
    : value is String && (value == '1' || value.toLowerCase() == 'true');
