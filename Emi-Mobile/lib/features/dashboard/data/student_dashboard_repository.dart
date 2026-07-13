import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import 'student_dashboard_summary.dart';

class StudentDashboardRepository {
  const StudentDashboardRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<StudentDashboardSummary> summary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/dashboard/summary',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Data dashboard tidak valid.',
        );
      }
      return StudentDashboardSummary.fromJson(data);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }
}
