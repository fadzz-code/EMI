import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../data/speaking_models.dart';
import '../data/speaking_providers.dart';

class StudentSpeakingListScreen extends ConsumerStatefulWidget {
  const StudentSpeakingListScreen({super.key});

  @override
  ConsumerState<StudentSpeakingListScreen> createState() =>
      _StudentSpeakingListScreenState();
}

class _StudentSpeakingListScreenState
    extends ConsumerState<StudentSpeakingListScreen> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(speakingExercisesProvider);
    final attempts = ref.watch(speakingAttemptsProvider(_page));

    return EmiScaffold(
      title: 'Speaking',
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(speakingExercisesProvider.future),
            ref.refresh(speakingAttemptsProvider(_page).future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorCard(
                message: error.toString(),
                onRetry: () => ref.invalidate(speakingExercisesProvider),
              ),
              data: (items) => _ExerciseList(items: items),
            ),
            const SizedBox(height: EmiSpacing.lg),
            Text(
              'Riwayat Attempt',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: EmiSpacing.sm),
            attempts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorCard(
                message: error.toString(),
                onRetry: () => ref.invalidate(speakingAttemptsProvider(_page)),
              ),
              data: (page) => Column(
                children: [
                  _AttemptList(
                    items: page.items,
                    onOpen: (attemptId) => _showAttempt(context, attemptId),
                  ),
                  if (page.lastPage > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: page.currentPage > 1
                              ? () => setState(() => _page--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('${page.currentPage}/${page.lastPage}'),
                        IconButton(
                          onPressed: page.currentPage < page.lastPage
                              ? () => setState(() => _page++)
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
    );
  }

  Future<void> _showAttempt(BuildContext context, String attemptId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(EmiSpacing.md),
            child: ref
                .watch(speakingAttemptProvider(attemptId))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorCard(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(speakingAttemptProvider(attemptId)),
                  ),
                  data: (attempt) => _AttemptDetail(attempt: attempt),
                ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.items});

  final List<SpeakingExercise> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmiCard(child: Text('Belum ada latihan speaking.'));
    }
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: EmiSpacing.md),
              child: InkWell(
                onTap: () => context.push('/student/speaking/${item.id}'),
                child: EmiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: EmiSpacing.sm),
                      Text(
                        item.promptText ??
                            item.targetText ??
                            'Buka untuk detail latihan.',
                      ),
                      const SizedBox(height: EmiSpacing.sm),
                      Wrap(
                        spacing: EmiSpacing.sm,
                        children: [
                          _Chip(item.difficulty ?? 'Speaking'),
                          if (item.hasReferenceAudio) const _Chip('Suara Asli'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AttemptList extends StatelessWidget {
  const _AttemptList({required this.items, required this.onOpen});

  final List<SpeakingAttempt> items;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmiCard(child: Text('Belum ada riwayat.'));
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
          child: InkWell(
            onTap: () => onOpen(item.id),
            child: EmiCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.exercise?.title ??
                              item.targetText ??
                              'Attempt speaking',
                        ),
                        Text('Status: ${item.status}'),
                      ],
                    ),
                  ),
                  if (item.aiScore != null) Text('${item.aiScore}'),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AttemptDetail extends StatelessWidget {
  const _AttemptDetail({required this.attempt});

  final SpeakingAttempt attempt;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Hasil Speaking', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: EmiSpacing.md),
          Text(
            attempt.exercise?.title ?? attempt.targetText ?? 'Attempt speaking',
          ),
          Text('Status: ${attempt.status}'),
          if (attempt.isProcessing)
            const Text('Analisis masih berjalan. Tarik untuk refresh nanti.'),
          if (attempt.aiScore != null) Text('Skor AI: ${attempt.aiScore}'),
          if (attempt.aiTranscription != null)
            Text('Transkripsi: ${attempt.aiTranscription}'),
          if (attempt.aiAlignment != null)
            Text('Detail analisis: ${attempt.aiAlignment}'),
          if (attempt.aiError != null) Text('Error AI: ${attempt.aiError}'),
          if (attempt.teacherScore != null)
            Text('Nilai guru: ${attempt.teacherScore}'),
          if (attempt.teacherFeedback != null)
            Text('Feedback guru: ${attempt.teacherFeedback}'),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), backgroundColor: EmiColors.secondary);
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: EmiSpacing.sm),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
