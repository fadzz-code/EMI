import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

class AdminModuleSummary {
  const AdminModuleSummary({
    required this.total,
    required this.draft,
    required this.published,
    required this.archived,
  });

  final int total;
  final int draft;
  final int published;
  final int archived;
}

class AdminModuleQuery {
  const AdminModuleQuery({this.search, this.status, this.page = 1});

  final String? search;
  final String? status;
  final int page;

  Map<String, dynamic> toQuery() => {
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
    if (status != null && status!.isNotEmpty) 'status': status,
    'page': page,
    'per_page': 15,
    'sort_by': 'updated_at',
    'sort_direction': 'desc',
  };

  AdminModuleQuery copyWith({
    String? search,
    String? status,
    int? page,
    bool clearStatus = false,
  }) => AdminModuleQuery(
    search: search ?? this.search,
    status: clearStatus ? null : status ?? this.status,
    page: page ?? this.page,
  );
}

class AdminModulePage {
  const AdminModulePage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminModuleItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory AdminModulePage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'] is List
        ? (json?['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdminModuleItem.fromJson)
              .toList()
        : <AdminModuleItem>[];
    final meta = _map(json?['meta']);
    return AdminModulePage(
      items: rows,
      currentPage: _int(meta['current_page']) ?? 1,
      lastPage: _int(meta['last_page']) ?? 1,
      total: _int(meta['total']) ?? rows.length,
    );
  }
}

class AdminModuleItem {
  const AdminModuleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.lessonsCount,
    required this.lessons,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final int lessonsCount;
  final List<AdminLessonItem> lessons;
  final String? createdAt;
  final String? updatedAt;

  factory AdminModuleItem.fromJson(Map<String, dynamic> json) {
    final lessons = json['lessons'] is List
        ? (json['lessons'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdminLessonItem.fromJson)
              .toList()
        : <AdminLessonItem>[];
    return AdminModuleItem(
      id: _string(json['id']),
      title: _string(json['title'], fallback: 'Tanpa judul'),
      description: _string(json['description']),
      status: _string(json['status'], fallback: 'draft'),
      lessonsCount: _int(json['lessons_count']) ?? lessons.length,
      lessons: lessons,
      createdAt: _nullableString(json['created_at']),
      updatedAt: _nullableString(json['updated_at']),
    );
  }
}

class AdminLessonItem {
  const AdminLessonItem({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    required this.contentBody,
    required this.mediaId,
    required this.externalUrl,
    required this.sortOrder,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String contentType;
  final String contentBody;
  final String? mediaId;
  final String? externalUrl;
  final int sortOrder;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  factory AdminLessonItem.fromJson(Map<String, dynamic> json) =>
      AdminLessonItem(
        id: _string(json['id']),
        title: _string(json['title'], fallback: 'Tanpa judul'),
        description: _string(json['description']),
        contentType: _string(json['content_type'], fallback: 'text'),
        contentBody: _string(json['content_body']),
        mediaId:
            _nullableString(_map(json['media'])['id']) ??
            _nullableString(json['media_id']),
        externalUrl: _nullableString(json['external_url']),
        sortOrder: _int(json['sort_order']) ?? 0,
        status: _string(json['status'], fallback: 'draft'),
        createdAt: _nullableString(json['created_at']),
        updatedAt: _nullableString(json['updated_at']),
      );
}

class AdminModuleSaveRequest {
  const AdminModuleSaveRequest({
    required this.title,
    required this.description,
    required this.status,
  });

  final String title;
  final String description;
  final String status;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'status': status == 'archived' ? 'draft' : status,
  };
}

class AdminModuleMediaUpload {
  const AdminModuleMediaUpload({
    required this.id,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    this.url,
  });

  final String id;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final String? url;

  factory AdminModuleMediaUpload.fromJson(Map<String, dynamic> json) =>
      AdminModuleMediaUpload(
        id: _string(json['id']),
        originalName: _string(json['original_name'], fallback: 'Media'),
        mimeType: _string(json['mime_type']),
        sizeBytes: _int(json['size_bytes']) ?? 0,
        url: _nullableString(json['url']),
      );
}

class AdminModuleClassTarget {
  const AdminModuleClassTarget({required this.id, required this.name});

  final String id;
  final String name;

  factory AdminModuleClassTarget.fromJson(Map<String, dynamic> json) =>
      AdminModuleClassTarget(
        id: _string(json['id']),
        name: _string(json['name'], fallback: 'Tanpa nama'),
      );
}

class AdminModuleApplySummary {
  const AdminModuleApplySummary({
    required this.applied,
    required this.synced,
    required this.skipped,
    required this.failed,
  });

  final int applied;
  final int synced;
  final int skipped;
  final int failed;

  factory AdminModuleApplySummary.fromJson(Map<String, dynamic>? json) =>
      AdminModuleApplySummary(
        applied: (json?['applied'] as List?)?.length ?? 0,
        synced: (json?['synced'] as List?)?.length ?? 0,
        skipped: (json?['skipped'] as List?)?.length ?? 0,
        failed: (json?['failed'] as List?)?.length ?? 0,
      );
}

class AdminModuleTemporaryUrl {
  const AdminModuleTemporaryUrl({required this.url, required this.expiresAt});

  final String url;
  final String expiresAt;

