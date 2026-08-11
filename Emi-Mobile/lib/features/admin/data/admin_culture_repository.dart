import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

class AdminCultureQuery {
  const AdminCultureQuery({
    this.search,
    this.status,
    this.contentType,
    this.page = 1,
    this.perPage = 15,
  });

  final String? search;
  final String? status;
  final String? contentType;
  final int page;
  final int perPage;

  Map<String, dynamic> toQuery() => {
    if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
    if (status?.isNotEmpty == true) 'status': status,
    if (contentType?.isNotEmpty == true) 'content_type': contentType,
    'page': page,
    'per_page': perPage,
  };

  AdminCultureQuery copyWith({
    String? search,
    String? status,
    String? contentType,
    int? page,
    bool clearStatus = false,
    bool clearContentType = false,
  }) => AdminCultureQuery(
    search: search ?? this.search,
    status: clearStatus ? null : status ?? this.status,
    contentType: clearContentType ? null : contentType ?? this.contentType,
    page: page ?? this.page,
    perPage: perPage,
  );
}

class AdminCulturePage {
  const AdminCulturePage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminCultureItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  bool get hasMore => currentPage < lastPage;

  factory AdminCulturePage.fromJson(Map<String, dynamic>? json) {
    final raw = json?['data'];
    final rows = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(AdminCultureItem.fromJson)
              .toList()
        : <AdminCultureItem>[];
    final meta = _map(json?['meta']);
    return AdminCulturePage(
      items: rows,
      currentPage: _integer(meta['current_page']) ?? 1,
      lastPage: _integer(meta['last_page']) ?? 1,
      total: _integer(meta['total']) ?? rows.length,
    );
  }
}

class AdminCultureItem {
  const AdminCultureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    required this.displayOrder,
    required this.status,
    this.mediaId,
    this.mediaUrl,
    this.mediaName,
    this.mediaSize,
    this.externalUrl,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String contentType;
  final String? mediaId;
  final String? mediaUrl;
  final String? mediaName;
  final int? mediaSize;
  final String? externalUrl;
  final int displayOrder;
  final String status;
  final String? updatedAt;

  factory AdminCultureItem.fromJson(Map<String, dynamic> json) {
    final media = _map(json['media']);
    return AdminCultureItem(
      id: _text(json['id']),
      title: _text(json['title'], 'Tanpa judul'),
      description: _text(json['description']),
      contentType: _text(json['content_type'], 'article'),
      mediaId: _nullable(json['media_id']) ?? _nullable(media['id']),
      mediaUrl: _nullable(media['url']),
      mediaName: _nullable(media['original_name']),
      mediaSize: _integer(media['size_bytes']),
      externalUrl: _nullable(json['external_url']),
      displayOrder: _integer(json['display_order']) ?? 1,
      status: _text(json['status'], 'draft'),
      updatedAt: _nullable(json['updated_at']),
    );
  }
}

class AdminCultureSaveRequest {
  const AdminCultureSaveRequest({
    required this.title,
    required this.description,
    required this.contentType,
    required this.mediaId,
    required this.externalUrl,
    required this.displayOrder,
    required this.status,
  });

  final String title;
  final String description;
  final String contentType;
  final String? mediaId;
  final String? externalUrl;
  final int displayOrder;
  final String status;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description.isEmpty ? null : description,
    'content_type': contentType,
    'media_id': mediaId,
    'external_url': externalUrl,
    'display_order': displayOrder,
    'status': status,
  };
}

class AdminCultureApplyResult {
  const AdminCultureApplyResult({
    required this.applied,
    required this.skipped,
    required this.failed,
  });

  final int applied;
  final int skipped;
  final int failed;

  factory AdminCultureApplyResult.fromJson(Map<String, dynamic> json) =>
      AdminCultureApplyResult(
        applied: (json['applied'] as List? ?? const []).length,
        skipped: (json['skipped'] as List? ?? const []).length,
        failed: (json['failed'] as List? ?? const []).length,
      );
}

class AdminCultureTemplate {
  const AdminCultureTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.items,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final List<AdminCultureItem> items;

