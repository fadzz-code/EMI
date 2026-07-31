import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/emi_theme.dart';
import '../data/chatbot_models.dart';
import 'chatbot_controller.dart';

/// Visual tokens the history panel needs from the host role's style
/// system. Passed in explicitly so this single widget can be reused by
/// both Student (`StudentStyle`) and Teacher (`TeacherStyle`) without
/// either role's screen depending on the other's style file.
class ChatbotPanelPalette {
  const ChatbotPanelPalette({
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.tint,
    required this.cardRadius,
  });

  final Color surface;
  final Color ink;
  final Color inkMuted;
  final Color tint;
  final double cardRadius;
}

/// Bottom-sheet panel listing a chatbot's saved conversations: open one to
/// continue it, start a fresh session, or delete a conversation. Mirrors
/// the web app's chatbot history sidebar
/// (`Emi-Frontend/src/features/student/student-chatbot.tsx`) so students
/// and teachers see the same conversation history on mobile as on web.
class ChatbotHistoryPanel extends ConsumerStatefulWidget {
  const ChatbotHistoryPanel({
    super.key,
    required this.provider,
    required this.notifierRead,
    this.palette = const ChatbotPanelPalette(
      surface: Colors.white,
      ink: EmiColors.textPrimary,
      inkMuted: EmiColors.textSecondary,
      tint: Color(0xFFF3F6FC),
      cardRadius: 18,
    ),
  });

  final ProviderListenable<ChatbotState> provider;
  final ChatbotController Function() notifierRead;
  final ChatbotPanelPalette palette;

  @override
  ConsumerState<ChatbotHistoryPanel> createState() =>
      _ChatbotHistoryPanelState();
}

class _ChatbotHistoryPanelState extends ConsumerState<ChatbotHistoryPanel> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final palette = widget.palette;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        margin: const EdgeInsets.all(EmiSpacing.md),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(palette.cardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EmiSpacing.md,
                EmiSpacing.md,
                EmiSpacing.sm,
                EmiSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Riwayat Percakapan',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: palette.ink),
                    ),
                  ),
                  IconButton(
                    key: const Key('chatbotHistoryCloseButton'),
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: palette.inkMuted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: state.isLoadingConversations && state.conversations.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(EmiSpacing.lg),
                      child: Text(
                        'Memuat riwayat...',
                        style: TextStyle(color: palette.inkMuted),
                      ),
                    )
                  : state.conversations.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(EmiSpacing.lg),
                      child: Text(
                        'Belum ada percakapan tersimpan.',
                        style: TextStyle(color: palette.inkMuted),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: EmiSpacing.sm,
                      ),
                      itemCount: state.conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = state.conversations[index];
                        final active =
                            conversation.id == state.activeConversationId;
                        return _ConversationTile(
                          conversation: conversation,
                          active: active,
                          palette: palette,
                          onTap: () {
                            widget.notifierRead().openConversation(
                              conversation.id,
                            );
                            Navigator.of(context).pop();
                          },
                          onDelete: () => widget
                              .notifierRead()
                              .deleteConversation(conversation.id),
                        );
                      },
                    ),
            ),
            const SizedBox(height: EmiSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.active,
    required this.palette,
    required this.onTap,
    required this.onDelete,
  });

  final ChatbotConversationSummary conversation;
  final bool active;
  final ChatbotPanelPalette palette;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: EmiSpacing.xs),
      decoration: BoxDecoration(
        color: active ? palette.tint : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        title: Text(
          conversation.title?.trim().isNotEmpty == true
              ? conversation.title!
              : 'Percakapan',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.ink,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _formatDate(conversation.lastMessageAt ?? conversation.createdAt),
          style: TextStyle(color: palette.inkMuted, fontSize: 12),
        ),
        trailing: IconButton(
          key: Key('chatbotDeleteConversation-${conversation.id}'),
          tooltip: 'Hapus percakapan',
          onPressed: () => _confirmDelete(context, onDelete),
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VoidCallback onConfirmed,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus percakapan ini?'),
        content: const Text(
          'Riwayat percakapan ini akan dihapus secara permanen dan tidak dapat dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirmed();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}
