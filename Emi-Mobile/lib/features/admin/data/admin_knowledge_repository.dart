import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

class AdminKnowledgeSummary {
  const AdminKnowledgeSummary({
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

class AdminKnowledgeQuery {
  const AdminKnowledgeQuery({
    this.search,
    this.category,
    this.sourceType,
    this.status,
    this.page = 1,
  });

  final String? search;
  final String? category;
  final String? sourceType;
  final String? status;
  final int page;

  Map<String, dynamic> toQuery() => {
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
    if (category != null && category!.trim().isNotEmpty) 'category': category,
    if (status != null && status!.isNotEmpty) 'status': status,
    if (sourceType != null && sourceType!.isNotEmpty) 'source_type': sourceType,
    'page': page,
    'per_page': 15,
    'sort_by': 'updated_at',
    'sort_direction': 'desc',
  };

  AdminKnowledgeQuery copyWith({
    String? search,
    String? category,
    String? sourceType,
    String? status,
    int? page,
    bool clearCategory = false,
    bool clearSourceType = false,
    bool clearStatus = false,
  }) => AdminKnowledgeQuery(
    search: search ?? this.search,
    category: clearCategory ? null : category ?? this.category,
    sourceType: clearSourceType ? null : sourceType ?? this.sourceType,
    status: clearStatus ? null : status ?? this.status,
    page: page ?? this.page,
  );
}

class AdminKnowledgePage {
  const AdminKnowledgePage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminKnowledgeItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory AdminKnowledgePage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'] is List
        ? (json?['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdminKnowledgeItem.fromJson)
              .toList()
        : <AdminKnowledgeItem>[];
    final meta = _map(json?['meta']);
    return AdminKnowledgePage(
      items: rows,
      currentPage: _int(meta['current_page']) ?? 1,
      lastPage: _int(meta['last_page']) ?? 1,
      total: _int(meta['total']) ?? rows.length,
    );
  }
}

class AdminKnowledgeItem {
  const AdminKnowledgeItem({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.sourceType,
    required this.status,
    this.sourceUrl,
    this.processingStatus,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String category;
  final String content;
  final String sourceType;
  final String status;
  final String? sourceUrl;
  final String? processingStatus;
  final String? createdAt;
  final String? updatedAt;

  factory AdminKnowledgeItem.fromJson(Map<String, dynamic> json) =>
      AdminKnowledgeItem(
        id: _string(json['id']),
        title: _string(json['title'], fallback: 'Tanpa judul'),
        category: _string(json['category'], fallback: 'Umum'),
        content: _string(json['content']),
        sourceType: _string(json['source_type'], fallback: 'manual'),
        status: _string(json['status'], fallback: 'draft'),
        sourceUrl: _nullableString(json['source_url']),
        processingStatus: _nullableString(json['processing_status']),
        createdAt: _nullableString(json['created_at']),
        updatedAt: _nullableString(json['updated_at']),
      );
}

class AdminKnowledgeSaveRequest {
  const AdminKnowledgeSaveRequest({
    required this.title,
    required this.category,
    required this.content,
    required this.sourceType,
    required this.status,
    this.sourceUrl,
    this.pdfPath,
    this.pdfName,
  });

  final String title;
  final String category;
  final String content;
  final String sourceType;
  final String status;
  final String? sourceUrl;
  final String? pdfPath;
  final String? pdfName;
}

class AdminKnowledgeSourcePreview {
  const AdminKnowledgeSourcePreview({
    required this.title,
    required this.content,
    required this.sourceType,
    required this.sourceUrl,
    required this.characterCount,
  });

  final String title;
  final String content;
  final String sourceType;
  final String sourceUrl;
  final int characterCount;

  factory AdminKnowledgeSourcePreview.fromJson(Map<String, dynamic> json) =>
      AdminKnowledgeSourcePreview(
        title: _string(json['title']),
        content: _string(json['content']),
        sourceType: _string(json['source_type']),
        sourceUrl: _string(json['source_url']),
        characterCount: _int(json['character_count']) ?? 0,
      );
}

class AdminKnowledgeRepository {
  const AdminKnowledgeRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<AdminKnowledgePage> list(AdminKnowledgeQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/ai/knowledge',
        queryParameters: query.toQuery(),
      );
      return AdminKnowledgePage.fromJson(response.data);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminKnowledgeSummary> summary() async {
    final page = await list(const AdminKnowledgeQuery(page: 1));
    var draft = 0;
    var published = 0;
    var archived = 0;
    var current = page;
    while (true) {
      for (final item in current.items) {
        if (item.status == 'draft') draft++;
        if (item.status == 'published') published++;
        if (item.status == 'archived') archived++;
      }
      if (!current.hasMore) break;
      current = await list(AdminKnowledgeQuery(page: current.currentPage + 1));
    }
    return AdminKnowledgeSummary(
      total: current.total,
      draft: draft,
      published: published,
      archived: archived,
    );
  }

  Future<AdminKnowledgeItem> detail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/ai/knowledge/$id',
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return AdminKnowledgeItem.fromJson(data);
      }
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data pengetahuan tidak valid.',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminKnowledgeSourcePreview> previewSource({
    required String sourceType,
    required String sourceUrl,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/ai/knowledge/extract-source',
        data: {'source_type': sourceType, 'source_url': sourceUrl},
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return AdminKnowledgeSourcePreview.fromJson(data);
      }
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data PDF tidak valid.',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminKnowledgeItem> save({
    String? id,
    required AdminKnowledgeSaveRequest request,
  }) async {
    try {
      if (request.pdfPath != null && id == null) {
        final form = FormData.fromMap({
          'title': request.title,
          'category': request.category,
          'status': request.status == 'archived' ? 'draft' : request.status,
          'file': await MultipartFile.fromFile(
            request.pdfPath!,
            filename: request.pdfName,
          ),
        });
        final response = await _dio.post<Map<String, dynamic>>(
          '/admin/ai/knowledge/import-pdf',
          data: form,
        );
        final data = _map(response.data?['data']);
        return detail(_string(data['item_id']));
      }
      final data = {
        'title': request.title,
        'category': request.category,
        'content': request.content,
        'source_type': request.sourceType,
        'source_url': request.sourceUrl,
        'status': request.status,
      };
      final response = id == null
          ? await _dio.post<Map<String, dynamic>>(
              '/admin/ai/knowledge',
              data: data,
            )
          : await _dio.put<Map<String, dynamic>>(
              '/admin/ai/knowledge/$id',
              data: data,
            );
      final body = response.data?['data'];
      if (body is Map<String, dynamic>) {
        return AdminKnowledgeItem.fromJson(body);
      }
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data pengetahuan tidak valid.',
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminKnowledgeItem> publish(String id) => _action(id, 'publish');

  Future<AdminKnowledgeItem> archive(String id) => _action(id, 'archive');

  Future<void> delete(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/admin/ai/knowledge/$id');
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<AdminKnowledgeItem> retry(String id) =>
      _action(id, 'retry-processing');

  Future<AdminKnowledgeItem> _action(String id, String action) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/ai/knowledge/$id/$action',
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return AdminKnowledgeItem.fromJson(data);
      }
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data pengetahuan tidak valid.',
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