  factory AdminCultureTemplate.fromJson(Map<String, dynamic> json) =>
      AdminCultureTemplate(
        id: _text(json['id']),
        title: _text(json['title'], 'Tanpa judul'),
        description: _text(json['description']),
        status: _text(json['status'], 'draft'),
        items: (json['items'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AdminCultureItem.fromJson)
            .toList(),
      );
}

class AdminCultureRepository {
  const AdminCultureRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;
  static const _path = '/admin/culture/items';

  Future<AdminCulturePage> list(AdminCultureQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: query.toQuery(),
      );
      return AdminCulturePage.fromJson(response.data);
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<AdminCultureItem> detail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
      return AdminCultureItem.fromJson(_map(response.data?['data']));
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<AdminCultureItem> save({
    String? id,
    required AdminCultureSaveRequest request,
  }) async {
    try {
      final response = id == null
          ? await _dio.post<Map<String, dynamic>>(_path, data: request.toJson())
          : await _dio.put<Map<String, dynamic>>(
              '$_path/$id',
              data: request.toJson(),
            );
      return AdminCultureItem.fromJson(_map(response.data?['data']));
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<String> upload({required String path, required String name}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/media',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(path, filename: name),
          'purpose': 'culture_media',
          'visibility': 'private',
        }),
      );
      final id = _text(_map(response.data?['data'])['id']);
      if (id.isEmpty) throw StateError('missing media');
      return id;
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<void> publish(String id) => _action(id, 'publish');
  Future<void> archive(String id) => _action(id, 'archive');

  Future<List<AdminCultureTemplate>> templates() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/culture-templates',
        queryParameters: const {'per_page': 100},
      );
      return (response.data?['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminCultureTemplate.fromJson)
          .toList();
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<AdminCultureTemplate> template(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/culture-templates/$id',
      );
      return AdminCultureTemplate.fromJson(_map(response.data?['data']));
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<AdminCultureTemplate> saveTemplate({
    String? id,
    required String title,
    required String description,
  }) async {
    try {
      final data = {
        'title': title,
        'description': description,
        'status': 'draft',
      };
      final response = id == null
          ? await _dio.post<Map<String, dynamic>>(
              '/admin/culture-templates',
              data: data,
            )
          : await _dio.put<Map<String, dynamic>>(
              '/admin/culture-templates/$id',
              data: data,
            );
      return AdminCultureTemplate.fromJson(_map(response.data?['data']));
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<void> saveTemplateItem({
    required String templateId,
    String? id,
    required AdminCultureSaveRequest request,
  }) async {
    try {
      if (id == null) {
        await _dio.post<void>(
          '/admin/culture-templates/$templateId/items',
          data: request.toJson(),
        );
      } else {
        await _dio.put<void>(
          '/admin/culture-template-items/$id',
          data: request.toJson(),
        );
      }
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<void> publishTemplate(String id) async {
    try {
      await _dio.post<void>('/admin/culture-templates/$id/publish');
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<AdminCultureApplyResult> applyTemplate(
    String id,
    List<String> classIds,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/culture-templates/$id/apply',
        data: {'class_ids': classIds},
      );
      return AdminCultureApplyResult.fromJson(_map(response.data?['data']));
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<void> deleteTemplateItem(String id) async {
    try {
      await _dio.delete<void>('/admin/culture-template-items/$id');
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('$_path/$id');
    } catch (error) {
      throw _safe(error);
    }
  }

  Future<void> _action(String id, String action) async {
    try {
      await _dio.post<void>('$_path/$id/$action');
    } catch (error) {
      throw _safe(error);
    }
  }

  AppError _safe(Object error) {
    final mapped = _errorMapper.map(error);
    return AppError(
      type: mapped.type,
      message: switch (mapped.type) {
        AppErrorType.validation =>
          'Data belum valid. Periksa isian lalu coba lagi.',
        AppErrorType.notFound => 'Konten budaya tidak ditemukan.',
        AppErrorType.networkUnavailable ||
        AppErrorType.timeout => mapped.message,
        _ => 'Konten budaya belum bisa diproses. Silakan coba lagi.',
      },
      fieldErrors: mapped.fieldErrors,
    );
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};
String _text(Object? value, [String fallback = '']) =>
    value is String && value.trim().isNotEmpty ? value : fallback;
String? _nullable(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;
int? _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');
