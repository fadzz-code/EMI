import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import 'teacher_quiz_models.dart';

class TeacherQuizRepository {
  const TeacherQuizRepository(this._dio, this._mapper);
  final Dio _dio;
  final DioErrorMapper _mapper;

  Future<TeacherQuizPage> list({
    int page = 1,
    String? search,
    String? status,
  }) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/class-quizzes',
      queryParameters: {
        'page': page,
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (status?.isNotEmpty == true) 'status': status,
      },
    ),
    TeacherQuizPage.fromJson,
  );

  Future<TeacherQuizPage> classList(String classId) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/class-quizzes',
      queryParameters: {'class_id': classId, 'per_page': 100},
    ),
    TeacherQuizPage.fromJson,
  );

  Future<TeacherQuiz> detail(String id) =>
      _item(() => _dio.get('/class-quizzes/$id'));
  Future<TeacherQuiz> create(Map<String, dynamic> data) =>
      _item(() => _dio.post('/class-quizzes', data: data));
  Future<TeacherQuiz> update(String id, Map<String, dynamic> data) =>
      _item(() => _dio.put('/class-quizzes/$id', data: data));
  Future<TeacherQuiz> publish(String id) =>
      _item(() => _dio.post('/class-quizzes/$id/publish'));
  Future<TeacherQuiz> archive(String id) =>
      _item(() => _dio.post('/class-quizzes/$id/archive'));
  Future<void> deleteQuiz(String id) => _request(
    () => _dio.delete<Map<String, dynamic>>('/class-quizzes/$id'),
    (_) {},
  );
  Future<String> uploadQuestionImage(String path, String name) => _request(
    () async => _dio.post<Map<String, dynamic>>(
      '/media',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: name),
        'purpose': 'question_image',
        'visibility': 'public',
      }),
    ),
    (json) => _text(_data(json)['id']),
  );
  Future<TeacherQuizQuestion> question(String id) =>
      _question(() => _dio.get('/quiz-questions/$id'));
  Future<TeacherQuizQuestion> createQuestion(
    String quizId,
    Map<String, dynamic> data,
  ) => _question(
    () => _dio.post('/class-quizzes/$quizId/questions', data: data),
  );
  Future<TeacherQuizQuestion> updateQuestion(
    String id,
    Map<String, dynamic> data,
  ) => _question(() => _dio.put('/quiz-questions/$id', data: data));
  Future<void> deleteQuestion(String id) => _request(
    () => _dio.delete<Map<String, dynamic>>('/quiz-questions/$id'),
    (_) {},
  );
  Future<void> reorderQuestions(String quizId, List<String> questionIds) async {
    try {
      await _dio.patch<void>(
        '/class-quizzes/$quizId/questions/reorder',
        data: {'question_ids': questionIds},
      );
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }
  Future<TeacherQuizAttemptPage> attempts(
    String quizId, {
    int page = 1,
    String? status,
  }) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/class-quizzes/$quizId/attempts',
      queryParameters: {
        'page': page,
        if (status?.isNotEmpty == true) 'status': status,
      },
    ),
    TeacherQuizAttemptPage.fromJson,
  );
  Future<TeacherQuizReportSummary> classQuizReport(String quizId) => _request(
    () => _dio.get<Map<String, dynamic>>('/class-quizzes/$quizId/report'),
    TeacherQuizReportSummary.fromJson,
  );

  Future<TeacherQuizResultPage> report({
    int page = 1,
    String? quizId,
    String? status,
  }) => _request(
    () => _dio.get<Map<String, dynamic>>(
      '/teacher/reports/quiz-results',
      queryParameters: {
        'page': page,
        if (quizId?.isNotEmpty == true) 'quiz_id': quizId,
        if (status?.isNotEmpty == true) 'status': status,
      },
    ),
    TeacherQuizResultPage.fromJson,
  );

  Future<List<int>> reportCsv({
    String? quizId,
    String? status,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        '/teacher/reports/quiz-results/export',
        queryParameters: {
          if (quizId?.isNotEmpty == true) 'quiz_id': quizId,
          if (status?.isNotEmpty == true) 'status': status,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }

  Future<TeacherQuizAttempt> attempt(String id) => _request(
    () => _dio.get<Map<String, dynamic>>('/quiz-attempts/$id'),
    (json) => TeacherQuizAttempt.fromJson(_data(json)),
  );

  Future<TeacherQuiz> _item(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) => _request(call, (json) => TeacherQuiz.fromJson(_data(json)));
  Future<TeacherQuizQuestion> _question(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) => _request(call, (json) => TeacherQuizQuestion.fromJson(_data(json)));
  Future<T> _request<T>(
    Future<Response<Map<String, dynamic>>> Function() call,
    T Function(Map<String, dynamic>?) parse,
  ) async {
    try {
      return parse((await call()).data);
    } catch (error) {
      throw error is AppError ? error : _mapper.map(error);
    }
  }
}

String _text(Object? value) => value is String ? value : '';

Map<String, dynamic> _data(Map<String, dynamic>? json) {
  final data = json?['data'];
  if (data is Map<String, dynamic>) return data;
  throw const AppError(
    type: AppErrorType.unknown,
    message: 'Data kuis tidak valid.',
  );
}
