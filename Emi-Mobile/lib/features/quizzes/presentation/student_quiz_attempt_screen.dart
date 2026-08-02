import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../../dashboard/data/student_dashboard_providers.dart';
import '../../progress/data/student_progress_providers.dart';
import '../data/student_quiz.dart';
import '../data/student_quiz_providers.dart';

class QuizSubmissionCoordinator {
  QuizSubmissionCoordinator({
    required this.save,
    required this.submit,
    required this.onSuccess,
    required this.onError,
  });

  final Future<bool> Function() save;
  final Future<QuizAttempt> Function() submit;
  final void Function(QuizAttempt) onSuccess;
  final void Function(Object) onError;
  Future<void>? _operation;
  bool _disposed = false;
  bool _submitted = false;

  Future<void> run() {
    if (_submitted || _disposed) return Future.value();
    return _operation ??= _run();
  }

  Future<void> _run() async {
    try {
      if (!await save() || _disposed) return;
      final result = await submit();
      _submitted = true;
      if (!_disposed) onSuccess(result);
    } catch (error) {
      if (!_disposed) onError(error);
    } finally {
      _operation = null;
    }
  }

  void dispose() => _disposed = true;
}

class StudentQuizAttemptScreen extends ConsumerStatefulWidget {
  const StudentQuizAttemptScreen({
    super.key,
    required this.quizId,
    this.attemptId,
  });

  final String quizId;
  final String? attemptId;

  @override
  ConsumerState<StudentQuizAttemptScreen> createState() =>
      _StudentQuizAttemptScreenState();
}

