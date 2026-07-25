import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
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
            const StudentPageHeader(
              icon: Icons.mic_none_outlined,
              title: 'Latihan Speaking',
              subtitle: 'Latih pengucapanmu dan lihat hasilnya.',
            ),
            const SizedBox(height: EmiSpacing.md),
            exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorCard(
                onRetry: () => ref.invalidate(speakingExercisesProvider),
              ),
              data: (items) => _ExerciseList(items: items),
            ),
            const StudentSectionHeader('Riwayat Latihan', icon: Icons.history),
            attempts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorCard(
                onRetry: () => ref.invalidate(speakingAttemptsProvider(_page)),
              ),
              data: (page) => Column(
                children: [
                  _AttemptList(
                    items: page.items,
                    onOpen: (attemptId) => _showAttempt(context, attemptId),
                  ),
                  if (page.lastPage > 1) ...[
                    const SizedBox(height: EmiSpacing.sm),
                    StudentPaginationBar(
                      currentPage: page.currentPage,
                      lastPage: page.lastPage,
                      onPrevious: page.currentPage > 1
                          ? () => setState(() => _page--)
                          : null,
                      onNext: page.currentPage < page.lastPage
                          ? () => setState(() => _page++)
                          : null,
                    ),
                  ],
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
      backgroundColor: StudentStyle.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
      return StudentPlaceholder(
        icon: Icons.mic_none_outlined,
        title: 'Belum Ada Latihan',
        message: 'Latihan speaking untuk kelasmu belum tersedia.',
      );
    }
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: EmiSpacing.md),
              child: StudentCard(
                onTap: () => context.push('/student/speaking/${item.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: StudentStyle.tint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.record_voice_over_outlined,
                            color: EmiColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: EmiSpacing.sm),
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: StudentStyle.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: EmiSpacing.sm),
                    Text(
                      item.promptText ??
                          item.targetText ??
                          'Buka untuk detail latihan.',
                      style: const TextStyle(color: StudentStyle.inkMuted),
                    ),
                    const SizedBox(height: EmiSpacing.sm),
                    Wrap(
                      spacing: EmiSpacing.sm,
                      runSpacing: EmiSpacing.sm,
                      children: [
                        StudentStatusChip(label: item.difficulty ?? 'Speaking'),
                        if (item.hasReferenceAudio)
                          const StudentStatusChip(label: 'Suara Asli'),
                      ],
                    ),
                  ],
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
    if (items.isEmpty) {
      return StudentPlaceholder(
        icon: Icons.history,
        title: 'Belum Ada Riwayat',
        message: 'Hasil latihanmu akan muncul di sini.',
      );
    }
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
          child: StudentCard(
            onTap: () => onOpen(item.id),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.exercise?.title ??
                            item.targetText ??
                            'Latihan speaking',
                        style: const TextStyle(color: StudentStyle.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Status: ${item.status}',
                        style: const TextStyle(color: StudentStyle.inkMuted),
                      ),
                    ],
                  ),
                ),
                if (item.aiScore != null)
                  StudentStatusChip(label: '${item.aiScore}', status: 'done'),
              ],
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: EmiSpacing.md),
              decoration: BoxDecoration(
                color: StudentStyle.tintStrong,
                borderRadius: BorderRadius.circular(EmiRadii.pill),
              ),
            ),
          ),
          Text(
            'Hasil Speaking',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: StudentStyle.ink),
          ),
          const SizedBox(height: EmiSpacing.md),
          StudentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(
                  context,
                  'Latihan',
                  attempt.exercise?.title ??
                      attempt.targetText ??
                      'Latihan speaking',
                ),
                _row(context, 'Status', attempt.status),
                if (attempt.isProcessing)
                  _row(
                    context,
                    'Analisis',
                    'Masih berjalan. Tarik untuk refresh nanti.',
                  ),
                if (attempt.aiScore != null)
                  _row(context, 'Skor AI', '${attempt.aiScore}'),
                if (attempt.aiTranscription != null)
                  _row(context, 'Transkripsi', attempt.aiTranscription!),
                if (attempt.aiAlignment != null)
                  _row(context, 'Detail analisis', '${attempt.aiAlignment}'),
                if (attempt.aiError != null)
                  _row(context, 'Error AI', attempt.aiError!),
                if (attempt.teacherScore != null)
                  _row(context, 'Nilai guru', '${attempt.teacherScore}'),
                if (attempt.teacherFeedback != null)
                  _row(context, 'Feedback guru', attempt.teacherFeedback!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: StudentStyle.inkMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(value, style: const TextStyle(color: StudentStyle.ink)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return StudentPlaceholder(
      icon: Icons.cloud_off_outlined,
      title: 'Belum Bisa Dimuat',
      message: 'Periksa koneksi internetmu, lalu coba lagi.',
      onRetry: onRetry,
    );
  }
}
