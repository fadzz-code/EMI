class ChatbotSource {
  const ChatbotSource({
    required this.id,
    required this.title,
    this.category,
    this.sourceType,
    this.sourceUrl,
  });

  final String id;
  final String title;
  final String? category;
  final String? sourceType;
  final String? sourceUrl;

  factory ChatbotSource.fromJson(Map<String, dynamic> json) {
    return ChatbotSource(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String?,
      sourceType: json['source_type'] as String?,
      sourceUrl: json['source_url'] as String?,
    );
  }
}

class ChatbotResponse {
  const ChatbotResponse({
    required this.answer,
    required this.matched,
    required this.mode,
    required this.provider,
    required this.conversationId,
    this.source,
    this.confidence,
  });

  final String answer;
  final bool matched;
  final String mode;
  final String provider;
  final ChatbotSource? source;
  final num? confidence;

  /// The conversation this message was appended to (server creates one if
  /// the request did not send `conversation_id`). Callers should persist
  /// this and send it back on the next `sendMessage` call to keep the
  /// exchange in the same conversation/history thread.
  final String conversationId;

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    final source = json['source'];
    return ChatbotResponse(
      answer: json['answer'] as String? ?? '',
      matched: json['matched'] == true,
      mode: json['mode'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      source: source is Map<String, dynamic>
          ? ChatbotSource.fromJson(source)
          : null,
      confidence: json['confidence'] as num?,
      conversationId: json['conversation_id'] as String? ?? '',
    );
  }
}

enum ChatbotMessageRole { user, assistant }

ChatbotMessageRole _roleFromString(String? value) {
  return value == 'assistant'
      ? ChatbotMessageRole.assistant
      : ChatbotMessageRole.user;
}

class ChatbotMessage {
  const ChatbotMessage({
    required this.id,
    required this.role,
    required this.content,
    this.response,
  });

  final String id;
  final ChatbotMessageRole role;
  final String content;
  final ChatbotResponse? response;
}

/// One conversation entry as returned by
/// `GET /{role}/chatbot/conversations` (list view, no message bodies).
class ChatbotConversationSummary {
  const ChatbotConversationSummary({
    required this.id,
    required this.status,
    this.title,
    this.lastMessageAt,
    this.createdAt,
  });

  final String id;
  final String? title;
  final String status;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  factory ChatbotConversationSummary.fromJson(Map<String, dynamic> json) {
    return ChatbotConversationSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      status: json['status'] as String? ?? 'active',
      lastMessageAt: DateTime.tryParse(
        json['last_message_at'] as String? ?? '',
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

/// A single stored message inside a conversation, as returned by
/// `GET /{role}/chatbot/conversations/{id}` (detail view).
class ChatbotConversationMessage {
  const ChatbotConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    this.citations = const [],
  });

  final String id;
  final ChatbotMessageRole role;
  final String content;
  final List<ChatbotSource> citations;

  factory ChatbotConversationMessage.fromJson(Map<String, dynamic> json) {
    final citations = json['citations'];
    return ChatbotConversationMessage(
      id: json['id'] as String? ?? '',
      role: _roleFromString(json['role'] as String?),
      content: json['content'] as String? ?? '',
      citations: citations is List
          ? citations
                .whereType<Map<String, dynamic>>()
                .map(ChatbotSource.fromJson)
                .toList()
          : const [],
    );
  }
}

/// Full conversation detail: summary fields plus its ordered messages.
class ChatbotConversationDetail extends ChatbotConversationSummary {
  const ChatbotConversationDetail({
    required super.id,
    required super.status,
    required this.messages,
    super.title,
    super.lastMessageAt,
    super.createdAt,
  });

  final List<ChatbotConversationMessage> messages;

  factory ChatbotConversationDetail.fromJson(Map<String, dynamic> json) {
    final messages = json['messages'];
    return ChatbotConversationDetail(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      status: json['status'] as String? ?? 'active',
      lastMessageAt: DateTime.tryParse(
        json['last_message_at'] as String? ?? '',
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      messages: messages is List
          ? messages
                .whereType<Map<String, dynamic>>()
                .map(ChatbotConversationMessage.fromJson)
                .toList()
          : const [],
    );
  }
}
