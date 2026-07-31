import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import '../../../shared/models/api_response.dart';
import 'chatbot_models.dart';

class ChatbotRepository {
  const ChatbotRepository(
    this._dio,
    this._errorMapper, {
    this.basePath = '/student/chatbot',
  });

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  /// API prefix for this role's chatbot endpoints. Student and Teacher
  /// share identical request/response shapes on the backend
  /// (`StudentChatbotController` is reused under `/teacher/chatbot/*`),
  /// only the path prefix differs.
  final String basePath;

  Future<ChatbotResponse> sendMessage(
    String message, {
    String? conversationId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$basePath/messages',
        data: {'message': message, 'conversation_id': ?conversationId},
      );
      final payload = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? {},
        (value) => value as Map<String, dynamic>,
      );
      final data = payload.data;
      if (data == null) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Respons Chatbot AI tidak tersedia.',
        );
      }
      return ChatbotResponse.fromJson(data);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<List<ChatbotConversationSummary>> listConversations() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$basePath/conversations',
        queryParameters: {'per_page': 30},
      );
      final data = response.data?['data'];
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatbotConversationSummary.fromJson)
          .toList();
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<ChatbotConversationDetail> getConversation(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$basePath/conversations/$id',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppError(
          type: AppErrorType.unknown,
          message: 'Detail percakapan tidak tersedia.',
        );
      }
      return ChatbotConversationDetail.fromJson(data);
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('$basePath/conversations/$id');
    } catch (error) {
      if (error is AppError) rethrow;
      throw _errorMapper.map(error);
    }
  }
}