class _StudentQuizAttemptScreenState
    extends ConsumerState<StudentQuizAttemptScreen> {
  QuizAttempt? _attempt;
  int _index = 0;
  bool _loading = true;
  bool _saving = false;
  bool _submitting = false;
  bool _confirmingSubmit = false;
  bool _allowPop = false;
  String? _submitKey;
  Object? _error;
  final _selectedOptions = <String, String>{};
  final _textAnswers = <String, TextEditingController>{};
  Timer? _timer;
  Duration? _remaining;
  late final QuizSubmissionCoordinator _submission;

  List<QuizQuestion> get _questions => _attempt?.quiz?.questions ?? const [];
  QuizQuestion? get _question => _questions.isEmpty
      ? null
      : _questions[_index.clamp(0, _questions.length - 1)];

  @override
  void initState() {
    super.initState();
    _submission = QuizSubmissionCoordinator(
      save: _saveCurrent,
      submit: _submitAttempt,
      onSuccess: _submissionSucceeded,
      onError: _submissionFailed,
    );
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _submission.dispose();
    for (final controller in _textAnswers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || _attempt == null || _attempt!.isFinished,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _attempt == null || _attempt!.isFinished) return;
        final leave = await _confirmLeave();
        if (!leave) return;
        final saved = await _saveCurrent();
        if (!saved || !context.mounted) return;
        setState(() => _allowPop = true);
        context.pop();
      },
      child: Scaffold(
        backgroundColor: StudentStyle.pageBackground,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _ErrorState(error: _error!, onRetry: _start)
              : _attempt!.isFinished
              ? _ResultView(
                  attempt: _attempt!,
                  onDone: () => context.go('/student/quizzes/${widget.quizId}'),
                )
              : _AttemptView(
                  attempt: _attempt!,
                  question: _question,
                  index: _index,
                  total: _questions.length,
                  selectedOptionId: _question == null
                      ? null
                      : _selectedOptions[_question!.id],
                  textController: _question == null
                      ? null
                      : _controllerFor(_question!.id),
                  remaining: _remaining,
                  saving: _saving,
                  submitting: _submitting,
                  onSelect: (optionId) => setState(
                    () => _selectedOptions[_question!.id] = optionId,
                  ),
                  onPrevious: _index == 0 ? null : () => _move(-1),
                  onNext: _index >= _questions.length - 1
                      ? null
                      : () => _move(1),
                  onSubmit: _submit,
                ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = ref.read(studentQuizRepositoryProvider);
      final attempt = widget.attemptId == null
          ? await repository.startAttempt(widget.quizId)
          : await repository.attempt(widget.attemptId!);
      if (!mounted) return;
      _hydrate(attempt);
      setState(() {
        _attempt = attempt;
        _loading = false;
      });
      _startTimer(attempt);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _hydrate(QuizAttempt attempt) {
    for (final answer in attempt.answers) {
      if (answer.selectedOptionId != null) {
        _selectedOptions[answer.questionId] = answer.selectedOptionId!;
      }
      if (answer.answerText != null) {
        _controllerFor(answer.questionId).text = answer.answerText!;
      }
    }
  }

  TextEditingController _controllerFor(String questionId) {
    return _textAnswers.putIfAbsent(questionId, TextEditingController.new);
  }

  Future<void> _move(int delta) async {
    final saved = await _saveCurrent();
    if (!saved) return;
    setState(() => _index += delta);
  }

  Future<bool> _saveCurrent() async {
    final attempt = _attempt;
    final question = _question;
    if (attempt == null || question == null) return false;
    final selectedOptionId = _selectedOptions[question.id];
    final text = _textAnswers[question.id]?.text.trim();
    if (question.isMultipleChoice && selectedOptionId == null) return true;
    if (!question.isMultipleChoice && (text == null || text.isEmpty)) {
      return true;
    }

    setState(() => _saving = true);
    try {
      final answer = await ref
          .read(studentQuizRepositoryProvider)
          .saveAnswer(
            attemptId: attempt.id,
            questionId: question.id,
            selectedOptionId: question.isMultipleChoice
                ? selectedOptionId
                : null,
            answerText: question.isMultipleChoice ? null : text,
          );
      _mergeAnswer(answer);
      setState(() => _saving = false);
      return true;
    } catch (error) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return false;
    }
  }

  void _mergeAnswer(QuizAnswer answer) {
    final attempt = _attempt;
    if (attempt == null) return;
    final answers = [
      ...attempt.answers.where((item) => item.questionId != answer.questionId),
      answer,
    ];
    _attempt = QuizAttempt(
      id: attempt.id,
      quizId: attempt.quizId,
      attemptNumber: attempt.attemptNumber,
      status: attempt.status,
      startedAt: attempt.startedAt,
      expiresAt: attempt.expiresAt,
      submittedAt: attempt.submittedAt,
      scorePoints: attempt.scorePoints,
      maxPoints: attempt.maxPoints,
      scorePercent: attempt.scorePercent,
      correctCount: attempt.correctCount,
      incorrectCount: attempt.incorrectCount,
      unansweredCount: attempt.unansweredCount,
      quiz: attempt.quiz,
      answers: answers,
    );
  }

  Future<void> _submit() async {
    if (_submitting || _confirmingSubmit) return;
    setState(() => _confirmingSubmit = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kumpulkan kuis?'),
        content: const Text(
          'Jawaban yang sudah dikumpulkan tidak bisa diubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            child: const Text('Kumpulkan'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirmingSubmit = false);
    if (confirmed == true) await _submitPipeline();
  }

  Future<void> _submitPipeline() async {
    if (_attempt == null) return;
    if (!_submitting && mounted) setState(() => _submitting = true);
    await _submission.run();
    if (mounted && _attempt?.isFinished != true) {
      setState(() => _submitting = false);
    }
  }

  Future<QuizAttempt> _submitAttempt() {
    final attemptId = _attempt!.id;
    _submitKey ??= _idempotencyKey(attemptId);
    return ref
        .read(studentQuizRepositoryProvider)
        .submitAttempt(attemptId: attemptId, idempotencyKey: _submitKey!);
  }

  void _submissionSucceeded(QuizAttempt result) {
    _timer?.cancel();
    setState(() {
      _attempt = result;
      _submitting = false;
    });
    ref.invalidate(studentQuizDetailProvider(widget.quizId));
    ref.invalidate(studentQuizListProvider);
    ref.invalidate(studentQuizAttemptsProvider);
    ref.invalidate(studentDashboardSummaryProvider);
    ref.invalidate(studentProgressReportProvider);
    context.go(
      '/student/quizzes/${widget.quizId}/result?attemptId=${result.id}',
    );
  }

  void _submissionFailed(Object error) {
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kuis belum terkirim. Coba lagi.')),
    );
  }

  void _startTimer(QuizAttempt attempt) {
    _timer?.cancel();
    if (attempt.expiresAt == null || !attempt.isInProgress) return;
    void tick() {
      if (!mounted) return;
      final remaining = attempt.expiresAt!.difference(DateTime.now());
      final bounded = remaining.isNegative ? Duration.zero : remaining;
      setState(() => _remaining = bounded);
      if (bounded == Duration.zero) {
        _timer?.cancel();
        _submitPipeline();
      }
    }

    tick();
    if (_remaining != Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  Future<bool> _confirmLeave() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar dari kuis?'),
            content: const Text(
              'Jawaban pada soal ini akan disimpan sebelum keluar.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('Tetap di sini'),
              ),
              ElevatedButton(
                onPressed: () => context.pop(true),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _AttemptView extends StatelessWidget {
  const _AttemptView({
    required this.attempt,
    required this.question,
    required this.index,
    required this.total,
    required this.selectedOptionId,
    required this.textController,
    required this.remaining,
    required this.saving,
    required this.submitting,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final QuizAttempt attempt;
  final QuizQuestion? question;
  final int index;
  final int total;
  final String? selectedOptionId;
  final TextEditingController? textController;
  final Duration? remaining;
  final bool saving;
  final bool submitting;
  final ValueChanged<String> onSelect;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (question == null) {
      return const Center(child: Text('Soal kuis tidak tersedia.'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            EmiSpacing.md,
            EmiSpacing.md,
            EmiSpacing.md,
            EmiSpacing.sm,
          ),
          child: Container(
            padding: const EdgeInsets.all(EmiSpacing.md),
            decoration: BoxDecoration(
              color: StudentStyle.surface,
              borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
              boxShadow: StudentStyle.softShadow(),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Soal ${index + 1}/$total',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StudentStyle.ink,
                        ),
                      ),
                    ),
                    if (remaining != null) _TimerPill(remaining: remaining!),
                  ],
                ),
                const SizedBox(height: EmiSpacing.sm),
                StudentProgressBar(value: total == 0 ? 0 : (index + 1) / total),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EmiSpacing.md),
                decoration: BoxDecoration(
                  color: StudentStyle.surface,
                  borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
                  boxShadow: StudentStyle.softShadow(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question!.questionText,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: StudentStyle.ink),
                    ),
                    const SizedBox(height: EmiSpacing.sm),
                    StudentStatusChip(label: '${question!.points.g} poin'),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              if (question!.isMultipleChoice)
                ...question!.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
                    child: _OptionTile(
                      text: option.optionText,
                      selected: selectedOptionId == option.id,
                      onTap: () => onSelect(option.id),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: StudentStyle.surface,
                    borderRadius: BorderRadius.circular(
                      StudentStyle.cardRadius,
                    ),
                    boxShadow: StudentStyle.softShadow(),
                  ),
                  child: TextField(
                    controller: textController,
                    minLines: 4,
                    maxLines: 6,
                    style: const TextStyle(color: StudentStyle.ink),
                    decoration: const InputDecoration(
                      hintText: 'Tulis jawaban...',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.all(EmiSpacing.md),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(EmiSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving || submitting ? null : onPrevious,
                  child: const Text('Sebelumnya'),
                ),
              ),
              const SizedBox(width: EmiSpacing.sm),
              if (onNext != null)
                Expanded(
                  child: FilledButton(
                    onPressed: saving || submitting ? null : onNext,
                    child: Text(saving ? 'Menyimpan...' : 'Berikutnya'),
                  ),
                )
              else
                Expanded(
                  child: FilledButton(
                    onPressed: saving || submitting ? null : onSubmit,
                    child: Text(submitting ? 'Mengirim...' : 'Kumpulkan'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(EmiSpacing.md),
          decoration: BoxDecoration(
            color: selected ? EmiColors.primarySoft : StudentStyle.surface,
            borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
            boxShadow: StudentStyle.softShadow(),
            border: selected
                ? Border.all(color: EmiColors.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? EmiColors.primary : StudentStyle.inkMuted,
                size: 22,
              ),
              const SizedBox(width: EmiSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: StudentStyle.ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.attempt, required this.onDone});

  final QuizAttempt attempt;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        const StudentPageHeader(
          icon: Icons.emoji_events_outlined,
          title: 'Hasil Kuis',
          subtitle: 'Kerja bagus! Ini ringkasan hasilmu.',
        ),
        const SizedBox(height: EmiSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(EmiSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFB877), Color(0xFFFF8A3D)],
            ),
            borderRadius: BorderRadius.circular(StudentStyle.heroRadius),
            boxShadow: StudentStyle.heroShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: ${attempt.status}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              if (attempt.scorePercent != null) ...[
                const SizedBox(height: EmiSpacing.sm),
                Text(
                  '${attempt.scorePercent!.round()}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 40,
                  ),
                ),
              ],
              if (attempt.scorePoints != null && attempt.maxPoints != null)
                Text(
                  '${attempt.scorePoints!.g}/${attempt.maxPoints!.g} poin',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92)),
                ),
              if (attempt.scorePercent == null)
                Text(
                  'Nilai belum ditampilkan oleh pengaturan kuis.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92)),
                ),
            ],
          ),
        ),
        const SizedBox(height: EmiSpacing.md),
        StudentCard(
          child: Row(
            children: [
              if (attempt.correctCount != null)
                Expanded(
                  child: StudentStatChip(
                    label: 'Benar',
                    value: '${attempt.correctCount}',
                  ),
                ),
              if (attempt.incorrectCount != null) ...[
                const SizedBox(width: EmiSpacing.sm),
                Expanded(
                  child: StudentStatChip(
                    label: 'Salah',
                    value: '${attempt.incorrectCount}',
                  ),
                ),
              ],
              if (attempt.unansweredCount != null) ...[
                const SizedBox(width: EmiSpacing.sm),
                Expanded(
                  child: StudentStatChip(
                    label: 'Kosong',
                    value: '${attempt.unansweredCount}',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: EmiSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onDone,
            child: const Text('Kembali ke detail kuis'),
          ),
        ),
      ],
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final urgent = remaining.inMinutes < 1;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFFFFE1E3) : StudentStyle.tint,
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: urgent ? const Color(0xFFA62932) : EmiColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$minutes:$seconds',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: urgent ? const Color(0xFFA62932) : StudentStyle.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        StudentPlaceholder(
          icon: Icons.cloud_off_outlined,
          title: 'Kuis Belum Bisa Dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}

String _idempotencyKey(String attemptId) {
  return 'emi-mobile-${DateTime.now().microsecondsSinceEpoch}-$attemptId';
}

extension on num {
  String get g => this % 1 == 0 ? round().toString() : toStringAsFixed(2);
}
