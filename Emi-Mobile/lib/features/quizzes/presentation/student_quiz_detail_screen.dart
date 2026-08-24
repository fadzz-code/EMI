import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../data/student_quiz.dart';
import '../data/student_quiz_providers.dart';

class StudentQuizDetailScreen extends ConsumerStatefulWidget {
  const StudentQuizDetailScreen({super.key, required this.quizId});

  final String quizId;

  @override
  ConsumerState<StudentQuizDetailScreen> createState() =>
      _StudentQuizDetailScreenState();
}

class _StudentQuizDetailScreenState
    extends ConsumerState<StudentQuizDetailScreen> {
  int _historyPage = 1;

  @override
  Widget build(BuildContext context) {
    final quizId = widget.quizId;
    final quiz = ref.watch(studentQuizDetailProvider(quizId));
    final history = ref.watch(
      studentQuizAttemptsProvider((quizId: quizId, page: _historyPage)),
    );

    return EmiScaffold(
      title: 'Detail Kuis',
      child: quiz.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            StudentPlaceholder(
              icon: Icons.cloud_off_outlined,
              title: 'Kuis Belum Bisa Dimuat',
              message: 'Periksa koneksi internetmu, lalu coba lagi.',
              onRetry: () => ref.invalidate(studentQuizDetailProvider(quizId)),
            ),
          ],
        ),
        data: (item) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(studentQuizDetailProvider(quizId).future),
          child: ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              StudentCard(
                padding: EdgeInsets.zero,
                clip: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(EmiSpacing.md),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFB877), Color(0xFFFF8A3D)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusPill(quiz: item),
                          const SizedBox(height: EmiSpacing.md),
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(EmiSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.description != null &&
                              item.description!.trim().isNotEmpty) ...[
                            Text(
                              item.description!,
                              style: const TextStyle(
                                color: StudentStyle.inkMuted,
                              ),
                            ),
                            const SizedBox(height: EmiSpacing.md),
                          ],
                          _InfoGrid(quiz: item),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const StudentSectionHeader('Instruksi', icon: Icons.info_outline),
              StudentCard(
                child: Text(
                  (item.instructions?.trim().isNotEmpty ?? false)
                      ? item.instructions!
                      : 'Belum ada instruksi khusus.',
                  style: const TextStyle(color: StudentStyle.ink),
                ),
              ),
              const StudentSectionHeader(
                'Riwayat Percobaan',
                icon: Icons.history,
              ),
              StudentCard(
                child: history.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => const Text(
                    'Riwayat belum bisa dimuat.',
                    style: TextStyle(color: StudentStyle.inkMuted),
                  ),
                  data: (page) => Column(
                    children: [
                      ...page.items.map(
                        (attempt) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Percobaan ${attempt.attemptNumber}',
                            style: const TextStyle(color: StudentStyle.ink),
                          ),
                          subtitle: Text(
                            attempt.status,
                            style: const TextStyle(
                              color: StudentStyle.inkMuted,
                            ),
                          ),
                          trailing: Text(
                            attempt.scorePercent == null
                                ? '-'
                                : '${attempt.scorePercent!.round()}%',
                            style: const TextStyle(
                              color: EmiColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onTap: () => context.push(
                            '/student/quizzes/${widget.quizId}/attempt?attemptId=${attempt.id}',
                          ),
                        ),
                      ),
                      if (page.items.isEmpty)
                        const Text(
                          'Belum ada riwayat percobaan.',
                          style: TextStyle(color: StudentStyle.inkMuted),
                        ),
                      if (page.lastPage > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: page.currentPage > 1
                                  ? () => setState(() => _historyPage--)
                                  : null,
                              icon: const Icon(
                                Icons.chevron_left,
                                color: StudentStyle.ink,
                              ),
                            ),
                            Text('${page.currentPage}/${page.lastPage}'),
                            IconButton(
                              onPressed: page.currentPage < page.lastPage
                                  ? () => setState(() => _historyPage++)
                                  : null,
                              icon: const Icon(
                                Icons.chevron_right,
                                color: StudentStyle.ink,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: EmiSpacing.lg),
              if (!item.canStart && item.cannotStartReason != null) ...[
                Text(
                  item.cannotStartReason!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: EmiSpacing.sm),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: item.canStart
                      ? () {
                          final activeAttemptId = item.activeAttempt?.id;
                          context.go(
                            '/student/quizzes/${item.id}/attempt${activeAttemptId == null || activeAttemptId.isEmpty ? '' : '?attemptId=$activeAttemptId'}',
                          );
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    item.canStart
                        ? item.hasActiveAttempt
                              ? 'Lanjutkan kuis'
                              : 'Mulai kuis'
                        : 'Kuis belum dapat dimulai',
                  ),
                ),
              ),
              const SizedBox(height: EmiSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/student/quizzes'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.quiz});

  final StudentQuiz quiz;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: EmiSpacing.sm,
      runSpacing: EmiSpacing.sm,
      children: [
        _InfoTile(label: 'Soal', value: '${quiz.questionsCount}'),
        if (quiz.durationMinutes != null)
          _InfoTile(label: 'Durasi', value: '${quiz.durationMinutes} menit'),
        if (quiz.maxAttempts != null)
          _InfoTile(
            label: 'Attempt',
            value: '${quiz.usedAttempts ?? 0}/${quiz.maxAttempts}',
          ),
        if (quiz.bestScorePercent != null)
          _InfoTile(
            label: 'Nilai terbaik',
            value: '${quiz.bestScorePercent!.round()}%',
          ),
        if (quiz.openAt != null)
          _InfoTile(label: 'Buka', value: _shortDate(quiz.openAt!)),
        if (quiz.closeAt != null)
          _InfoTile(label: 'Tutup', value: _shortDate(quiz.closeAt!)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(EmiSpacing.sm),
      decoration: BoxDecoration(
        color: StudentStyle.tint,
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: StudentStyle.inkMuted, fontSize: 12),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.quiz});

  final StudentQuiz quiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: Text(
        quiz.statusLabel,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _shortDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
