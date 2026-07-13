import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../data/chatbot_models.dart';
import 'chatbot_controller.dart';

class StudentChatbotScreen extends ConsumerStatefulWidget {
  const StudentChatbotScreen({super.key});

  @override
  ConsumerState<StudentChatbotScreen> createState() =>
      _StudentChatbotScreenState();
}

class _StudentChatbotScreenState extends ConsumerState<StudentChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _stickToBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateStickiness);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateStickiness);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chatbotControllerProvider, (_, next) {
      if (_stickToBottom) _scrollToBottom();
      if (!next.isSending && next.error == null) _messageController.clear();
    });

    final state = ref.watch(chatbotControllerProvider);

    return EmiScaffold(
      title: 'Chatbot AI',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                const _IntroCard(),
                if (state.error != null) ...[
                  const SizedBox(height: EmiSpacing.md),
                  _ErrorCard(
                    message: state.error!.message,
                    onRetry: state.pendingMessage == null
                        ? null
                        : () => ref
                              .read(chatbotControllerProvider.notifier)
                              .retry(),
                  ),
                ],
                const SizedBox(height: EmiSpacing.md),
                if (state.messages.isEmpty) const _EmptyChat(),
                for (final message in state.messages) _ChatBubble(message),
                if (state.isSending) const _TypingBubble(),
              ],
            ),
          ),
          _ChatInput(
            controller: _messageController,
            isSending: state.isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  void _send() {
    ref.read(chatbotControllerProvider.notifier).send(_messageController.text);
  }

  void _updateStickiness() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _stickToBottom = position.maxScrollExtent - position.pixels < 120;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(EmiSpacing.sm),
                decoration: BoxDecoration(
                  color: EmiColors.secondary,
                  border: Border.all(color: EmiColors.border, width: 2),
                  borderRadius: BorderRadius.circular(EmiRadii.pill),
                  boxShadow: const [EmiShadows.hard],
                ),
                child: const Icon(Icons.auto_awesome_outlined),
              ),
              const SizedBox(width: EmiSpacing.md),
              Expanded(
                child: Text(
                  'Tanya materi Bahasa Mekongga',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: EmiSpacing.md),
          const Text(
            'EMI menjawab dari Basis AI yang dipublish admin dan menampilkan referensi jika cocok.',
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (onRetry != null) ...[
            const SizedBox(height: EmiSpacing.sm),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const _AssistantBubble(
      content:
          'Halo! Kamu bisa bertanya tentang kosakata, budaya, atau materi Bahasa Mekongga.',
      response: null,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble(this.message);

  final ChatbotMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.role == ChatbotMessageRole.user) {
      return _UserBubble(content: message.content);
    }
    return _AssistantBubble(
      content: message.content,
      response: message.response,
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: EmiSpacing.md),
        padding: const EdgeInsets.all(EmiSpacing.md),
        decoration: BoxDecoration(
          color: EmiColors.primary,
          border: Border.all(color: EmiColors.border, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: const [EmiShadows.hard],
        ),
        child: Text(content),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.content, required this.response});

  static const _answerPrefix =
      'Berdasarkan Basis AI EMI, berikut informasi yang ditemukan:';

  final String content;
  final ChatbotResponse? response;

  @override
  Widget build(BuildContext context) {
    final source = response?.source;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: EmiSpacing.md),
        padding: const EdgeInsets.all(EmiSpacing.md),
        decoration: BoxDecoration(
          color: EmiColors.surface,
          border: Border.all(color: EmiColors.border, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: const [EmiShadows.hard],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_displayAnswer(content)),
            if (response != null && response!.matched) ...[
              const SizedBox(height: EmiSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: EmiColors.background,
                  border: Border.all(color: EmiColors.border),
                  borderRadius: BorderRadius.circular(EmiRadii.pill),
                ),
                child: const Text('Referensi tersedia'),
              ),
            ],
            if (source != null) ...[
              const SizedBox(height: EmiSpacing.sm),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text('Sumber: ${source.title}'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Kategori: ${source.category ?? 'Umum'}'),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Jenis sumber: ${_sourceTypeLabel(source.sourceType)}',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _displayAnswer(String value) {
    return value.startsWith(_answerPrefix)
        ? value.substring(_answerPrefix.length).trim()
        : value;
  }

  String _sourceTypeLabel(String? sourceType) {
    return switch (sourceType) {
      'pdf' => 'PDF / Dokumen',
      'link' => 'Link',
      _ => 'Teks Manual',
    };
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: EmiCard(child: Text('EMI sedang mencari jawaban...')),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(EmiSpacing.md),
        decoration: const BoxDecoration(
          color: EmiColors.surface,
          border: Border(top: BorderSide(color: EmiColors.border, width: 2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Tanyakan materi, kosakata, atau budaya...',
                ),
              ),
            ),
            const SizedBox(width: EmiSpacing.sm),
            ElevatedButton(
              onPressed: isSending ? null : onSend,
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
