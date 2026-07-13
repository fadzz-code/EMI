import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import 'student_module.dart';

class StudentModuleRepository {
  const StudentModuleRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<StudentModulePage> list({
    String? search,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/modules',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final json = response.data;
      if (json == null) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Data modul tidak valid.',
        );
      }
      return StudentModulePage.fromJson(json);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<StudentModule> detail(String moduleId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/modules/$moduleId',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Detail modul tidak valid.',
        );
      }
      return StudentModule.fromJson(data);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<StudentLesson> lesson(String lessonId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/class-lessons/$lessonId',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Detail lesson tidak valid.',
        );
      }
      return StudentLesson.fromJson(data);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<LessonContent?> lessonContent(String lessonId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/class-lessons/$lessonId/content-url',
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return LessonContent.fromJson(data);
      return null;
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<LessonProgress> completeLesson(String lessonId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/student/lessons/$lessonId/progress',
        data: {'status': 'completed', 'progress_percent': 100},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Progress lesson tidak valid.',
        );
      }
      return LessonProgress.fromJson(data);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<ModuleProgress> startModule(String moduleId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/student/modules/$moduleId/start',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Progress modul tidak valid.',
        );
      }
      return ModuleProgress.fromJson(data);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }
}
