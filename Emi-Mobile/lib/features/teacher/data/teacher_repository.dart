import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

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
  const TeacherClassStudentPage({required this.items});

  final List<TeacherClassStudent> items;

  factory TeacherClassStudentPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'];
    return TeacherClassStudentPage(
      items: rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(TeacherClassStudent.fromJson)
                .toList()
          : const [],
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
    required this.className,
    required this.percent,
    required this.completedModules,
    required this.startedModules,
    required this.publishedModules,
    required this.completedQuizzes,
    required this.attemptedQuizzes,
    required this.publishedQuizzes,
  });

  final String studentId;
  final String name;
  final String className;
  final double percent;
  final int completedModules;
  final int startedModules;
  final int publishedModules;
  final int completedQuizzes;
  final int attemptedQuizzes;
  final int publishedQuizzes;

  factory TeacherStudentProgress.fromJson(Map<String, dynamic> json) =>
      TeacherStudentProgress(
        studentId: _string(json['student_id']),
        name: _string(json['full_name'], fallback: 'Nama belum tersedia'),
        className: _string(
          _map(json['class'])['name'],
          fallback: 'Kelas belum tersedia',
        ),
        percent: _number(json['overall_learning_progress_percent']),
        completedModules: _int(json['completed_modules']),
        startedModules: _int(json['started_modules']),
        publishedModules: _int(json['published_modules']),
        completedQuizzes: _int(json['quizzes_completed']),
        attemptedQuizzes: _int(json['quizzes_attempted']),
        publishedQuizzes: _int(json['published_quizzes']),
      );
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

class TeacherRepository {
  const TeacherRepository(this._dio, this._mapper);

  final Dio _dio;
  final DioErrorMapper _mapper;

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

  Future<TeacherModule> updateModule(String id, Map<String, dynamic> data) =>
      _request(
        () => _dio.put<Map<String, dynamic>>('/class-modules/$id', data: data),
        (json) => TeacherModule.fromJson(_data(json, 'Modul')),
      );

  Future<TeacherModule> publishModule(String id) =>
      _action('/class-modules/$id/publish', 'Modul');

  Future<TeacherLesson> lessonDetail(String id) => _request(
    () => _dio.get<Map<String, dynamic>>('/class-lessons/$id'),
    (json) => TeacherLesson.fromJson(_data(json, 'Detail materi')),
  );

  Future<TeacherLesson> updateLesson(String id, Map<String, dynamic> data) =>
      _request(
        () => _dio.put<Map<String, dynamic>>('/class-lessons/$id', data: data),
        (json) => TeacherLesson.fromJson(_data(json, 'Materi')),
      );

  Future<TeacherLesson> publishLesson(String id) =>
      _actionLesson('/class-lessons/$id/publish');

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
          'visibility': 'private',
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
        'per_page': 100,
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
