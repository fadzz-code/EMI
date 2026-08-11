import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../data/speaking_models.dart';
import '../data/speaking_providers.dart';

class StudentSpeakingListScreen extends ConsumerStatefulWidget {
  const StudentSpeakingListScreen({super.key, this.resultsOnly = false});

  final bool resultsOnly;

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
            StudentPageHeader(
              icon: Icons.mic_none_outlined,
              title: widget.resultsOnly ? 'Hasil Speaking' : 'Latihan Speaking',
              subtitle: widget.resultsOnly
                  ? 'Lihat hasil dan riwayat latihanmu.'
                  : 'Latih pengucapanmu dan lihat hasilnya.',
            ),
            if (!widget.resultsOnly) ...[
              const SizedBox(height: EmiSpacing.md),
              exercises.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorCard(
                  onRetry: () => ref.invalidate(speakingExercisesProvider),
                ),
                data: (items) => _ExerciseList(items: items),
              ),
              const StudentSectionHeader(
                'Riwayat Latihan',
                icon: Icons.history,
              ),
            ],
            attempts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorCard(
                onRetry: () => ref.invalidate(speakingAttemptsProvider(_page)),
              ),
              data: (page) => Column(
                children: [
                  if (widget.resultsOnly && page.items.isNotEmpty) ...[
                    _LatestResultHero(
                      attempt: page.items.first,
                      onOpen: () => _showAttempt(context, page.items.first.id),
                      onTrainAgain: page.items.first.exerciseId.isEmpty
                          ? null
                          : () => context.push(
                              '/student/speaking/${page.items.first.exerciseId}',
                            ),
                    ),
                    const StudentSectionHeader(
                      'Riwayat Hasil',
                      icon: Icons.history,
                    ),
                  ],
                  _AttemptList(
                    items: widget.resultsOnly && page.items.isNotEmpty
                        ? page.items.skip(1).toList()
                        : page.items,
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

class _LatestResultHero extends StatelessWidget {
  const _LatestResultHero({
    required this.attempt,
    required this.onOpen,
    required this.onTrainAgain,
  });

  final SpeakingAttempt attempt;
  final VoidCallback onOpen;
  final VoidCallback? onTrainAgain;

  @override
  Widget build(BuildContext context) {
    final score = attempt.teacherScore ?? attempt.aiScore;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: EmiSpacing.md),
      padding: const EdgeInsets.all(EmiSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [StudentStyle.heroTintStart, StudentStyle.heroTintEnd],
        ),
        borderRadius: BorderRadius.circular(StudentStyle.heroRadius),
        boxShadow: StudentStyle.heroShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Terbaru',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: EmiSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score?.round().toString() ?? '—',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 7, left: 3),
                child: Text('/100', style: TextStyle(color: Colors.white70)),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  attempt.scoreLevel,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            attempt.friendlyStatus,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: EmiSpacing.md),
          Wrap(
            spacing: EmiSpacing.sm,
            runSpacing: EmiSpacing.sm,
            children: [
              FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: EmiColors.primary,
                ),
                child: const Text('Lihat Detail'),
              ),
              OutlinedButton.icon(
                onPressed: onTrainAgain,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
                icon: const Icon(Icons.replay),
                label: const Text('Latihan Lagi'),
              ),
            ],
          ),
        ],
      ),
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

class _AttemptDetail extends ConsumerStatefulWidget {
  const _AttemptDetail({required this.attempt});

  final SpeakingAttempt attempt;

  @override
  ConsumerState<_AttemptDetail> createState() => _AttemptDetailState();
}

class _AttemptDetailState extends ConsumerState<_AttemptDetail> {
  final _player = AudioPlayer();
  var _loading = false;
  String? _audioError;

  SpeakingAttempt get attempt => widget.attempt;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

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
                _row(context, 'Status', attempt.friendlyStatus),
                if (attempt.aiScore != null || attempt.teacherScore != null)
                  _row(
                    context,
                    'Pencapaian',
                    '${(attempt.teacherScore ?? attempt.aiScore)!.round()}/100 · ${attempt.scoreLevel}',
                  ),
                if (attempt.targetText != null ||
                    attempt.exercise?.targetText != null)
                  _row(
                    context,
                    'Kalimat target',
                    attempt.targetText ?? attempt.exercise!.targetText!,
                  ),
                if (attempt.aiTranscription != null)
                  _row(context, 'Yang terdengar', attempt.aiTranscription!),
                if (attempt.isProcessing)
                  _row(
                    context,
                    'Analisis',
                    'Masih berjalan. Tarik untuk refresh nanti.',
                  ),
                if (attempt.aiAlignment != null)
                  _row(
                    context,
                    'Detail pengucapan',
                    _alignmentSummary(attempt.aiAlignment!),
                  ),
                if (attempt.aiError != null)
                  _row(context, 'Error AI', attempt.aiError!),
                if (attempt.teacherScore != null)
                  _row(context, 'Nilai guru', '${attempt.teacherScore}'),
                if (attempt.teacherFeedback != null)
                  _row(context, 'Feedback guru', attempt.teacherFeedback!),
                if (attempt.audioUrl != null || attempt.audioMediaId != null)
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing == true;
                      return Row(
                        children: [
                          IconButton.filled(
                            onPressed: _loading ? null : () => _toggle(playing),
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    playing ? Icons.pause : Icons.play_arrow,
                                  ),
                          ),
                          const SizedBox(width: EmiSpacing.sm),
                          Expanded(
                            child: Text(
                              _audioError ?? 'Rekaman siswa',
                              style: TextStyle(
                                color: _audioError == null
                                    ? StudentStyle.ink
                                    : EmiColors.error,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _alignmentSummary(Object alignment) {
    if (alignment is! Map || alignment['operations'] is! List) {
      return 'Analisis tersedia. Dengarkan lagi lalu bandingkan pengucapanmu.';
    }
    final operations = (alignment['operations'] as List).whereType<Map>();
    final tips = operations.where((item) => item['type'] != 'match').map((
      item,
    ) {
      final target = item['target']?.toString() ?? 'kata ini';
      return item['type'] == 'deletion'
          ? 'Ucapkan “$target” lebih lengkap.'
          : 'Latih “$target” dengan lebih jelas.';
    }).toList();
    return tips.isEmpty
        ? 'Semua kata utama terdengar tepat. Pertahankan ritme dan intonasimu.'
        : tips.take(3).join(' ');
  }

  Future<void> _toggle(bool playing) async {
    setState(() {
      _loading = true;
      _audioError = null;
    });
    try {
      if (playing) {
        await _player.pause();
      } else {
        if (_player.audioSource == null) {
          final directUrl = attempt.audioUrl;
          final url = directUrl != null && directUrl.isNotEmpty
              ? directUrl
              : await ref
                    .read(speakingRepositoryProvider)
                    .temporaryMediaUrl(attempt.audioMediaId!);
          await _player.setUrl(url);
        }
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _audioError = 'Audio gagal diputar. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
