import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import 'admin_progress_models.dart';

class AdminProgressOption {
  const AdminProgressOption(this.id, this.name);
  final String id;
  final String name;
  factory AdminProgressOption.fromJson(Map<String, dynamic> json) =>
      AdminProgressOption('${json['id'] ?? ''}', '${json['name'] ?? ''}');
}

class AdminProgressRepository {
  const AdminProgressRepository(this._dio, this._mapper);
  final Dio _dio;
  final DioErrorMapper _mapper;

  Future<AdminProgressOverview> overview(
    AdminProgressFilters filters, {
    int studentPage = 1,
    int classPage = 1,
  }) async => _get(
    '/admin/reports/progress/overview',
    filters.query(studentPage: studentPage, classPage: classPage),
    AdminProgressOverview.fromJson,
  );

  Future<AdminStudentProgressDetail> student(String id, {int page = 1}) async =>
      _get('/admin/reports/progress/students/$id', {
        'quiz_page': page,
      }, AdminStudentProgressDetail.fromJson);

  Future<AdminClassProgressDetail> schoolClass(
    String id, {
    int page = 1,
  }) async => _get('/admin/reports/progress/classes/$id', {
    'page': page,
  }, AdminClassProgressDetail.fromJson);

  Future<AdminProgressPage<AdminProgressSchool>> schoolReport({int page = 1}) =>
      _page('/admin/reports/progress/schools', {
        'page': page,
      }, AdminProgressSchool.fromJson);

  Future<AdminProgressPage<AdminQuizResultRow>> quizResults({
    int page = 1,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/reports/quiz-results',
        queryParameters: {'page': page},
      );
      final data = response.data?['data'];
      final rows = data is Map ? data['rows'] : null;
      return AdminProgressPage(
        items: (rows as List? ?? const [])
            .whereType<Map>()
            .map(
              (e) => AdminQuizResultRow.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
        meta: AdminProgressMeta.fromJson(response.data?['meta']),
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<List<int>> csv(String report, AdminProgressFilters filters) async {
    try {
      final response = await _dio.get<List<int>>(
        '/admin/reports/$report/export',
        queryParameters: filters.query(studentPage: 1, classPage: 1)
          ..removeWhere((key, _) => key.endsWith('_page')),
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } catch (error) {
      throw _map(error);
    }
  }

  Future<List<AdminProgressOption>> schools() => _options('/schools');
  Future<List<AdminProgressOption>> classes(String? schoolId) =>
      _options('/classes', {'per_page': 100, 'school_id': ?schoolId});

  Future<List<int>> pdf({
    String? studentId,
    String? classId,
    AdminProgressFilters filters = const AdminProgressFilters(),
  }) async {
    final path = studentId != null
        ? '/admin/reports/progress/students/$studentId/pdf'
        : classId != null
        ? '/admin/reports/progress/classes/$classId/pdf'
        : '/admin/reports/progress/pdf';
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: filters.query(studentPage: 1, classPage: 1)
          ..removeWhere((key, _) => key.endsWith('_page')),
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } catch (error) {
      throw _map(error);
    }
  }

  Future<AdminProgressPage<T>> _page<T>(
    String path,
    Map<String, dynamic> query,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      return AdminProgressPage(
        items: (response.data?['data'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => parse(Map<String, dynamic>.from(e)))
            .toList(),
        meta: AdminProgressMeta.fromJson(response.data?['meta']),
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Future<List<AdminProgressOption>> _options(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query ?? const {'per_page': 100},
      );
      final raw = response.data?['data'];
      final list = raw is Map ? raw['data'] : raw;
      return (list as List? ?? const [])
          .whereType<Map>()
          .map(
            (e) => AdminProgressOption.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } catch (error) {
      throw _map(error);
    }
  }

  Future<T> _get<T>(
    String path,
    Map<String, dynamic> query,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      final data = response.data?['data'];
      if (data is Map) return parse(Map<String, dynamic>.from(data));
      throw const AppError(
        type: AppErrorType.unknown,
        message: 'Data progress tidak valid.',
      );
    } catch (error) {
      throw _map(error);
    }
  }

  Object _map(Object error) => error is AppError ? error : _mapper.map(error);
}
