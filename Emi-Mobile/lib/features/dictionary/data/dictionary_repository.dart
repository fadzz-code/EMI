import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import 'dictionary_entry.dart';

class DictionaryRepository {
  const DictionaryRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<DictionaryPage> list({
    String? search,
    String language = 'all',
    String? categoryId,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/dictionary',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          'language': language,
          if (categoryId != null && categoryId.isNotEmpty)
            'category_id': categoryId,
        },
      );
      final json = response.data;
      if (json == null) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Data kamus tidak valid.',
        );
      }
      return DictionaryPage.fromJson(json);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<DictionaryEntry> detail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/dictionary/$id');
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Detail kamus tidak valid.',
        );
      }
      return DictionaryEntry.fromJson(data);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }
}
