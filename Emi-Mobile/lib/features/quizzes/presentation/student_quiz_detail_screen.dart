import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
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
            EmiCard(
              child: Column(
                children: [
                  Text(error.toString()),
                  const SizedBox(height: EmiSpacing.md),
                  ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(studentQuizDetailProvider(quizId)),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (item) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(studentQuizDetailProvider(quizId).future),
          child: ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              EmiCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(EmiSpacing.md),
                      decoration: const BoxDecoration(
                        color: EmiColors.secondary,
                        border: Border(
                          bottom: BorderSide(color: EmiColors.border, width: 2),
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusPill(quiz: item),
                          const SizedBox(height: EmiSpacing.md),
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.headlineMedium,
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
                              item.description!.trim().isNotEmpty)
                            Text(item.description!),
                          const SizedBox(height: EmiSpacing.lg),
                          _InfoGrid(quiz: item),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.lg),
              EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instruksi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: EmiSpacing.sm),
                    Text(
                      (item.instructions?.trim().isNotEmpty ?? false)
                          ? item.instructions!
                          : 'Belum ada instruksi khusus.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.lg),
              EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Percobaan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: EmiSpacing.sm),
                    history.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text(error.toString()),
                      data: (page) => Column(
                        children: [
                          ...page.items.map(
                            (attempt) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Percobaan ${attempt.attemptNumber}'),
                              subtitle: Text(attempt.status),
                              trailing: Text(
                                attempt.scorePercent == null
                                    ? '-'
                                    : '${attempt.scorePercent!.round()}%',
                              ),
                              onTap: () => context.push(
                                '/student/quizzes/${widget.quizId}/attempt?attemptId=${attempt.id}',
                              ),
                            ),
                          ),
                          if (page.items.isEmpty)
                            const Text('Belum ada riwayat percobaan.'),
                          if (page.lastPage > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: page.currentPage > 1
                                      ? () => setState(() => _historyPage--)
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('${page.currentPage}/${page.lastPage}'),
                                IconButton(
                                  onPressed: page.currentPage < page.lastPage
                                      ? () => setState(() => _historyPage++)
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.lg),
              ElevatedButton.icon(
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
              const SizedBox(height: EmiSpacing.md),
              OutlinedButton.icon(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/student/quizzes'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
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
        color: EmiColors.backgroundWarm,
        border: Border.all(color: EmiColors.border, width: 2),
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
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
        color: quiz.availability == QuizAvailability.finished
            ? EmiColors.success
            : EmiColors.primary,
        border: Border.all(color: EmiColors.border, width: 2),
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: Text(
        quiz.statusLabel,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

String _shortDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
