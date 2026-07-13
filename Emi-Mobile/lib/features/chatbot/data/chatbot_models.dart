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
    this.source,
    this.confidence,
  });

  final String answer;
  final bool matched;
  final String mode;
  final String provider;
  final ChatbotSource? source;
  final num? confidence;

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
    );
  }
}

enum ChatbotMessageRole { user, assistant }

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
