import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../data/chatbot_models.dart';
import '../data/chatbot_providers.dart';
import '../data/chatbot_repository.dart';

final chatbotControllerProvider =
    StateNotifierProvider.autoDispose<ChatbotController, ChatbotState>((ref) {
      return ChatbotController(ref.watch(chatbotRepositoryProvider));
    });

class ChatbotState {
  const ChatbotState({
    this.messages = const [],
    this.isSending = false,
    this.error,
    this.pendingMessage,
  });

  final List<ChatbotMessage> messages;
  final bool isSending;
  final AppError? error;
  final String? pendingMessage;

  ChatbotState copyWith({
    List<ChatbotMessage>? messages,
    bool? isSending,
    AppError? error,
    bool clearError = false,
    String? pendingMessage,
    bool clearPendingMessage = false,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : error ?? this.error,
      pendingMessage: clearPendingMessage
          ? null
          : pendingMessage ?? this.pendingMessage,
    );
  }
}

class ChatbotController extends StateNotifier<ChatbotState> {
  ChatbotController(this._repository) : super(const ChatbotState());

  final ChatbotRepository _repository;
  int _nextId = 0;

  Future<void> send(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || state.isSending) return;

    state = state.copyWith(
      isSending: true,
      clearError: true,
      pendingMessage: message,
    );
    try {
      final response = await _repository.sendMessage(message);
      if (!mounted) return;
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatbotMessage(
            id: _messageId(),
            role: ChatbotMessageRole.user,
            content: message,
          ),
          ChatbotMessage(
            id: _messageId(),
            role: ChatbotMessageRole.assistant,
            content: response.answer,
            response: response,
          ),
        ],
        isSending: false,
        clearPendingMessage: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(isSending: false, error: _asAppError(error));
    }
  }

  Future<void> retry() async {
    final message = state.pendingMessage;
    if (message == null || state.isSending) return;
    await send(message);
  }

  String _messageId() {
    _nextId += 1;
    return 'chat-$_nextId';
  }

  AppError _asAppError(Object error) {
    if (error is AppError) return error;
    return const AppError(
      type: AppErrorType.unknown,
      message: 'Gagal mengirim pertanyaan. Coba lagi.',
    );
  }
}
