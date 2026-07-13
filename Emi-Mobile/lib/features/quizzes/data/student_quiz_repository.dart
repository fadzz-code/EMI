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

  Future<QuizAttempt> startAttempt(String quizId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/class-quizzes/$quizId/attempts',
      );
      return _attempt(response.data?['data'], 'Attempt kuis tidak valid.');
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<QuizAttempt> attempt(String attemptId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/quiz-attempts/$attemptId',
      );
      return _attempt(response.data?['data'], 'Detail attempt tidak valid.');
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<QuizAnswer> saveAnswer({
    required String attemptId,
    required String questionId,
    String? selectedOptionId,
    String? answerText,
  }) async {
    try {
      final payload = <String, String>{};
      if (selectedOptionId != null) {
        payload['selected_option_id'] = selectedOptionId;
      }
      if (answerText != null) {
        payload['answer_text'] = answerText;
      }
      final response = await _dio.put<Map<String, dynamic>>(
        '/quiz-attempts/$attemptId/answers/$questionId',
        data: payload,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Jawaban kuis tidak valid.',
        );
      }
      return QuizAnswer.fromJson(data);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<QuizAttempt> submitAttempt({
    required String attemptId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/quiz-attempts/$attemptId/submit',
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      return _attempt(response.data?['data'], 'Hasil kuis tidak valid.');
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

  QuizAttempt _attempt(Object? data, String message) {
    if (data is! Map<String, dynamic>) {
      throw AppError(type: AppErrorType.unknown, message: message);
    }
    return QuizAttempt.fromJson(data);
  }
}
