import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

class AdminSummary {
  const AdminSummary({required this.items});

  final List<AdminMetric> items;

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    final overview = _map(json['overview']);
    return AdminSummary(
      items: [
        AdminMetric(
          label: 'Pendaftaran yang Perlu Diperiksa',
          value: _number(overview['pending_registration_requests']),
          helper: 'Periksa data Guru dan Siswa.',
          iconName: 'approval',
          highlight: true,
        ),
        AdminMetric(
          label: 'Sekolah Aktif',
          value: _number(overview['active_schools']),
          helper: 'Sekolah yang memakai EMI.',
          iconName: 'school',
        ),
        AdminMetric(
          label: 'Kelas Aktif',
          value: _number(overview['active_classes']),
          helper: 'Kelas yang sudah terdata.',
          iconName: 'class',
        ),
        AdminMetric(
          label: 'Jumlah Pengguna',
          value: _number(
            _sum(overview['active_teachers'], overview['active_students']),
          ),
          helper: 'Guru dan Siswa.',
          iconName: 'users',
        ),
      ],
    );
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

String _number(Object? value) => value is num ? value.toString() : '0';

int _sum(Object? first, Object? second) {
  final a = first is num ? first.toInt() : 0;
  final b = second is num ? second.toInt() : 0;
  return a + b;
}

class AdminMetric {
  const AdminMetric({
    required this.label,
    required this.value,
    required this.iconName,
    this.helper,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String iconName;
  final String? helper;
  final bool highlight;
}

class AdminListQuery {
  const AdminListQuery({
    this.search,
    this.role,
    this.status,
    this.schoolId,
    this.page = 1,
  });

  final String? search;
  final String? role;
  final String? status;
  final String? schoolId;
  final int page;

  Map<String, dynamic> toQuery() => {
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
    if (role != null && role!.isNotEmpty) 'role': role,
    if (status != null && status!.isNotEmpty) 'status': status,
    if (schoolId != null && schoolId!.isNotEmpty) 'school_id': schoolId,
    'page': page,
    'per_page': 15,
  };

  AdminListQuery copyWith({
    String? search,
    String? role,
    String? status,
    String? schoolId,
    int? page,
    bool clearRole = false,
    bool clearStatus = false,
    bool clearSchool = false,
  }) => AdminListQuery(
    search: search ?? this.search,
    role: clearRole ? null : role ?? this.role,
    status: clearStatus ? null : status ?? this.status,
    schoolId: clearSchool ? null : schoolId ?? this.schoolId,
    page: page ?? this.page,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminListQuery &&
          other.search == search &&
          other.role == role &&
          other.status == status &&
          other.schoolId == schoolId &&
          other.page == page;

  @override
  int get hashCode => Object.hash(search, role, status, schoolId, page);
}

class AdminListPage {
  const AdminListPage({required this.items, this.hasMore = false});

  final List<AdminRecord> items;
  final bool hasMore;

  factory AdminListPage.fromJson(Map<String, dynamic>? json) {
    final data = json?['data'];
    final rows = data is List
        ? data
              .whereType<Map<String, dynamic>>()
              .map(AdminRecord.fromJson)
              .toList()
        : <AdminRecord>[];
    final meta = json?['meta'];
    final current = meta is Map<String, dynamic>
        ? _int(meta['current_page'])
        : null;
    final last = meta is Map<String, dynamic> ? _int(meta['last_page']) : null;
    return AdminListPage(
      items: rows,
      hasMore: current != null && last != null && current < last,
    );
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class AdminRecord {
  const AdminRecord({
    required this.id,
    required this.title,
    this.subtitle,
    this.status,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? status;

  factory AdminRecord.fromJson(Map<String, dynamic> json) {
    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.trim().isNotEmpty) return value;
        if (value is num) return '$value';
      }
      return null;
    }

    return AdminRecord(
      id: pick(['id', 'uuid']) ?? '',
      title:
          pick(['title', 'name', 'full_name', 'indonesia', 'question_text']) ??
          'Tanpa judul',
      subtitle: pick([
        'email',
        'description',
        'school_name',
        'role',
        'mekongga',
      ]),
      status: pick(['status', 'role']),
    );
  }
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
    this.avatarUrl,
    this.schoolName,
    this.classId,
    this.className,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? phone;
  final String? avatarUrl;
  final String? schoolName;
  final String? classId;
  final String? className;
  final String? createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final school = _map(json['active_school']);
    final klass = _map(json['active_class']);
    final avatar = _map(json['avatar']);
    return AdminUser(
      id: _string(json['id']),
      name: _string(json['full_name'], fallback: 'Tanpa nama'),
      email: _string(json['email']),
      phone: _nullableString(json['phone']),
      avatarUrl: _nullableString(avatar['url']),
      role: _string(json['role']),
      status: _string(json['status']),
      schoolName: _nullableString(school['name']),
      classId: _nullableString(klass['id']),
      className: _nullableString(klass['name']),
      createdAt: _nullableString(json['created_at']),
    );
  }
}

class AdminSchool {
  const AdminSchool({
    required this.id,
    required this.name,
    required this.status,
    this.address,
    this.phone,
    this.classesCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String status;
  final String? address;
  final String? phone;
  final int classesCount;
  final String? createdAt;

  factory AdminSchool.fromJson(Map<String, dynamic> json) => AdminSchool(
    id: _string(json['id']),
    name: _string(json['name'], fallback: 'Tanpa nama'),
    status: _string(json['status']),
    address: _nullableString(json['address']),
    phone: _nullableString(json['phone']),
    classesCount: _int(json['classes_count']) ?? 0,
    createdAt: _nullableString(json['created_at']),
  );
}

class AdminClass {
  const AdminClass({
    required this.id,
    required this.name,
    required this.status,
    this.schoolId,
    this.schoolName,
    this.teacherName,
    this.teacherEmail,
    this.studentsCount = 0,
    this.gradeLevel,
    this.academicYear,
  });

  final String id;
  final String name;
  final String status;
  final String? schoolId;
  final String? schoolName;
  final String? teacherName;
  final String? teacherEmail;
  final int studentsCount;
  final String? gradeLevel;
  final String? academicYear;

  factory AdminClass.fromJson(Map<String, dynamic> json) {
    final school = _map(json['school']);
    final assignment = _map(json['active_teacher_assignment']);
    final teacher = _map(assignment['teacher']);
    return AdminClass(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Tanpa nama'),
      status: _string(json['status']),
      schoolId: _nullableString(json['school_id'] ?? school['id']),
      schoolName: _nullableString(school['name'] ?? json['school_name']),
      teacherName: _nullableString(
        teacher['full_name'] ?? json['teacher_name'],
      ),
      teacherEmail: _nullableString(teacher['email']),
      studentsCount: _int(json['active_students_count']) ?? 0,
      gradeLevel: _nullableString(json['grade_level']),
      academicYear: _nullableString(json['academic_year']),
    );
  }
}

class AdminClassContent {
  const AdminClassContent({
    required this.id,
    required this.title,
    required this.status,
  });

  final String id;
  final String title;
  final String status;

  factory AdminClassContent.fromJson(Map<String, dynamic> json) =>
      AdminClassContent(
        id: _string(json['id']),
        title: _string(json['title'], fallback: 'Tanpa judul'),
        status: _string(json['status'], fallback: 'draft'),
      );
}

class AdminClassStudent {
  const AdminClassStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });

  final String id;
  final String name;
  final String email;
  final String status;

  factory AdminClassStudent.fromJson(Map<String, dynamic> json) {
    final student = _map(json['student']);
    return AdminClassStudent(
      id: _string(student['id']),
      name: _string(student['full_name'], fallback: 'Tanpa nama'),
      email: _string(student['email']),
      status: _string(student['status']),
    );
  }
}

class AdminClassStudentPage {
  const AdminClassStudentPage({required this.items});

  final List<AdminClassStudent> items;

  factory AdminClassStudentPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'] is List
        ? (json?['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdminClassStudent.fromJson)
              .toList()
        : <AdminClassStudent>[];
    return AdminClassStudentPage(items: rows);
  }
}

class AdminClassPage {
  const AdminClassPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminClass> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory AdminClassPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'] is List
        ? (json?['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdminClass.fromJson)
              .toList()
        : <AdminClass>[];
    final meta = _map(json?['meta']);
    return AdminClassPage(
      items: rows,
      currentPage: _int(meta['current_page']) ?? 1,
      lastPage: _int(meta['last_page']) ?? 1,
      total: _int(meta['total']) ?? rows.length,
    );
  }
}

class AdminSchoolPage {
  const AdminSchoolPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminSchool> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory AdminSchoolPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'] is List
        ? (json?['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdminSchool.fromJson)
              .toList()
        : <AdminSchool>[];
    final meta = _map(json?['meta']);
    return AdminSchoolPage(
      items: rows,
      currentPage: _int(meta['current_page']) ?? 1,
      lastPage: _int(meta['last_page']) ?? 1,
      total: _int(meta['total']) ?? rows.length,
    );
  }
}

class AdminUserPage {
  const AdminUserPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminUser> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory AdminUserPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'] is List
        ? (json?['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdminUser.fromJson)
              .where((user) => user.role == 'teacher' || user.role == 'student')
              .toList()
        : <AdminUser>[];
    final meta = _map(json?['meta']);
    return AdminUserPage(
      items: rows,
      currentPage: _int(meta['current_page']) ?? 1,
      lastPage: _int(meta['last_page']) ?? 1,
      total: _int(meta['total']) ?? rows.length,
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is num) return '$value';
  return fallback;
}

String? _nullableString(Object? value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class AdminRepository {
  const AdminRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<AdminSummary> dashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/dashboard/summary',
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminSummary.fromJson(data);
      return const AdminSummary(items: []);
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminListPage> list(String endpoint, AdminListQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: query.toQuery(),
      );
      return AdminListPage.fromJson(response.data);
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminRecord> detail(String endpoint, String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$endpoint/$id');
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminRecord.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data admin tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminClassPage> classes(AdminListQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/classes',
        queryParameters: query.toQuery(),
      );
      return AdminClassPage.fromJson(response.data);
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminClass> classDetail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/classes/$id');
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminClass.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data kelas tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<List<AdminClassContent>> classModules(String classId) =>
      _classContent('/classes/$classId/modules');

  Future<List<AdminClassContent>> classQuizzes(String classId) =>
      _classContent('/class-quizzes', {'class_id': classId, 'per_page': 100});

  Future<void> publishClassContent(String type, String id) async {
    try {
      await _dio.post<void>('/class-$type/$id/publish');
    } catch (error) {
      throw _map(error);
    }
  }

  Future<List<AdminClassContent>> _classContent(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query ?? const {'per_page': 100},
      );
      final raw = response.data?['data'];
      final rows = raw is Map ? raw['data'] : raw;
      return (rows as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminClassContent.fromJson)
          .toList();
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminClassStudentPage> classStudents(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/classes/$id/students',
      );
      return AdminClassStudentPage.fromJson(response.data);
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminClass> saveClass({
    String? id,
    required String schoolId,
    required String name,
    String? gradeLevel,
    String? academicYear,
    required String status,
  }) async {
    try {
      final data = {
        if (id == null) 'school_id': schoolId,
        'name': name,
        'grade_level': gradeLevel,
        'academic_year': academicYear,
        'status': status,
      };
      final response = id == null
          ? await _dio.post<Map<String, dynamic>>('/classes', data: data)
          : await _dio.put<Map<String, dynamic>>('/classes/$id', data: data);
      final body = response.data?['data'];
      if (body is Map<String, dynamic>) return AdminClass.fromJson(body);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data kelas tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminClass> deactivateClass(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>('/classes/$id');
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminClass.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data kelas tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<void> permanentlyDeleteClass(String id) async {
    try {
      await _dio.delete<void>('/classes/$id/force');
    } catch (error) {
      throw _map(error);
    }
  }

  Future<void> assignTeacher(String classId, String teacherId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/classes/$classId/assign-teacher',
        data: {'teacher_id': teacherId},
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<void> assignStudent(String classId, String studentId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/classes/$classId/assign-student',
        data: {'student_id': studentId},
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminSchoolPage> schools(AdminListQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/schools',
        queryParameters: query.toQuery(),
      );
      return AdminSchoolPage.fromJson(response.data);
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminSchool> schoolDetail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/schools/$id');
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminSchool.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data sekolah tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminSchool> saveSchool({
    String? id,
    required String name,
    String? address,
    String? phone,
    required String status,
  }) async {
    try {
      final data = {
        'name': name,
        'address': address,
        'phone': phone,
        'status': status,
      };
      final response = id == null
          ? await _dio.post<Map<String, dynamic>>('/schools', data: data)
          : await _dio.put<Map<String, dynamic>>('/schools/$id', data: data);
      final body = response.data?['data'];
      if (body is Map<String, dynamic>) return AdminSchool.fromJson(body);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data sekolah tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminSchool> deactivateSchool(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>('/schools/$id');
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminSchool.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data sekolah tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<void> permanentlyDeleteSchool(String id) async {
    try {
      await _dio.delete<void>('/schools/$id/force');
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminUserPage> users(AdminListQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users',
        queryParameters: query.toQuery(),
      );
      return AdminUserPage.fromJson(response.data);
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminUser> userDetail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/$id');
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminUser.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data pengguna tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminUser> updateUser(
    String id, {
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/users/$id',
        data: {'full_name': name, 'email': email, 'phone': phone},
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminUser.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data pengguna tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<void> permanentlyDeleteUser(String id, String confirmation) async {
    try {
      await _dio.post<void>(
        '/users/$id/force-delete',
        data: {'confirmation': confirmation},
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminUser> updateUserStatus(
    String id, {
    required String status,
    String? reason,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/users/$id/status',
        data: {'status': status, 'reason': ?reason},
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminUser.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data pengguna tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Object _map(Object error) =>
      error is AppError ? error : _errorMapper.map(error);
}
