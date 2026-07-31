import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'chatbot_repository.dart';

final chatbotRepositoryProvider = Provider<ChatbotRepository>(
  (ref) => ChatbotRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

/// Same chatbot backend contract, scoped to the Teacher role's
/// `/teacher/chatbot/*` endpoints.
final teacherChatbotRepositoryProvider = Provider<ChatbotRepository>(
  (ref) => ChatbotRepository(
    ref.watch(dioProvider),
    const DioErrorMapper(),
    basePath: '/teacher/chatbot',
  ),
);
