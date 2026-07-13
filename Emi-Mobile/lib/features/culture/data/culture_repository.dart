import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import 'culture_models.dart';

class CultureRepository {
  const CultureRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<CulturePage> list({int page = 1, int perPage = 15}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/culture',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final json = response.data;
      if (json == null) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Data budaya tidak valid.',
        );
      }
      return CulturePage.fromJson(json);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }
}
