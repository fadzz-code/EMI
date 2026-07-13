import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/student_quiz.dart';
import '../data/student_quiz_providers.dart';

class StudentQuizAttemptScreen extends ConsumerStatefulWidget {
  const StudentQuizAttemptScreen({super.key, required this.quizId});

  final String quizId;

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
  String? _submitKey;
  Object? _error;
  final _selectedOptions = <String, String>{};
  final _textAnswers = <String, TextEditingController>{};
  Timer? _timer;
  Duration? _remaining;

  List<QuizQuestion> get _questions => _attempt?.quiz?.questions ?? const [];
  QuizQuestion? get _question => _questions.isEmpty
      ? null
      : _questions[_index.clamp(0, _questions.length - 1)];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _textAnswers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _attempt == null || _attempt!.isFinished,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _attempt == null || _attempt!.isFinished) return;
        final leave = await _confirmLeave();
        if (leave && context.mounted) context.pop();
      },
      child: Scaffold(
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
      final attempt = await ref
          .read(studentQuizRepositoryProvider)
          .startAttempt(widget.quizId);
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
    if (confirmed != true || _submitting) return;
    setState(() => _submitting = true);
    final saved = await _saveCurrent();
    if (!saved || _attempt == null) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    final attemptId = _attempt!.id;
    _submitKey ??= _idempotencyKey(attemptId);
    try {
      final result = await ref
          .read(studentQuizRepositoryProvider)
          .submitAttempt(attemptId: attemptId, idempotencyKey: _submitKey!);
      _timer?.cancel();
      setState(() {
        _attempt = result;
        _submitting = false;
      });
      ref.invalidate(studentQuizDetailProvider(widget.quizId));
      ref.invalidate(studentQuizListProvider);
    } catch (error) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  void _startTimer(QuizAttempt attempt) {
    _timer?.cancel();
    if (attempt.expiresAt == null || !attempt.isInProgress) return;
    void tick() {
      final remaining = attempt.expiresAt!.difference(DateTime.now());
      setState(
        () => _remaining = remaining.isNegative ? Duration.zero : remaining,
      );
    }

    tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<bool> _confirmLeave() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar dari kuis?'),
            content: const Text(
              'Jawaban tersimpan saat pindah soal. Jawaban di soal ini yang belum disimpan bisa hilang.',
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
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: EmiSpacing.md),
          decoration: const BoxDecoration(
            color: EmiColors.background,
            border: Border(
              bottom: BorderSide(color: EmiColors.border, width: 2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Soal ${index + 1}/$total',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (remaining != null) _TimerPill(remaining: remaining!),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              LinearProgressIndicator(
                value: total == 0 ? 0 : (index + 1) / total,
              ),
              const SizedBox(height: EmiSpacing.lg),
              EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question!.questionText,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: EmiSpacing.sm),
                    Text('${question!.points.g} poin'),
                  ],
                ),
              ),
              const SizedBox(height: EmiSpacing.lg),
              if (question!.isMultipleChoice)
                ...question!.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
                    child: ChoiceChip(
                      selected: selectedOptionId == option.id,
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(option.optionText),
                      ),
                      onSelected: (_) => onSelect(option.id),
                      selectedColor: EmiColors.primary,
                      backgroundColor: EmiColors.surface,
                      side: const BorderSide(color: EmiColors.border, width: 2),
                    ),
                  ),
                )
              else
                TextField(
                  controller: textController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Tulis jawaban...',
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(EmiSpacing.md),
          decoration: const BoxDecoration(
            color: EmiColors.surface,
            border: Border(top: BorderSide(color: EmiColors.border, width: 2)),
          ),
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
                  child: ElevatedButton(
                    onPressed: saving || submitting ? null : onNext,
                    child: Text(saving ? 'Menyimpan...' : 'Berikutnya'),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving || submitting ? null : onSubmit,
                    child: Text(submitting ? 'Mengirim...' : 'Submit'),
                  ),
                ),
            ],
          ),
        ),
      ],
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
        Text('Hasil Kuis', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: EmiSpacing.lg),
        EmiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: ${attempt.status}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (attempt.scorePercent != null) ...[
                const SizedBox(height: EmiSpacing.md),
                Text(
                  '${attempt.scorePercent!.round()}%',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
              if (attempt.scorePoints != null && attempt.maxPoints != null)
                Text('${attempt.scorePoints!.g}/${attempt.maxPoints!.g} poin'),
              if (attempt.correctCount != null)
                Text('Benar: ${attempt.correctCount}'),
              if (attempt.incorrectCount != null)
                Text('Salah: ${attempt.incorrectCount}'),
              if (attempt.unansweredCount != null)
                Text('Kosong: ${attempt.unansweredCount}'),
              if (attempt.scorePercent == null)
                const Text('Nilai belum ditampilkan oleh pengaturan kuis.'),
            ],
          ),
        ),
        const SizedBox(height: EmiSpacing.lg),
        ...attempt.answers.map(
          (answer) => Padding(
            padding: const EdgeInsets.only(bottom: EmiSpacing.md),
            child: EmiCard(
              child: Text(
                answer.isCorrect == null
                    ? 'Jawaban tersimpan'
                    : (answer.isCorrect! ? 'Benar' : 'Salah'),
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onDone,
          child: const Text('Kembali ke detail kuis'),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: remaining.inMinutes < 1 ? EmiColors.error : EmiColors.secondary,
        border: Border.all(color: EmiColors.border, width: 2),
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: Text('$minutes:$seconds'),
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
        EmiCard(
          child: Column(
            children: [
              Text(error.toString()),
              const SizedBox(height: EmiSpacing.md),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
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
