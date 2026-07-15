import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

class AdminSpeakingQuery {
  const AdminSpeakingQuery({this.search, this.status, this.page = 1});

  final String? search;
  final String? status;
  final int page;

  Map<String, dynamic> toQuery() => {
    if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
    if (status?.isNotEmpty == true) 'status': status,
    'page': page,
    'per_page': 15,
  };

  AdminSpeakingQuery copyWith({
    String? search,
    String? status,
    int? page,
    bool clearStatus = false,
  }) => AdminSpeakingQuery(
    search: search ?? this.search,
    status: clearStatus ? null : status ?? this.status,
    page: page ?? this.page,
  );
}

class AdminSpeakingPage {
  const AdminSpeakingPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminSpeakingTemplate> items;
  final int currentPage;
  final int lastPage;
  final int total;
  bool get hasMore => currentPage < lastPage;

  factory AdminSpeakingPage.fromJson(Map<String, dynamic>? json) {
    final rows = json?['data'] is List
        ? (json!['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdminSpeakingTemplate.fromJson)
              .toList()
        : <AdminSpeakingTemplate>[];
    final meta = _map(json?['meta']);
    return AdminSpeakingPage(
      items: rows,
      currentPage: _int(meta['current_page']) ?? 1,
      lastPage: _int(meta['last_page']) ?? 1,
      total: _int(meta['total']) ?? rows.length,
    );
  }
}

class AdminSpeakingTemplate {
  const AdminSpeakingTemplate({
    required this.id,
    required this.title,
    required this.targetText,
    required this.status,
    required this.difficulty,
    this.targetTranslation,
    this.promptText,
    this.referenceAudioMediaId,
    this.referenceAudioUrl,
    this.referenceAudioName,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String targetText;
  final String status;
  final String difficulty;
  final String? targetTranslation;
  final String? promptText;
  final String? referenceAudioMediaId;
  final String? referenceAudioUrl;
  final String? referenceAudioName;
  final String? updatedAt;

  AdminSpeakingTemplate copyWith({String? referenceAudioUrl}) =>
      AdminSpeakingTemplate(
        id: id,
        title: title,
        targetText: targetText,
        status: status,
        difficulty: difficulty,
        targetTranslation: targetTranslation,
        promptText: promptText,
        referenceAudioMediaId: referenceAudioMediaId,
        referenceAudioUrl: referenceAudioUrl ?? this.referenceAudioUrl,
        referenceAudioName: referenceAudioName,
        updatedAt: updatedAt,
      );

  factory AdminSpeakingTemplate.fromJson(Map<String, dynamic> json) {
    final audio = _map(json['reference_audio']);
    return AdminSpeakingTemplate(
      id: _string(json['id']),
      title: _string(json['title'], 'Tanpa judul'),
      targetText: _string(json['target_text']),
      targetTranslation: _nullable(json['target_translation']),
      promptText: _nullable(json['prompt_text']),
      difficulty: _string(json['difficulty'], 'beginner'),
      status: _string(json['status'], 'draft'),
      referenceAudioMediaId: _nullable(json['reference_audio_media_id']),
      referenceAudioUrl: _nullable(audio['url']),
      referenceAudioName: _nullable(
        audio['original_name'] ?? audio['file_name'],
      ),
      updatedAt: _nullable(json['updated_at']),
    );
  }
}

class AdminSpeakingSaveRequest {
  const AdminSpeakingSaveRequest({
    required this.title,
    required this.targetText,
    required this.targetTranslation,
    required this.promptText,
    required this.difficulty,
    required this.status,
    required this.referenceAudioMediaId,
  });

  final String title;
  final String targetText;
  final String targetTranslation;
  final String promptText;
  final String difficulty;
  final String status;
  final String? referenceAudioMediaId;

  Map<String, dynamic> toJson() => {
    'title': title,
    'target_text': targetText,
    'target_translation': targetTranslation.isEmpty ? null : targetTranslation,
    'prompt_text': promptText.isEmpty ? null : promptText,
    'difficulty': difficulty,
    'status': status,
    'reference_audio_media_id': referenceAudioMediaId,
  };
}

class AdminSpeakingRepository {
  const AdminSpeakingRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<AdminSpeakingPage> list(AdminSpeakingQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/speaking/exercises',
        queryParameters: query.toQuery(),
      );
      return AdminSpeakingPage.fromJson(response.data);
    } catch (error) {
      throw _safeError(error);
    }
  }

  Future<AdminSpeakingTemplate> detail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/speaking/exercises/$id',
      );
      final item = AdminSpeakingTemplate.fromJson(_map(response.data?['data']));
      if (item.referenceAudioUrl != null ||
          item.referenceAudioMediaId == null) {
        return item;
      }
      final temporary = await _dio.post<Map<String, dynamic>>(
        '/media/${item.referenceAudioMediaId}/temporary-url',
      );
      final url = _nullable(_map(temporary.data?['data'])['url']);
      return url == null ? item : item.copyWith(referenceAudioUrl: url);
    } catch (error) {
      throw _safeError(error);
    }
  }

  Future<AdminSpeakingTemplate> save({
    String? id,
    required AdminSpeakingSaveRequest request,
  }) async {
    try {
      final response = id == null
          ? await _dio.post<Map<String, dynamic>>(
              '/admin/speaking/exercises',
              data: request.toJson(),
            )
          : await _dio.patch<Map<String, dynamic>>(
              '/admin/speaking/exercises/$id',
              data: request.toJson(),
            );
      return AdminSpeakingTemplate.fromJson(_map(response.data?['data']));
    } catch (error) {
      throw _safeError(error);
    }
  }

  Future<String> uploadAudio({
    required String path,
    required String name,
    ProgressCallback? onProgress,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/media',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(path, filename: name),
          'purpose': 'speaking_reference_audio',
          'visibility': 'public',
        }),
        onSendProgress: onProgress,
      );
      final id = _string(_map(response.data?['data'])['id']);
      if (id.isEmpty) throw StateError('missing media');
      return id;
    } catch (error) {
      throw _safeError(error);
    }
  }

  Future<void> archive(String id) async {
    try {
      await _dio.patch<void>('/admin/speaking/exercises/$id/archive');
    } catch (error) {
      throw _safeError(error);
    }
  }

  AppError _safeError(Object error) {
    final mapped = _errorMapper.map(error);
    return AppError(
      type: mapped.type,
      message: switch (mapped.type) {
        AppErrorType.validation =>
          'Data belum valid. Periksa isian lalu coba lagi.',
        AppErrorType.notFound => 'Template speaking tidak ditemukan.',
        AppErrorType.networkUnavailable ||
        AppErrorType.timeout => mapped.message,
        _ => 'Template speaking belum bisa diproses. Silakan coba lagi.',
      },
      fieldErrors: mapped.fieldErrors,
    );
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};
String _string(Object? value, [String fallback = '']) =>
    value is String && value.trim().isNotEmpty ? value : fallback;
String? _nullable(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;
int? _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');
