import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import 'student_quiz.dart';

class StudentQuizRepository {
  const StudentQuizRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<StudentQuizPage> list({
    String? availability,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParameters = <String, Object>{
        'page': page,
        'per_page': perPage,
      };
      if (availability != null) {
        queryParameters['availability'] = availability;
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/quizzes',
        queryParameters: queryParameters,
      );
      final json = response.data;
      if (json == null) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Data kuis tidak valid.',
        );
      }
      return StudentQuizPage.fromJson(json);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<StudentQuiz> detail(String quizId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/quizzes/$quizId',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Detail kuis tidak valid.',
        );
      }
      return StudentQuiz.fromJson(data);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }
}
