import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import '../../../shared/models/api_response.dart';
import 'chatbot_models.dart';

class ChatbotRepository {
  const ChatbotRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<ChatbotResponse> sendMessage(String message) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/student/chatbot/messages',
        data: {'message': message},
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
}
