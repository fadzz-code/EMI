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
      mediaId: _nullable(json['media_id']),
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
          'visibility': 'public',
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