  factory AdminModuleTemporaryUrl.fromJson(Map<String, dynamic> json) =>
      AdminModuleTemporaryUrl(
        url: _string(json['url']),
        expiresAt: _string(json['expires_at']),
      );
}

class AdminLessonSaveRequest {
  const AdminLessonSaveRequest({
    required this.title,
    required this.description,
    required this.contentType,
    required this.contentBody,
    required this.mediaId,
    required this.externalUrl,
    required this.sortOrder,
    required this.status,
  });

  final String title;
  final String description;
  final String contentType;
  final String contentBody;
  final String mediaId;
  final String externalUrl;
  final int? sortOrder;
  final String status;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'content_type': contentType,
    'content_body': contentType == 'text' ? contentBody : null,
    'media_id': ['image', 'audio', 'pdf'].contains(contentType)
        ? mediaId
        : null,
    'external_url': ['video', 'link'].contains(contentType)
        ? externalUrl
        : null,
    if (sortOrder != null) 'sort_order': sortOrder,
    'status': status == 'archived' ? 'draft' : status,
  };
}

class AdminModuleRepository {
  const AdminModuleRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<AdminModulePage> list(AdminModuleQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/module-templates',
        queryParameters: query.toQuery(),
      );
      return AdminModulePage.fromJson(response.data);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminModuleSummary> summary() async {
    var current = await list(const AdminModuleQuery(page: 1));
    var draft = 0;
    var published = 0;
    var archived = 0;
    while (true) {
      for (final item in current.items) {
        if (item.status == 'draft') draft++;
        if (item.status == 'published') published++;
        if (item.status == 'archived') archived++;
      }
      if (!current.hasMore) break;
      current = await list(AdminModuleQuery(page: current.currentPage + 1));
    }
    return AdminModuleSummary(
      total: current.total,
      draft: draft,
      published: published,
      archived: archived,
    );
  }

  Future<AdminModuleItem> detail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/module-templates/$id',
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminModuleItem.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data modul tidak valid.',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<AdminLessonItem>> lessons(String moduleId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/module-templates/$moduleId/lessons',
        queryParameters: const {'per_page': 100},
      );
      final rows = response.data?['data'] is List
          ? response.data!['data'] as List
          : const [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(AdminLessonItem.fromJson)
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminModuleItem> save({
    String? id,
    required AdminModuleSaveRequest request,
  }) async {
    try {
      final response = id == null
          ? await _dio.post<Map<String, dynamic>>(
              '/admin/module-templates',
              data: request.toJson(),
            )
          : await _dio.put<Map<String, dynamic>>(
              '/admin/module-templates/$id',
              data: request.toJson(),
            );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminModuleItem.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data modul tidak valid.',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminModuleItem> publish(
    String id, {
    bool applyToAllActiveClasses = false,
    bool publishClassModules = false,
  }) => _moduleAction(
    id,
    'publish',
    body: {
      'apply_to_all_active_classes': applyToAllActiveClasses,
      'publish_class_modules': publishClassModules,
    },
  );

  Future<AdminModuleItem> archive(String id) => _moduleAction(id, 'archive');

  Future<List<AdminModuleClassTarget>> activeClasses() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/classes',
        queryParameters: const {'status': 'active', 'per_page': 100},
      );
      return (response.data?['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminModuleClassTarget.fromJson)
          .toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminModuleApplySummary> apply(
    String id,
    List<String> classIds, {
    bool publishClassModules = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/module-templates/$id/apply',
        data: {
          'class_ids': classIds,
          'publish_class_modules': publishClassModules,
        },
      );
      return AdminModuleApplySummary.fromJson(_map(response.data?['data']));
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/admin/module-templates/$id');
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminModuleMediaUpload> uploadMedia({
    required String path,
    required String name,
    required String purpose,
    required String visibility,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: name),
        'purpose': purpose,
        'visibility': visibility,
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/media',
        data: form,
        onSendProgress: onProgress,
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return AdminModuleMediaUpload.fromJson(data);
      }
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data media tidak valid.',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminModuleTemporaryUrl> temporaryUrl(String mediaId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/media/$mediaId/temporary-url',
        data: const {'expires_in_minutes': 15, 'disposition': 'inline'},
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return AdminModuleTemporaryUrl.fromJson(data);
      }
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'URL media tidak valid.',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminLessonItem> saveLesson({
    required String moduleId,
    String? id,
    required AdminLessonSaveRequest request,
  }) async {
    try {
      final response = id == null
          ? await _dio.post<Map<String, dynamic>>(
              '/admin/module-templates/$moduleId/lessons',
              data: request.toJson(),
            )
          : await _dio.put<Map<String, dynamic>>(
              '/admin/lesson-templates/$id',
              data: request.toJson(),
            );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminLessonItem.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data materi tidak valid.',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> deleteLesson(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/admin/lesson-templates/$id');
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminLessonItem> publishLesson(String id) =>
      _lessonAction(id, 'publish');

  Future<AdminLessonItem> archiveLesson(String id) =>
      _lessonAction(id, 'archive');

  Future<void> reorderLessons(String moduleId, List<String> lessonIds) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/admin/module-templates/$moduleId/lessons/reorder',
        data: {'lesson_ids': lessonIds},
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminModuleItem> _moduleAction(
    String id,
    String action, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/module-templates/$id/$action',
        data: body,
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminModuleItem.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data modul tidak valid.',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminLessonItem> _lessonAction(String id, String action) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/lesson-templates/$id/$action',
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return AdminLessonItem.fromJson(data);
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data materi tidak valid.',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Object _mapError(Object error) =>
      error is AppError ? error : _errorMapper.map(error);
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

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
