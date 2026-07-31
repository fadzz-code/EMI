import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/emi_theme.dart';
import '../../chatbot/data/chatbot_models.dart';
import '../../chatbot/presentation/chatbot_controller.dart';
import '../../chatbot/presentation/chatbot_history_panel.dart';
import 'teacher_shell.dart';
import 'teacher_style.dart';
import 'teacher_widgets.dart';

/// Teacher's Chatbot AI screen. Mirrors `StudentChatbotScreen` behavior
/// (same backend contract, reused `ChatbotController`) but wrapped in
/// `TeacherShell`/`TeacherStyle` to match the Teacher role's visual
/// language instead of the Student one.
class TeacherChatbotScreen extends ConsumerStatefulWidget {
  const TeacherChatbotScreen({super.key});

  @override
  ConsumerState<TeacherChatbotScreen> createState() =>
      _TeacherChatbotScreenState();
}

class _TeacherChatbotScreenState extends ConsumerState<TeacherChatbotScreen> {
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
    ref.listen(teacherChatbotControllerProvider, (_, next) {
      if (_stickToBottom) _scrollToBottom();
      if (!next.isSending && next.error == null) _messageController.clear();
    });

    final state = ref.watch(teacherChatbotControllerProvider);

    return TeacherShell(
      title: 'Chatbot AI',
      child: Column(
        children: [
          _ChatbotToolbar(
            onHistory: () => _openHistory(context),
            onNewSession: () => ref
                .read(teacherChatbotControllerProvider.notifier)
                .startNewSession(),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                const _IntroCard(),
                if (state.error != null) ...[
                  const SizedBox(height: EmiSpacing.md),
                  _ErrorCard(
                    onRetry: state.pendingMessage == null
                        ? null
                        : () => ref
                              .read(teacherChatbotControllerProvider.notifier)
                              .retry(),
                  ),
                ],
                const SizedBox(height: EmiSpacing.md),
                if (state.isLoadingHistory)
                  const Padding(
                    padding: EdgeInsets.only(bottom: EmiSpacing.md),
                    child: _LoadingHistoryBubble(),
                  ),
                if (state.messages.isEmpty && !state.isLoadingHistory)
                  const _EmptyChat(),
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
    ref
        .read(teacherChatbotControllerProvider.notifier)
        .send(_messageController.text);
  }

  void _openHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatbotHistoryPanel(
        provider: teacherChatbotControllerProvider,
        notifierRead: () =>
            ref.read(teacherChatbotControllerProvider.notifier),
        palette: const ChatbotPanelPalette(
          surface: TeacherStyle.surface,
          ink: TeacherStyle.ink,
          inkMuted: TeacherStyle.inkMuted,
          tint: TeacherStyle.tint,
          cardRadius: TeacherStyle.cardRadius,
        ),
      ),
    );
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

class _ChatbotToolbar extends StatelessWidget {
  const _ChatbotToolbar({required this.onHistory, required this.onNewSession});

  final VoidCallback onHistory;
  final VoidCallback onNewSession;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EmiSpacing.md,
        0,
        EmiSpacing.md,
        EmiSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            key: const Key('teacherChatbotHistoryButton'),
            onPressed: onHistory,
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Riwayat'),
          ),
          const SizedBox(width: EmiSpacing.sm),
          OutlinedButton.icon(
            key: const Key('teacherChatbotNewSessionButton'),
            onPressed: onNewSession,
            icon: const Icon(Icons.add_comment_outlined, size: 18),
            label: const Text('Sesi Baru'),
          ),
        ],
      ),
    );
  }
}

class _LoadingHistoryBubble extends StatelessWidget {
  const _LoadingHistoryBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Memuat percakapan...',
        style: TextStyle(color: TeacherStyle.inkMuted),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return TeacherListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TeacherStyle.tint,
                  borderRadius: BorderRadius.circular(EmiRadii.pill),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: EmiColors.primary,
                ),
              ),
              const SizedBox(width: EmiSpacing.md),
              Expanded(
                child: Text(
                  'Tanya materi Bahasa Mekongga',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: TeacherStyle.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: EmiSpacing.md),
          const Text(
            'EMI menjawab dari Basis AI yang dipublish admin dan menampilkan referensi jika cocok.',
            style: TextStyle(color: TeacherStyle.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return TeacherListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_outlined, color: TeacherStyle.ink),
              const SizedBox(width: EmiSpacing.sm),
              Expanded(
                child: Text(
                  'Jawaban Belum Tersedia',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: TeacherStyle.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: EmiSpacing.sm),
          const Text(
            'EMI belum bisa menjawab sekarang. Coba lagi sebentar.',
            style: TextStyle(color: TeacherStyle.inkMuted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: EmiSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onRetry,
                child: const Text('Coba Lagi'),
              ),
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
          'Halo, Guru! Kamu bisa bertanya tentang kosakata, budaya, atau materi Bahasa Mekongga.',
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
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: TeacherStyle.softShadow(opacity: 0.12),
        ),
        child: Text(content, style: const TextStyle(color: Colors.white)),
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
          color: TeacherStyle.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: TeacherStyle.softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayAnswer(content),
              style: const TextStyle(color: TeacherStyle.ink),
            ),
            if (response != null && response!.matched) ...[
              const SizedBox(height: EmiSpacing.sm),
              const TeacherStatusChip(label: 'Referensi tersedia'),
            ],
            if (source != null) ...[
              const SizedBox(height: EmiSpacing.sm),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'Sumber: ${source.title}',
                  style: const TextStyle(
                    color: TeacherStyle.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kategori: ${source.category ?? 'Umum'}',
                      style: const TextStyle(color: TeacherStyle.inkMuted),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Jenis sumber: ${_sourceTypeLabel(source.sourceType)}',
                      style: const TextStyle(color: TeacherStyle.inkMuted),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: EmiSpacing.md),
        padding: const EdgeInsets.all(EmiSpacing.md),
        decoration: BoxDecoration(
          color: TeacherStyle.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: TeacherStyle.softShadow(),
        ),
        child: const Text(
          'EMI sedang mencari jawaban...',
          style: TextStyle(color: TeacherStyle.inkMuted),
        ),
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(EmiSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: TeacherStyle.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: TeacherStyle.softShadow(),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !isSending,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(color: TeacherStyle.ink),
                  decoration: const InputDecoration(
                    hintText: 'Tanyakan materi, kosakata, atau budaya...',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: EmiSpacing.md,
                      vertical: EmiSpacing.sm,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: EmiSpacing.sm),
            SizedBox(
              width: 52,
              height: 52,
              child: FilledButton(
                onPressed: isSending ? null : onSend,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
