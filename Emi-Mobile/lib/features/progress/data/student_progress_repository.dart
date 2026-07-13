import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import 'student_progress.dart';

class StudentProgressRepository {
  const StudentProgressRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<StudentProgressReport> report({int page = 1, int perPage = 15}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/reports/progress',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final json = response.data;
      if (json == null) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Data progress tidak valid.',
        );
      }
      return StudentProgressReport.fromJson(json);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }
}
