import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'chatbot_repository.dart';

final chatbotRepositoryProvider = Provider<ChatbotRepository>(
  (ref) => ChatbotRepository(ref.watch(dioProvider), const DioErrorMapper()),
);
