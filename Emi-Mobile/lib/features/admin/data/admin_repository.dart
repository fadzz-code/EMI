import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';

class AdminSummary {
  const AdminSummary({required this.items});

  final List<AdminMetric> items;

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    final metrics = <AdminMetric>[];
    void walk(String prefix, Object? value) {
      if (value is num || value is String || value is bool) {
        metrics.add(AdminMetric(label: prefix, value: '$value'));
      } else if (value is Map<String, dynamic>) {
        for (final entry in value.entries) {
          walk(
            prefix.isEmpty ? entry.key : '$prefix ${entry.key}',
            entry.value,
          );
        }
      }
    }

    for (final entry in json.entries) {
      walk(entry.key, entry.value);
    }
    return AdminSummary(items: metrics.take(12).toList());
  }
}

class AdminMetric {
  const AdminMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class AdminListQuery {
  const AdminListQuery({this.search, this.page = 1});

  final String? search;
  final int page;

  Map<String, dynamic> toQuery() => {
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
    'page': page,
    'per_page': 15,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminListQuery && other.search == search && other.page == page;

  @override
  int get hashCode => Object.hash(search, page);
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

  Object _map(Object error) =>
      error is AppError ? error : _errorMapper.map(error);
}
