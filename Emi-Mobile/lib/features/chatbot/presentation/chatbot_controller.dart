import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../data/chatbot_models.dart';
import '../data/chatbot_providers.dart';
import '../data/chatbot_repository.dart';

final chatbotControllerProvider =
    StateNotifierProvider.autoDispose<ChatbotController, ChatbotState>((ref) {
      return ChatbotController(ref.watch(chatbotRepositoryProvider));
    });

/// Same controller logic, wired to the Teacher chatbot endpoints.
final teacherChatbotControllerProvider =
    StateNotifierProvider.autoDispose<ChatbotController, ChatbotState>((ref) {
      return ChatbotController(ref.watch(teacherChatbotRepositoryProvider));
    });

class ChatbotState {
  const ChatbotState({
    this.messages = const [],
    this.conversations = const [],
    this.activeConversationId,
    this.isSending = false,
    this.isLoadingConversations = false,
    this.isLoadingHistory = false,
    this.error,
    this.pendingMessage,
  });

  final List<ChatbotMessage> messages;
  final List<ChatbotConversationSummary> conversations;
  final String? activeConversationId;
  final bool isSending;
  final bool isLoadingConversations;
  final bool isLoadingHistory;
  final AppError? error;
  final String? pendingMessage;

  ChatbotState copyWith({
    List<ChatbotMessage>? messages,
    List<ChatbotConversationSummary>? conversations,
    String? activeConversationId,
    bool clearActiveConversationId = false,
    bool? isSending,
    bool? isLoadingConversations,
    bool? isLoadingHistory,
    AppError? error,
    bool clearError = false,
    String? pendingMessage,
    bool clearPendingMessage = false,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      activeConversationId: clearActiveConversationId
          ? null
          : activeConversationId ?? this.activeConversationId,
      isSending: isSending ?? this.isSending,
      isLoadingConversations:
          isLoadingConversations ?? this.isLoadingConversations,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: clearError ? null : error ?? this.error,
      pendingMessage: clearPendingMessage
          ? null
          : pendingMessage ?? this.pendingMessage,
    );
  }
}

class ChatbotController extends StateNotifier<ChatbotState> {
  ChatbotController(this._repository) : super(const ChatbotState()) {
    loadConversations();
  }

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
      final response = await _repository.sendMessage(
        message,
        conversationId: state.activeConversationId,
      );
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
        activeConversationId: response.conversationId.isEmpty
            ? null
            : response.conversationId,
        isSending: false,
        clearPendingMessage: true,
      );
      unawaited(loadConversations());
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

  /// Refreshes the conversation history sidebar. Safe to call in the
  /// background (e.g. after sending a message) — failures are silent
  /// since this is a secondary list, not the primary send flow.
  Future<void> loadConversations() async {
    state = state.copyWith(isLoadingConversations: true);
    try {
      final conversations = await _repository.listConversations();
      if (!mounted) return;
      state = state.copyWith(
        conversations: conversations,
        isLoadingConversations: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoadingConversations: false);
    }
  }

  /// Loads a past conversation's messages and makes it the active thread,
  /// so subsequent `send()` calls append to it (mirrors the web app's
  /// "open conversation" behavior).
  Future<void> openConversation(String id) async {
    if (state.isLoadingHistory) return;
    state = state.copyWith(
      isLoadingHistory: true,
      clearError: true,
      activeConversationId: id,
    );
    try {
      final detail = await _repository.getConversation(id);
      if (!mounted) return;
      state = state.copyWith(
        messages: detail.messages
            .map(
              (message) => ChatbotMessage(
                id: message.id,
                role: message.role,
                content: message.content,
                response: ChatbotResponse(
                  answer: message.content,
                  matched: message.citations.isNotEmpty,
                  mode: 'history',
                  provider: 'history',
                  conversationId: detail.id,
                  source: message.citations.isNotEmpty
                      ? message.citations.first
                      : null,
                ),
              ),
            )
            .toList(),
        isLoadingHistory: false,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingHistory: false,
        error: _asAppError(error),
      );
    }
  }

  /// Clears the active thread so the next message starts a brand-new
  /// conversation on the server (mirrors the web app's "new session").
  void startNewSession() {
    state = state.copyWith(
      messages: const [],
      clearActiveConversationId: true,
      clearError: true,
      clearPendingMessage: true,
    );
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _repository.deleteConversation(id);
      if (!mounted) return;
      if (state.activeConversationId == id) {
        startNewSession();
      }
      await loadConversations();
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(error: _asAppError(error));
    }
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
