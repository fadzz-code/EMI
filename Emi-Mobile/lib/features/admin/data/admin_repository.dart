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
  const AdminListQuery({this.search, this.role, this.status, this.page = 1});

  final String? search;
  final String? role;
  final String? status;
  final int page;

  Map<String, dynamic> toQuery() => {
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
    if (role != null && role!.isNotEmpty) 'role': role,
    if (status != null && status!.isNotEmpty) 'status': status,
    'page': page,
    'per_page': 15,
  };

  AdminListQuery copyWith({
    String? search,
    String? role,
    String? status,
    int? page,
    bool clearRole = false,
    bool clearStatus = false,
  }) => AdminListQuery(
    search: search ?? this.search,
    role: clearRole ? null : role ?? this.role,
    status: clearStatus ? null : status ?? this.status,
    page: page ?? this.page,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminListQuery &&
          other.search == search &&
          other.role == role &&
          other.status == status &&
          other.page == page;

  @override
  int get hashCode => Object.hash(search, role, status, page);
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
