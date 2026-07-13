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
}
